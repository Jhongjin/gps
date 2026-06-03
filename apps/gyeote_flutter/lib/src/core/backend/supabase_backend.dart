import 'package:supabase_flutter/supabase_flutter.dart';

import '../location/location_models.dart';
import 'backend_config.dart';
import 'backend_contract.dart';

class SupabaseBackend {
  const SupabaseBackend({
    required this.client,
    required this.config,
  });

  final SupabaseClient client;
  final BackendConfig config;

  CircleRepository get circles => SupabaseCircleRepository(client);

  InvitationRepository get invitations =>
      SupabaseInvitationRepository(client, config);

  PlaceAlertRepository get placeAlerts => SupabasePlaceAlertRepository(client);

  CheckInRepository get checkIns => SupabaseCheckInRepository(client);

  DeviceRepository get devices => SupabaseDeviceRepository(client);

  LocationIngestRepository get locations =>
      SupabaseLocationIngestRepository(client);

  PrivacyRepository get privacy => SupabasePrivacyRepository(client);

  CompanionRepository get companions => SupabaseCompanionRepository(client);
}

class SupabaseCircleRepository implements CircleRepository {
  const SupabaseCircleRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CircleSummary>> listCircles() async {
    final rows = await _client
        .from('circles')
        .select('id, name, circle_members(profile_id)');
    return rows.map((row) {
      final map = Map<String, Object?>.from(row);
      final members = map['circle_members'];
      return CircleSummary(
        id: '${map['id']}',
        name: '${map['name']}',
        memberCount: members is List ? members.length : 0,
      );
    }).toList(growable: false);
  }

  @override
  Future<CircleSummary> createCircle({
    required String name,
    String circleType = 'family',
  }) async {
    final normalizedName = name.trim().isEmpty ? '가족 서클' : name.trim();
    final circleId = await _client.rpc(
      'create_circle_with_owner',
      params: {
        'circle_name': normalizedName,
        'circle_kind': circleType,
      },
    );

    return CircleSummary(
      id: '$circleId',
      name: normalizedName,
      memberCount: 1,
    );
  }

  @override
  Future<List<MemberLocationSnapshot>> listLatestLocations(
      String circleId) async {
    final rows = await _client.rpc(
      'get_circle_latest_locations',
      params: {'target_circle_id': circleId},
    );

    return (rows as List).map((row) {
      final map = Map<String, Object?>.from(row);
      return _memberLocationFromRow(map);
    }).toList(growable: false);
  }

  @override
  Future<List<MemberRoutePoint>> getMemberRouteTail({
    required String circleId,
    required String profileId,
    int limit = 30,
    Duration since = const Duration(hours: 2),
  }) async {
    final rows = await _client.rpc(
      'get_circle_member_route_tail',
      params: {
        'target_circle_id': circleId,
        'subject_profile_id': profileId,
        'route_limit': limit,
        'since_at': DateTime.now().subtract(since).toUtc().toIso8601String(),
      },
    );

    return (rows as List).map((row) {
      final map = Map<String, Object?>.from(row);
      return _memberRoutePointFromRow(map);
    }).toList(growable: false);
  }

  @override
  Future<List<MemberRoutePoint>> getActiveCompanionRouteTail({
    required String companionSessionId,
    required String profileId,
    int limit = 60,
    Duration since = const Duration(minutes: 45),
  }) async {
    final rows = await _client.rpc(
      'get_active_companion_route_tail',
      params: {
        'target_session_id': companionSessionId,
        'subject_profile_id': profileId,
        'route_limit': limit,
        'since_at': DateTime.now().subtract(since).toUtc().toIso8601String(),
      },
    );

    return (rows as List).map((row) {
      final map = Map<String, Object?>.from(row);
      return _memberRoutePointFromRow(map);
    }).toList(growable: false);
  }

  @override
  Stream<List<MemberLocationSnapshot>> watchLatestLocations(
      String circleId) async* {
    yield await listLatestLocations(circleId);
    yield* Stream<void>.periodic(const Duration(seconds: 5))
        .asyncMap((_) => listLatestLocations(circleId));
  }
}

class SupabaseInvitationRepository implements InvitationRepository {
  const SupabaseInvitationRepository(this._client, this._config);

  final SupabaseClient _client;
  final BackendConfig _config;

  @override
  Future<InviteCreationResult> createInvite({
    required String circleId,
    required DateTime expiresAt,
    int maxUses = 1,
  }) async {
    final ttlSeconds =
        expiresAt.difference(DateTime.now()).inSeconds.clamp(300, 604800);
    final rows = await _client.rpc(
      'create_circle_invite',
      params: {
        'target_circle_id': circleId,
        'invite_max_uses': maxUses,
        'invite_ttl': '$ttlSeconds seconds',
      },
    );
    final map = Map<String, Object?>.from((rows as List).first);
    final rawToken = '${map['raw_invite_token']}';
    final invite = CircleInvite(
      id: '${map['invite_id']}',
      circleId: circleId,
      codeHint: '${map['code_hint']}',
      expiresAt: DateTime.parse('${map['expires_at']}'),
      maxUses: maxUses,
      useCount: 0,
    );

    return InviteCreationResult(
      invite: invite,
      rawInviteUrl: Uri.parse('${_config.inviteBaseUrl}?token=$rawToken'),
    );
  }

  @override
  Future<void> acceptInvite({required String rawInviteToken}) async {
    await _client.rpc('accept_circle_invite',
        params: {'raw_invite_token': rawInviteToken});
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    await _client.from('circle_invitations').update({
      'status': 'revoked',
      'revoked_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', inviteId);
  }
}

class SupabasePlaceAlertRepository implements PlaceAlertRepository {
  const SupabasePlaceAlertRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PlaceAlertRule>> listPlaceAlerts(String circleId) async {
    final rows = await _client
        .from('place_alerts')
        .select(
          'id, circle_id, name, center_lat, center_lng, radius_m, notify_on_arrival, notify_on_departure, notify_on_late, notify_on_long_stay, quiet_hours, enabled, place_alert_targets(profile_id)',
        )
        .eq('circle_id', circleId)
        .order('created_at', ascending: false);

    return rows
        .map((row) => _placeAlertRuleFromRow(Map<String, Object?>.from(row)))
        .toList(growable: false);
  }

  @override
  Future<PlaceAlertRule> createPlaceAlert(PlaceAlertDraft draft) async {
    final rows = await _client.rpc(
      'create_place_alert_with_targets',
      params: {
        'target_circle_id': draft.circleId,
        'alert_name': draft.name.trim(),
        'target_center_lat': draft.center.latitude,
        'target_center_lng': draft.center.longitude,
        'target_radius_m': draft.radiusM,
        'target_profile_ids': draft.targetProfileIds,
        'notify_arrival': draft.notifyOnArrival,
        'notify_departure': draft.notifyOnDeparture,
        'notify_late': draft.notifyOnLate,
        'notify_long_stay': draft.notifyOnLongStay,
        'quiet_hours': draft.quietHours.toJson(),
      },
    );
    final map = Map<String, Object?>.from((rows as List).first);
    return _placeAlertRuleFromRow(map);
  }

  @override
  Future<PlaceAlertRule> setPlaceAlertEnabled({
    required String alertId,
    required bool enabled,
  }) async {
    final rows = await _client.rpc(
      'set_place_alert_enabled',
      params: {
        'alert_id': alertId,
        'is_enabled': enabled,
      },
    );
    final map = Map<String, Object?>.from((rows as List).first);
    return _placeAlertRuleFromRow(map);
  }

  @override
  Future<void> deletePlaceAlert(String alertId) async {
    await _client.rpc(
      'delete_place_alert',
      params: {'alert_id': alertId},
    );
  }
}

class SupabaseCheckInRepository implements CheckInRepository {
  const SupabaseCheckInRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<CheckInEvent> performCheckIn({
    required String circleId,
    String? companionSessionId,
    CheckInStatus status = CheckInStatus.safeArrived,
  }) async {
    final rows = await _client.rpc(
      'perform_check_in',
      params: {
        'target_circle_id': circleId,
        'target_companion_session_id': companionSessionId,
        'target_status': _checkInStatusToJson(status),
        'client_dedupe_key':
            'manual:${DateTime.now().toUtc().microsecondsSinceEpoch}',
      },
    );
    final map = Map<String, Object?>.from((rows as List).first);
    return _checkInEventFromRow(map, fallbackDisplayName: '나');
  }

  @override
  Future<List<CheckInEvent>> listRecentCheckIns({
    required String circleId,
    int limit = 20,
  }) async {
    final rows = await _client.rpc(
      'list_circle_check_ins',
      params: {
        'target_circle_id': circleId,
        'event_limit': limit,
      },
    );

    return (rows as List)
        .map((row) => _checkInEventFromRow(Map<String, Object?>.from(row)))
        .toList(growable: false);
  }
}

class SupabaseDeviceRepository implements DeviceRepository {
  const SupabaseDeviceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<RegisteredDevice> registerDevice({
    String? deviceId,
    required DevicePlatform platform,
    String? pushToken,
    String? appVersion,
  }) async {
    final payload = <String, Object?>{
      'profile_id': _currentUserId(_client),
      'platform': _devicePlatformToJson(platform),
      'push_token': pushToken,
      'app_version': appVersion,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    };

    final Object row;
    if (deviceId == null) {
      row = await _client
          .from('devices')
          .insert(payload)
          .select('id, platform, push_token, app_version, last_seen_at')
          .single();
    } else {
      row = await _client
          .from('devices')
          .upsert({...payload, 'id': deviceId})
          .select('id, platform, push_token, app_version, last_seen_at')
          .single();
    }

    return _registeredDeviceFromRow(Map<String, Object?>.from(row as Map));
  }

  @override
  Future<void> markSeen(String deviceId) async {
    await _client
        .from('devices')
        .update({
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', deviceId)
        .eq('profile_id', _currentUserId(_client));
  }
}

class SupabaseLocationIngestRepository implements LocationIngestRepository {
  const SupabaseLocationIngestRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> uploadLatest(LocationUpload upload) async {
    await _client.from('latest_locations').upsert(
          _latestLocationRow(_client, upload),
          onConflict: 'profile_id',
        );
  }

  @override
  Future<void> uploadHistoryBatch(List<LocationUpload> uploads) async {
    if (uploads.isEmpty) {
      return;
    }

    await _client.from('location_history').upsert(
          uploads
              .map((upload) => _historyLocationRow(_client, upload))
              .toList(growable: false),
          onConflict: 'profile_id,idempotency_key',
          ignoreDuplicates: true,
        );
  }
}

class SupabasePrivacyRepository implements PrivacyRepository {
  const SupabasePrivacyRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AdPreferences> getAdPreferences() async {
    final row = await _client
        .from('ad_preferences')
        .select(
            'personalized_ads_enabled, sensitive_categories_blocked, precise_location_ads_enabled')
        .eq('profile_id', _currentUserId(_client))
        .single();

    return _adPreferencesFromRow(Map<String, Object?>.from(row));
  }

  @override
  Future<void> requestData(DataRequestType requestType) async {
    await _client.from('data_requests').insert({
      'profile_id': _currentUserId(_client),
      'request_type': _dataRequestTypeToJson(requestType),
    });
  }

  @override
  Future<void> updateSharingPolicy({
    required String circleId,
    required SharingPolicy policy,
  }) async {
    await _client
        .from('sharing_policies')
        .update({
          'precision': _sharingModeToJson(policy.mode),
          'enabled': policy.enabled,
          'paused_until': policy.pausedUntil?.toUtc().toIso8601String(),
          'expires_at': policy.expiresAt?.toUtc().toIso8601String(),
          'consent_version': policy.consentVersion,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('circle_id', circleId)
        .eq('profile_id', _currentUserId(_client));
  }

  @override
  Future<void> updateAdPreferences(AdPreferences preferences) async {
    await _client.from('ad_preferences').upsert({
      'profile_id': _currentUserId(_client),
      'personalized_ads_enabled': preferences.personalizedAdsEnabled,
      'sensitive_categories_blocked': preferences.sensitiveCategoriesBlocked,
      'precise_location_ads_enabled': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

class SupabaseCompanionRepository implements CompanionRepository {
  const SupabaseCompanionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<String> createSession({
    required String circleId,
    required String subjectProfileId,
    required DateTime expiresAt,
  }) async {
    final row = await _client
        .from('companion_sessions')
        .insert({
          'circle_id': circleId,
          'subject_profile_id': subjectProfileId,
          'started_by': _currentUserId(_client),
          'status': 'pending',
          'precision': 'balanced',
          'expires_at': expiresAt.toUtc().toIso8601String(),
        })
        .select('id')
        .single();

    return '${row['id']}';
  }

  @override
  Future<void> consentToSession(String sessionId) async {
    await _client.from('companion_session_members').upsert({
      'session_id': sessionId,
      'profile_id': _currentUserId(_client),
      'consented_at': DateTime.now().toUtc().toIso8601String(),
      'revoked_at': null,
      'can_view': true,
    });
  }

  @override
  Future<void> activateSession(String sessionId) async {
    await _client.from('companion_sessions').update({
      'status': 'active',
      'started_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', sessionId);
  }

  @override
  Future<void> endSession({
    required String sessionId,
    required String reason,
  }) async {
    await _client.from('companion_sessions').update({
      'status': 'ended',
      'ended_at': DateTime.now().toUtc().toIso8601String(),
      'end_reason': reason,
    }).eq('id', sessionId);
  }

  @override
  Stream<CompanionSessionStatus> watchSessionStatus(String sessionId) {
    return _client
        .from('companion_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .map((rows) => rows.isEmpty
            ? CompanionSessionStatus.ended
            : _sessionStatusFromJson('${rows.first['status']}'));
  }
}

Map<String, Object?> _latestLocationRow(
    SupabaseClient client, LocationUpload upload) {
  final sample = upload.sample;
  final row = _baseLocationRow(client, upload);

  return {
    ...row,
    'speed_mps': sample.speedMps,
    'heading_deg': sample.headingDeg,
    'battery_percent': sample.batteryPercent,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
}

Map<String, Object?> _historyLocationRow(
    SupabaseClient client, LocationUpload upload) {
  return {
    ..._baseLocationRow(client, upload),
    'companion_session_id': upload.companionSessionId,
    'idempotency_key': upload.idempotencyKey,
  };
}

Map<String, Object?> _baseLocationRow(
    SupabaseClient client, LocationUpload upload) {
  final sample = upload.sample;
  final hideSharedCoordinate = upload.sharingMode == SharingMode.hidden;

  return {
    'profile_id': _currentUserId(client),
    'device_id': upload.deviceId,
    'source': _locationSourceToJson(sample.source),
    'raw_lat': sample.rawCoordinate.latitude,
    'raw_lng': sample.rawCoordinate.longitude,
    'shared_lat':
        hideSharedCoordinate ? null : sample.sharedCoordinate.latitude,
    'shared_lng':
        hideSharedCoordinate ? null : sample.sharedCoordinate.longitude,
    'accuracy_m': sample.accuracyM,
    'sharing_precision': _sharingModeToJson(upload.sharingMode),
    'recorded_at': sample.recordedAt.toUtc().toIso8601String(),
  };
}

String _currentUserId(SupabaseClient client) {
  final user = client.auth.currentUser;
  if (user == null) {
    throw StateError('Supabase user is not authenticated.');
  }
  return user.id;
}

MemberLocationSnapshot _memberLocationFromRow(Map<String, Object?> map) {
  final lat = map['shared_lat'];
  final lng = map['shared_lng'];
  return MemberLocationSnapshot(
    profileId: '${map['profile_id']}',
    displayName: '${map['display_name'] ?? '멤버'}',
    sharedCoordinate: lat is num && lng is num
        ? Coordinate(latitude: lat.toDouble(), longitude: lng.toDouble())
        : null,
    sharingMode: _sharingModeFromJson('${map['sharing_precision']}'),
    recordedAt: DateTime.parse('${map['recorded_at']}'),
    accuracyM:
        map['accuracy_m'] is num ? (map['accuracy_m'] as num).toDouble() : null,
    batteryPercent: map['battery_percent'] is num
        ? (map['battery_percent'] as num).toInt()
        : null,
  );
}

MemberRoutePoint _memberRoutePointFromRow(Map<String, Object?> map) {
  final lat = map['shared_lat'];
  final lng = map['shared_lng'];
  if (lat is! num || lng is! num) {
    throw StateError('Route point is missing shared coordinates.');
  }

  return MemberRoutePoint(
    profileId: '${map['profile_id']}',
    sharedCoordinate:
        Coordinate(latitude: lat.toDouble(), longitude: lng.toDouble()),
    sharingMode: _sharingModeFromJson('${map['sharing_precision']}'),
    recordedAt: DateTime.parse('${map['recorded_at']}'),
  );
}

RegisteredDevice _registeredDeviceFromRow(Map<String, Object?> map) {
  final lastSeenAt = map['last_seen_at'];

  return RegisteredDevice(
    id: '${map['id']}',
    platform: _devicePlatformFromJson('${map['platform']}'),
    pushToken: map['push_token']?.toString(),
    appVersion: map['app_version']?.toString(),
    lastSeenAt: lastSeenAt == null ? null : DateTime.parse('$lastSeenAt'),
  );
}

PlaceAlertRule _placeAlertRuleFromRow(Map<String, Object?> map) {
  final targets = map['place_alert_targets'];
  final targetCount = map['target_count'];
  return PlaceAlertRule(
    id: '${map['id']}',
    circleId: '${map['circle_id']}',
    name: '${map['name'] ?? '장소'}',
    center: Coordinate(
      latitude: (map['center_lat'] as num).toDouble(),
      longitude: (map['center_lng'] as num).toDouble(),
    ),
    radiusM: map['radius_m'] is num ? (map['radius_m'] as num).toInt() : 100,
    notifyOnArrival: map['notify_on_arrival'] == true,
    notifyOnDeparture: map['notify_on_departure'] == true,
    notifyOnLate: map['notify_on_late'] == true,
    notifyOnLongStay: map['notify_on_long_stay'] == true,
    quietHours: _placeAlertQuietHoursFromJson(map['quiet_hours']),
    enabled: map['enabled'] != false,
    targetCount: targetCount is num
        ? targetCount.toInt()
        : targets is List
            ? targets.length
            : 0,
  );
}

PlaceAlertQuietHours _placeAlertQuietHoursFromJson(Object? value) {
  if (value is! Map || value['enabled'] != true) {
    return const PlaceAlertQuietHours.none();
  }

  return PlaceAlertQuietHours(
    enabled: true,
    start: value['start']?.toString(),
    end: value['end']?.toString(),
    timeZone: value['timeZone']?.toString(),
    label: value['label']?.toString(),
  );
}

CheckInEvent _checkInEventFromRow(
  Map<String, Object?> map, {
  String fallbackDisplayName = '멤버',
}) {
  return CheckInEvent(
    id: '${map['id']}',
    circleId: '${map['circle_id']}',
    actorProfileId: '${map['actor_profile_id']}',
    subjectProfileId: '${map['subject_profile_id']}',
    displayName: '${map['display_name'] ?? fallbackDisplayName}',
    status: _checkInStatusFromJson('${map['status']}'),
    sharingMode: _sharingModeFromJson('${map['sharing_precision']}'),
    companionSessionId: map['companion_session_id']?.toString(),
    createdAt: DateTime.parse('${map['created_at']}'),
  );
}

AdPreferences _adPreferencesFromRow(Map<String, Object?> map) {
  return AdPreferences(
    personalizedAdsEnabled: map['personalized_ads_enabled'] == true,
    sensitiveCategoriesBlocked: map['sensitive_categories_blocked'] != false,
    preciseLocationAdsEnabled: false,
  );
}

CheckInStatus _checkInStatusFromJson(String value) {
  switch (value) {
    case 'needs_check':
      return CheckInStatus.needsCheck;
    case 'signal_weak':
      return CheckInStatus.signalWeak;
    case 'safe_arrived':
    default:
      return CheckInStatus.safeArrived;
  }
}

String _checkInStatusToJson(CheckInStatus status) {
  switch (status) {
    case CheckInStatus.safeArrived:
      return 'safe_arrived';
    case CheckInStatus.needsCheck:
      return 'needs_check';
    case CheckInStatus.signalWeak:
      return 'signal_weak';
  }
}

DevicePlatform _devicePlatformFromJson(String value) {
  switch (value) {
    case 'ios':
      return DevicePlatform.ios;
    case 'android':
    default:
      return DevicePlatform.android;
  }
}

String _devicePlatformToJson(DevicePlatform platform) {
  switch (platform) {
    case DevicePlatform.ios:
      return 'ios';
    case DevicePlatform.android:
      return 'android';
  }
}

SharingMode _sharingModeFromJson(String value) {
  switch (value) {
    case 'precise':
      return SharingMode.precise;
    case 'area':
      return SharingMode.area;
    case 'hidden':
      return SharingMode.hidden;
    case 'sos_only':
      return SharingMode.sosOnly;
    case 'balanced':
    default:
      return SharingMode.balanced;
  }
}

String _locationSourceToJson(LocationSource source) {
  switch (source) {
    case LocationSource.gps:
      return 'gps';
    case LocationSource.network:
      return 'network';
    case LocationSource.significantChange:
      return 'significant_change';
    case LocationSource.geofence:
      return 'geofence';
    case LocationSource.sos:
      return 'sos';
    case LocationSource.unknown:
      return 'unknown';
  }
}

String _sharingModeToJson(SharingMode mode) {
  switch (mode) {
    case SharingMode.precise:
      return 'precise';
    case SharingMode.balanced:
      return 'balanced';
    case SharingMode.area:
      return 'area';
    case SharingMode.hidden:
      return 'hidden';
    case SharingMode.sosOnly:
      return 'sos_only';
  }
}

String _dataRequestTypeToJson(DataRequestType requestType) {
  switch (requestType) {
    case DataRequestType.export:
      return 'export';
    case DataRequestType.deleteHistory:
      return 'delete_history';
    case DataRequestType.deleteAccount:
      return 'delete_account';
  }
}

CompanionSessionStatus _sessionStatusFromJson(String value) {
  switch (value) {
    case 'pending':
      return CompanionSessionStatus.pending;
    case 'active':
      return CompanionSessionStatus.active;
    case 'expired':
      return CompanionSessionStatus.expired;
    case 'cancelled':
      return CompanionSessionStatus.cancelled;
    case 'ended':
    default:
      return CompanionSessionStatus.ended;
  }
}
