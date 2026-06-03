import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/backend/backend_contract.dart';
import '../../core/location/location_models.dart';
import '../../theme/gyeote_theme.dart';

class MapMemberTrack {
  const MapMemberTrack({
    required this.id,
    required this.name,
    required this.status,
    required this.meta,
    required this.point,
    required this.tone,
    required this.recordedAt,
    required this.sharingMode,
    this.routeTail = const [],
    this.isCurrentUser = false,
    this.isStale = false,
    this.hasLowBattery = false,
    this.accuracyM,
    this.safetyNote,
  });

  final String id;
  final String name;
  final String status;
  final String meta;
  final LatLng point;
  final Color tone;
  final DateTime recordedAt;
  final SharingMode sharingMode;
  final List<LatLng> routeTail;
  final bool isCurrentUser;
  final bool isStale;
  final bool hasLowBattery;
  final double? accuracyM;
  final String? safetyNote;

  MapMemberTrack copyWith({
    String? id,
    String? name,
    String? status,
    String? meta,
    LatLng? point,
    Color? tone,
    DateTime? recordedAt,
    SharingMode? sharingMode,
    List<LatLng>? routeTail,
    bool? isCurrentUser,
    bool? isStale,
    bool? hasLowBattery,
    double? accuracyM,
    String? safetyNote,
    bool clearSafetyNote = false,
  }) {
    return MapMemberTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      meta: meta ?? this.meta,
      point: point ?? this.point,
      tone: tone ?? this.tone,
      recordedAt: recordedAt ?? this.recordedAt,
      sharingMode: sharingMode ?? this.sharingMode,
      routeTail: routeTail ?? this.routeTail,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      isStale: isStale ?? this.isStale,
      hasLowBattery: hasLowBattery ?? this.hasLowBattery,
      accuracyM: accuracyM ?? this.accuracyM,
      safetyNote: clearSafetyNote ? null : safetyNote ?? this.safetyNote,
    );
  }
}

List<MapMemberTrack> mapTracksFromSnapshots(
    List<MemberLocationSnapshot> snapshots) {
  return snapshots.indexed
      .where((entry) => entry.$2.sharedCoordinate != null)
      .map((entry) => _trackFromSnapshot(entry.$2, entry.$1))
      .toList(growable: false);
}

List<MapMemberTrack> demoMapTracks() {
  final now = DateTime.now();
  const routeToHome = [
    LatLng(37.50325, 127.04888),
    LatLng(37.50418, 127.04756),
    LatLng(37.50535, 127.04642),
    LatLng(37.50654, 127.04503),
    LatLng(37.50768, 127.04382),
  ];

  return [
    MapMemberTrack(
      id: 'demo-jun',
      name: '준',
      status: '학교 근처 · 예상 8분',
      meta: '배터리 46% · 균형 공유 · 경로 4개 샘플',
      point: routeToHome.first,
      tone: GyeoteColors.info,
      recordedAt: now.subtract(const Duration(minutes: 1)),
      sharingMode: SharingMode.balanced,
      accuracyM: 85,
      routeTail: routeToHome,
    ),
    MapMemberTrack(
      id: 'demo-hana',
      name: '하나',
      status: '강남역 · 5분 전',
      meta: '배터리 67% · 균형 공유',
      point: const LatLng(37.49809, 127.02761),
      tone: GyeoteColors.amber,
      recordedAt: now.subtract(const Duration(minutes: 5)),
      sharingMode: SharingMode.balanced,
      accuracyM: 110,
    ),
    MapMemberTrack(
      id: 'demo-grandfather',
      name: '할아버지',
      status: '위치 업데이트 대기 중',
      meta: '마지막 위치 · 22분 전 · 배터리 12% · 동네만 공유',
      point: const LatLng(37.51119, 127.04374),
      tone: GyeoteColors.amber,
      recordedAt: now.subtract(const Duration(minutes: 22)),
      sharingMode: SharingMode.area,
      accuracyM: 500,
      isStale: true,
      hasLowBattery: true,
      safetyNote: '배터리, 신호, 권한 상태 때문에 늦을 수 있어요.',
    ),
    MapMemberTrack(
      id: 'demo-me',
      name: '나',
      status: '집 근처',
      meta: '내 기기 · 정확 공유',
      point: routeToHome.last,
      tone: GyeoteColors.primary,
      recordedAt: now,
      sharingMode: SharingMode.precise,
      accuracyM: 35,
      isCurrentUser: true,
    ),
  ];
}

MapMemberTrack _trackFromSnapshot(MemberLocationSnapshot snapshot, int index) {
  final coordinate = snapshot.sharedCoordinate!;
  final sharingLabel = _sharingModeLabel(snapshot.sharingMode);
  final age = DateTime.now().difference(snapshot.recordedAt);
  final isStale = age > const Duration(minutes: 5);
  final isVeryStale = age >= const Duration(minutes: 30);
  final hasLowBattery =
      snapshot.batteryPercent != null && snapshot.batteryPercent! <= 15;
  final status = _statusForSnapshot(
    sharingLabel: sharingLabel,
    isStale: isStale,
    isVeryStale: isVeryStale,
    hasLowBattery: hasLowBattery,
  );
  final meta = [
    if (isVeryStale)
      '오래된 위치 · ${_relativeTime(snapshot.recordedAt)}'
    else if (isStale)
      '마지막 위치 · ${_relativeTime(snapshot.recordedAt)}',
    if (snapshot.batteryPercent != null) '배터리 ${snapshot.batteryPercent}%',
    if (snapshot.accuracyM != null) '정확도 ${snapshot.accuracyM!.round()}m',
    if (!isStale) _relativeTime(snapshot.recordedAt),
  ].join(' · ');

  return MapMemberTrack(
    id: snapshot.profileId,
    name: snapshot.displayName.isEmpty ? '멤버' : snapshot.displayName,
    status: status,
    meta: meta.isEmpty ? '방금 업데이트' : meta,
    point: LatLng(coordinate.latitude, coordinate.longitude),
    tone: isStale
        ? GyeoteColors.amber
        : hasLowBattery
            ? GyeoteColors.danger
            : _toneForIndex(index),
    recordedAt: snapshot.recordedAt,
    sharingMode: snapshot.sharingMode,
    isStale: isStale,
    hasLowBattery: hasLowBattery,
    accuracyM: snapshot.accuracyM,
    safetyNote: isVeryStale
        ? '현재 위치가 아닐 수 있어요. 연결이 돌아오면 다시 업데이트돼요.'
        : isStale
            ? '배터리, 신호, 권한 상태 때문에 늦을 수 있어요.'
            : hasLowBattery
                ? '배터리가 낮아 업데이트가 느릴 수 있어요.'
                : null,
  );
}

String _statusForSnapshot({
  required String sharingLabel,
  required bool isStale,
  required bool isVeryStale,
  required bool hasLowBattery,
}) {
  if (isVeryStale) {
    return '마지막 위치만 표시 중';
  }
  if (isStale) {
    return '위치 업데이트 대기 중';
  }
  if (hasLowBattery) {
    return '배터리가 낮아 업데이트가 느릴 수 있어요';
  }
  return '$sharingLabel 공유 중';
}

String _sharingModeLabel(SharingMode mode) {
  switch (mode) {
    case SharingMode.precise:
      return '정확';
    case SharingMode.balanced:
      return '균형';
    case SharingMode.area:
      return '동네 범위';
    case SharingMode.hidden:
      return '숨김';
    case SharingMode.sosOnly:
      return '긴급 전용';
  }
}

String _relativeTime(DateTime recordedAt) {
  final diff = DateTime.now().difference(recordedAt);
  if (diff.inSeconds < 60) {
    return '방금';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}분 전';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}시간 전';
  }
  return '${diff.inDays}일 전';
}

Color _toneForIndex(int index) {
  const tones = [
    GyeoteColors.primary,
    GyeoteColors.info,
    GyeoteColors.amber,
    GyeoteColors.danger,
  ];
  return tones[index % tones.length];
}
