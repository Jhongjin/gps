import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// 표본 좌표에서 **이동 상태와 도착 예상**을 뽑는다.
///
/// 이 파일에 문자열이 없는 것은 의도다. 여기서 나오는 것은 사실(속도·방위·
/// 남은 시간)이고, 문구는 화면이 로케일에 맞춰 만든다. 모델이 렌더된 문자열을
/// 들고 있으면 그 화면이 한 언어에 묶인다 — 이 저장소에서 네 번 나온 버그다.
///
/// 라우팅 서비스를 부르지 않는다. 경로 API 는 멤버의 좌표를 외부로 내보내는
/// 일이고, 이 앱에서 그건 기능 하나와 바꿀 만한 것이 아니다. 대신 직선거리에
/// 우회 계수를 곱한다. 그래서 결과는 "정확한 도착 시각"이 아니라 "대략 몇 분"
/// 이고, 화면도 그렇게만 말해야 한다.

/// 지구 반지름(m). 도시 규모 거리에서 구면 근사로 충분하다.
const double _earthRadiusM = 6371008.8;

/// 직선거리를 실제 이동 거리로 바꾸는 계수.
///
/// 도시 도로망에서 직선거리 대비 실제 경로는 대체로 1.2~1.5배다. 낮게 잡으면
/// 도착을 실제보다 이르게 약속하게 되고, 기다리는 사람에게 그건 나쁜 방향의
/// 오차다. 그래서 중간값보다 살짝 보수적으로 둔다.
const double detourFactor = 1.35;

/// 이 아래 속도는 멈춘 것으로 본다(약 2.2km/h). GPS 지터가 만드는 가짜 이동을
/// 걷는 중으로 읽지 않기 위한 바닥값이다.
const double _stoppedBelowMps = 0.6;

/// 걷기와 탈것을 가르는 속도(약 8km/h).
const double _walkingBelowMps = 2.2;

/// 탈것 안에서 자전거·버스와 자동차를 가르는 속도(약 25km/h).
const double _ridingBelowMps = 7.0;

/// 표본이 이보다 적게 흩어져 있으면 방위를 믿지 않는다.
const double _minNetDisplacementM = 30;

/// 이보다 오래된 표본은 현재 이동으로 치지 않는다.
const Duration movementWindow = Duration(minutes: 10);

/// 이보다 긴 도착 예상은 내놓지 않는다. 세 시간짜리 추정은 정보가 아니다.
const Duration _maxEta = Duration(hours: 3);

enum MovementState {
  /// 판단할 표본이 없다. "멈춰 있다"와 다르다 — 모르는 것을 아는 것처럼
  /// 말하지 않기 위해 별도 값으로 둔다.
  unknown,
  stopped,
  walking,
  riding,
  driving,
}

/// 목적지를 기준으로 한 이동 방향.
enum ApproachDirection { approaching, leaving, sideways }

class MovementEstimate {
  const MovementEstimate({
    required this.speedMps,
    required this.state,
    required this.bearingDeg,
    required this.span,
    required this.sampleCount,
  });

  /// 표본 구간의 평균 속도.
  final double speedMps;
  final MovementState state;

  /// 진북 기준 0~360. 멈춰 있거나 표본이 흩어지지 않았으면 null.
  final double? bearingDeg;

  /// 이 추정이 실제로 덮는 시간.
  final Duration span;
  final int sampleCount;

  bool get isMoving =>
      state != MovementState.unknown && state != MovementState.stopped;
}

class EtaEstimate {
  const EtaEstimate({
    required this.eta,
    required this.travelDistanceM,
    required this.direction,
  });

  final Duration eta;

  /// 우회 계수를 반영한 예상 이동 거리.
  final double travelDistanceM;
  final ApproachDirection direction;

  /// 화면에 쓸 분 단위. 10분 미만은 1분, 그 이상은 5분 단위로 끊는다.
  ///
  /// 초 단위까지 보여 주면 없는 정밀도를 주장하게 된다.
  int get roundedMinutes {
    final minutes = (eta.inSeconds / 60).ceil();
    if (minutes <= 1) return 1;
    if (minutes < 10) return minutes;
    return ((minutes + 2) ~/ 5) * 5;
  }
}

/// 두 지점 사이 대권 거리(m).
double distanceMeters(LatLng a, LatLng b) {
  final lat1 = _toRadians(a.latitude);
  final lat2 = _toRadians(b.latitude);
  final dLat = lat2 - lat1;
  final dLng = _toRadians(b.longitude - a.longitude);

  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
}

/// [from] 에서 [to] 를 향하는 방위각. 진북 0, 시계방향 0~360.
double bearingDegrees(LatLng from, LatLng to) {
  final lat1 = _toRadians(from.latitude);
  final lat2 = _toRadians(to.latitude);
  final dLng = _toRadians(to.longitude - from.longitude);

  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (_toDegrees(math.atan2(y, x)) + 360) % 360;
}

/// 두 방위각 사이의 최소 각도차(0~180).
double bearingDeltaDegrees(double a, double b) {
  final diff = (a - b).abs() % 360;
  return diff > 180 ? 360 - diff : diff;
}

/// 시간이 찍힌 표본 하나. [MapRoutePoint] 를 그대로 받지 않는 이유는 이 파일이
/// 지도 모델에 의존하지 않게 두기 위해서다.
class MovementSample {
  const MovementSample({required this.point, required this.recordedAt});

  final LatLng point;
  final DateTime recordedAt;
}

/// 표본에서 이동 상태를 추정한다.
///
/// [samples] 는 시간 오름차순이라고 가정하지 않는다 — 여기서 정렬한다.
/// [window] 안에 든 표본만 쓴다. 30분 전에 걷던 사실은 지금 걷는다는 뜻이
/// 아니다.
MovementEstimate estimateMovement(
  List<MovementSample> samples, {
  DateTime? now,
  Duration window = movementWindow,
}) {
  const unknown = MovementEstimate(
    speedMps: 0,
    state: MovementState.unknown,
    bearingDeg: null,
    span: Duration.zero,
    sampleCount: 0,
  );

  if (samples.length < 2) return unknown;

  final at = now ?? DateTime.now();
  final recent = samples
      .where((sample) => at.difference(sample.recordedAt) <= window)
      .toList()
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  if (recent.length < 2) return unknown;

  final span = recent.last.recordedAt.difference(recent.first.recordedAt);
  if (span <= Duration.zero) return unknown;

  var pathM = 0.0;
  for (var i = 1; i < recent.length; i++) {
    pathM += distanceMeters(recent[i - 1].point, recent[i].point);
  }

  final netM = distanceMeters(recent.first.point, recent.last.point);
  final seconds = span.inMilliseconds / 1000;

  // 제자리에서 흔들리는 GPS 는 경로 길이만 늘리고 실제 변위는 남기지 않는다.
  // 변위가 없으면 속도가 얼마로 나오든 멈춘 것으로 읽는다.
  if (netM < _minNetDisplacementM) {
    return MovementEstimate(
      speedMps: 0,
      state: MovementState.stopped,
      bearingDeg: null,
      span: span,
      sampleCount: recent.length,
    );
  }

  final speed = pathM / seconds;
  return MovementEstimate(
    speedMps: speed,
    state: _stateFor(speed),
    bearingDeg: bearingDegrees(recent.first.point, recent.last.point),
    span: span,
    sampleCount: recent.length,
  );
}

/// 목적지까지 남은 시간을 추정한다. 믿을 수 없으면 null 을 낸다.
///
/// null 을 내는 쪽이 틀린 숫자를 내는 쪽보다 낫다. 마중 나가는 사람은 이 숫자를
/// 보고 문을 나선다.
EtaEstimate? estimateEta({
  required LatLng from,
  required LatLng to,
  required MovementEstimate movement,
}) {
  final straightM = distanceMeters(from, to);
  final direction = _directionFor(from: from, to: to, movement: movement);

  if (!movement.isMoving) return null;

  // 이미 도착 반경 안이면 남은 시간이 아니라 도착으로 다뤄야 한다. 그 판단은
  // 장소 알림이 하므로 여기서는 추정을 내지 않는다.
  if (straightM < 60) return null;

  final travelM = straightM * detourFactor;
  final seconds = travelM / movement.speedMps;
  final eta = Duration(seconds: seconds.round());

  if (eta > _maxEta) return null;

  return EtaEstimate(
    eta: eta,
    travelDistanceM: travelM,
    direction: direction,
  );
}

/// 도착 예상 없이 방향만 알고 싶을 때 쓴다. 멈춰 있어도 답이 나온다.
ApproachDirection approachDirection({
  required LatLng from,
  required LatLng to,
  required MovementEstimate movement,
}) =>
    _directionFor(from: from, to: to, movement: movement);

ApproachDirection _directionFor({
  required LatLng from,
  required LatLng to,
  required MovementEstimate movement,
}) {
  final heading = movement.bearingDeg;
  if (heading == null || !movement.isMoving) {
    return ApproachDirection.sideways;
  }

  final delta = bearingDeltaDegrees(heading, bearingDegrees(from, to));
  if (delta <= 60) return ApproachDirection.approaching;
  if (delta >= 120) return ApproachDirection.leaving;
  return ApproachDirection.sideways;
}

MovementState _stateFor(double speedMps) {
  if (speedMps < _stoppedBelowMps) return MovementState.stopped;
  if (speedMps < _walkingBelowMps) return MovementState.walking;
  if (speedMps < _ridingBelowMps) return MovementState.riding;
  return MovementState.driving;
}

double _toRadians(double degrees) => degrees * math.pi / 180;

double _toDegrees(double radians) => radians * 180 / math.pi;
