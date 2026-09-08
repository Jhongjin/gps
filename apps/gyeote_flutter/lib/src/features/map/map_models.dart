import 'package:latlong2/latlong.dart';

import '../../core/backend/backend_contract.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/i18n/region_settings.dart';
import '../../core/location/location_models.dart';
import '../../theme/gyeote_theme.dart';
import '../../core/i18n/sharing_mode_label.dart';
import 'movement.dart';

// 공유 정확도 라벨은 코어 enum 의 로케일 표현이라 코어에 산다. 지도 밖에서도
// 쓰이므로 여기서 다시 내보내 기존 호출부를 그대로 둔다.
export '../../core/i18n/sharing_mode_label.dart' show sharingModeLabel;

/// 경로 꼬리의 표본 하나.
///
/// 좌표만 담던 것을 시각과 함께 담는다. 서버는 처음부터 [MemberRoutePoint] 로
/// 시각을 함께 주고 있었는데 화면으로 오는 길에 버려지고 있었다. 시각이 없으면
/// 선을 그릴 수는 있어도 **속도와 방향을 알 수 없어** 도착 예상이 불가능하다.
class MapRoutePoint {
  const MapRoutePoint({required this.point, required this.recordedAt});

  final LatLng point;
  final DateTime recordedAt;

  MovementSample toSample() =>
      MovementSample(point: point, recordedAt: recordedAt);

  @override
  bool operator ==(Object other) =>
      other is MapRoutePoint &&
      other.point == point &&
      other.recordedAt == recordedAt;

  @override
  int get hashCode => Object.hash(point, recordedAt);
}

class MapMemberTrack {
  const MapMemberTrack({
    required this.id,
    required this.name,
    this.statusOverride,
    this.metaOverride,
    required this.point,
    required this.tone,
    required this.recordedAt,
    required this.sharingMode,
    this.routeTail = const [],
    this.isCurrentUser = false,
    this.isStale = false,
    this.hasLowBattery = false,
    this.batteryPercent,
    this.accuracyM,
  });

  final String id;
  final String name;
  /// 데모 픽스처만 쓴다. 실제 데이터는 null 이고 [status]/[meta] 가 계산한다.
  final String? statusOverride;
  final String? metaOverride;
  final LatLng point;
  final GyeoteTone tone;
  final DateTime recordedAt;
  final SharingMode sharingMode;
  final List<MapRoutePoint> routeTail;
  final bool isCurrentUser;
  final bool isStale;
  final bool hasLowBattery;

  /// 마커 링의 채워진 정도로 그린다. 없으면 링을 꽉 채운다.
  final int? batteryPercent;
  final double? accuracyM;

  /// 폴리라인에 넘길 좌표만.
  List<LatLng> get routeLine =>
      routeTail.map((sample) => sample.point).toList(growable: false);

  /// 최근 표본에서 뽑은 이동 상태. 표본이 모자라면 [MovementState.unknown].
  MovementEstimate get movement => estimateMovement(
        routeTail.map((sample) => sample.toSample()).toList(growable: false),
      );

  /// 30분 넘게 갱신이 없으면 "마지막 위치"로만 다룬다.
  bool get isVeryStale =>
      DateTime.now().difference(recordedAt) >= const Duration(minutes: 30);

  /// 한 줄 상태. 모델은 렌더된 문자열을 담지 않는다 — 담으면 그 화면이
  /// 한 언어에 묶인다. [GyeoteTone] 을 쓰는 이유와 같다.
  String status(AppL10n l10n) {
    final override = statusOverride;
    if (override != null) return override;
    if (isVeryStale) return l10n.statusLastKnownOnly;
    if (isStale) return l10n.statusWaitingUpdate;
    if (hasLowBattery) return l10n.statusLowBattery;
    return l10n.statusSharing(sharingModeLabel(l10n, sharingMode));
  }

  /// 배터리·정확도·갱신 시각을 잇는 보조 줄.
  String meta(AppL10n l10n, DistanceUnit unit) {
    final override = metaOverride;
    if (override != null) return override;

    final parts = <String>[
      if (isVeryStale)
        l10n.metaOldLocation(relativeTimeLabel(l10n, recordedAt))
      else if (isStale)
        l10n.metaLastLocation(relativeTimeLabel(l10n, recordedAt)),
      if (batteryPercent != null) l10n.metaBattery(batteryPercent!),
      if (accuracyM != null) l10n.metaAccuracy(unit.formatDistance(accuracyM!)),
      if (!isStale) relativeTimeLabel(l10n, recordedAt),
    ];
    return parts.isEmpty ? l10n.metaJustUpdated : parts.join(' · ');
  }

  /// 스크린리더가 읽을 한 줄.
  ///
  /// 마커 링은 배터리를 채움 정도로, 오래됨을 색으로 **그린다**. 눈으로는
  /// 읽히지만 읽어 주는 것은 없었다 — 라벨은 이름과 상태만 담고 있었고, 그
  /// 자리를 위해 만든 `a11yBatteryLevel`·`a11yStaleLocation` 은 ARB 에만 있고
  /// 어디서도 쓰이지 않았다. 링이 아는 것을 라벨도 알아야 한다.
  String semanticsLabel(AppL10n l10n) => '$name, ${semanticsDetail(l10n)}';

  /// [semanticsLabel] 에서 이름을 뺀 부분. 이름을 따로 붙이는 문구
  /// (`a11yMemberRow`) 가 쓴다.
  String semanticsDetail(AppL10n l10n) {
    final parts = <String>[
      status(l10n),
      if (isStale || isVeryStale) l10n.a11yStaleLocation,
      if (batteryPercent case final percent?) l10n.a11yBatteryLevel(percent),
    ];
    return parts.join(', ');
  }

  /// 왜 늦는지 설명하는 안내. 사용자를 탓하지 않는 톤을 유지한다.
  String? safetyNote(AppL10n l10n) {
    if (isVeryStale) return l10n.noteVeryStale;
    if (isStale) return l10n.noteStale;
    if (hasLowBattery) return l10n.noteLowBattery;
    return null;
  }

  MapMemberTrack copyWith({
    String? id,
    String? name,
    String? statusOverride,
    String? metaOverride,
    LatLng? point,
    GyeoteTone? tone,
    DateTime? recordedAt,
    SharingMode? sharingMode,
    List<MapRoutePoint>? routeTail,
    bool? isCurrentUser,
    bool? isStale,
    bool? hasLowBattery,
    int? batteryPercent,
    double? accuracyM,
  }) {
    return MapMemberTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      statusOverride: statusOverride ?? this.statusOverride,
      metaOverride: metaOverride ?? this.metaOverride,
      point: point ?? this.point,
      tone: tone ?? this.tone,
      recordedAt: recordedAt ?? this.recordedAt,
      sharingMode: sharingMode ?? this.sharingMode,
      routeTail: routeTail ?? this.routeTail,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      isStale: isStale ?? this.isStale,
      hasLowBattery: hasLowBattery ?? this.hasLowBattery,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      accuracyM: accuracyM ?? this.accuracyM,
    );
  }
}

List<MapMemberTrack> mapTracksFromSnapshots(
  AppL10n l10n,
  List<MemberLocationSnapshot> snapshots,
) {
  return snapshots.indexed
      .where((entry) => entry.$2.sharedCoordinate != null)
      .map((entry) => _trackFromSnapshot(l10n, entry.$2, entry.$1))
      .toList(growable: false);
}

List<MapMemberTrack> demoMapTracks(AppL10n l10n) {
  final now = DateTime.now();
  // 데모 경로에도 시각을 준다. 시각이 없으면 데모에서 이동 상태와 도착 예상이
  // 통째로 비어 보이고, 실제로는 되는 기능을 안 되는 것처럼 보여 준다.
  const routeToHome = [
    LatLng(37.50325, 127.04888),
    LatLng(37.50418, 127.04756),
    LatLng(37.50535, 127.04642),
    LatLng(37.50654, 127.04503),
    LatLng(37.50768, 127.04382),
  ];
  final walkingHome = [
    for (final (index, point) in routeToHome.indexed)
      MapRoutePoint(
        point: point,
        recordedAt: now.subtract(Duration(minutes: 9 - index * 2)),
      ),
  ];

  return [
    MapMemberTrack(
      id: 'demo-jun',
      name: l10n.demoNameChild,
      point: walkingHome.last.point,
      tone: GyeoteTone.move,
      recordedAt: now.subtract(const Duration(minutes: 1)),
      sharingMode: SharingMode.balanced,
      batteryPercent: 46,
      accuracyM: 85,
      routeTail: walkingHome,
    ),
    MapMemberTrack(
      id: 'demo-hana',
      name: l10n.demoNameFriend,
      point: const LatLng(37.49809, 127.02761),
      tone: GyeoteTone.warm,
      recordedAt: now.subtract(const Duration(minutes: 5)),
      sharingMode: SharingMode.balanced,
      batteryPercent: 67,
      accuracyM: 110,
    ),
    MapMemberTrack(
      id: 'demo-grandfather',
      name: l10n.demoNameElder,
      point: const LatLng(37.51119, 127.04374),
      tone: GyeoteTone.warm,
      recordedAt: now.subtract(const Duration(minutes: 22)),
      sharingMode: SharingMode.area,
      batteryPercent: 12,
      accuracyM: 500,
      isStale: true,
      hasLowBattery: true,
    ),
    MapMemberTrack(
      id: 'demo-me',
      name: l10n.mapMeShort,
      // 준의 경로 끝점과 겹치지 않게 둔다. 두 마커가 같은 자리에 있으면
      // 마중 나가는 그림이 아니라 렌더링 버그로 읽힌다.
      point: const LatLng(37.51023, 127.04101),
      tone: GyeoteTone.brand,
      recordedAt: now,
      sharingMode: SharingMode.precise,
      batteryPercent: 88,
      accuracyM: 35,
      isCurrentUser: true,
    ),
  ];
}

MapMemberTrack _trackFromSnapshot(
  AppL10n l10n,
  MemberLocationSnapshot snapshot,
  int index,
) {
  final coordinate = snapshot.sharedCoordinate!;
  final age = DateTime.now().difference(snapshot.recordedAt);
  final hasLowBattery =
      snapshot.batteryPercent != null && snapshot.batteryPercent! <= 15;

  // 표시 문자열은 만들지 않는다. 사실만 담고, 문구는 그릴 때 로케일에 맞춰 만든다.
  return MapMemberTrack(
    id: snapshot.profileId,
    name: snapshot.displayName.isEmpty
        ? l10n.memberFallbackName
        : snapshot.displayName,
    point: LatLng(coordinate.latitude, coordinate.longitude),
    tone: _toneForIndex(index),
    recordedAt: snapshot.recordedAt,
    sharingMode: snapshot.sharingMode,
    isStale: age > const Duration(minutes: 5),
    hasLowBattery: hasLowBattery,
    batteryPercent: snapshot.batteryPercent,
    accuracyM: snapshot.accuracyM,
  );
}

/// "3분 전" 형태의 상대 시각.
String relativeTimeLabel(AppL10n l10n, DateTime recordedAt) {
  final diff = DateTime.now().difference(recordedAt);
  if (diff.inSeconds < 60) return l10n.agoJustNow;
  if (diff.inMinutes < 60) return l10n.agoMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.agoHours(diff.inHours);
  return l10n.agoDays(diff.inDays);
}

GyeoteTone _toneForIndex(int index) {
  const tones = [
    GyeoteTone.brand,
    GyeoteTone.move,
    GyeoteTone.warm,
    GyeoteTone.alert,
  ];
  return tones[index % tones.length];
}
