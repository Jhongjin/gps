// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppL10nKo extends AppL10n {
  AppL10nKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '곁에';

  @override
  String get navMap => '지도';

  @override
  String get navCircle => '서클';

  @override
  String get navHistory => '기록';

  @override
  String get navPrivacy => '안심';

  @override
  String get signOut => '로그아웃';

  @override
  String get mapDefaultCircleName => '우리 서클';

  @override
  String get mapLayersTooltip => '지도 종류';

  @override
  String get mapInvite => '초대';

  @override
  String get mapMeShort => '나';

  @override
  String mapSharingCount(int count) {
    return '$count명이 위치 공유 중';
  }

  @override
  String mapAttentionCount(int count) {
    return '확인 필요 $count';
  }

  @override
  String get mapConnecting => '서클 위치 연결 중';

  @override
  String get mapNoCircle => '아직 연결된 서클 없음';

  @override
  String get mapDemoNotice => '아직 서버 위치가 없어 데모 위치 표시 중';

  @override
  String get sosLabel => 'SOS';

  @override
  String get sosButtonSemantics => '긴급 공유. 길게 눌러 시작';

  @override
  String get sosArming => '긴급 공유 준비';

  @override
  String get sosSecondsRemaining => '초 후 전송';

  @override
  String sosAudience(String audience) {
    return '$audience에게\n정확 위치와 배터리를 보냅니다';
  }

  @override
  String get sosNoAds => '이 화면에는 광고가 표시되지 않습니다.';

  @override
  String get sosCancel => '취소';

  @override
  String get sosSendNow => '지금 보내기';

  @override
  String get memberBattery => '배터리';

  @override
  String get memberAccuracy => '정확도';

  @override
  String get memberUpdated => '갱신';

  @override
  String get memberCall => '전화';

  @override
  String get memberNudge => '깨우기';

  @override
  String get memberDirections => '길찾기';

  @override
  String memberPrecisionTitle(String name) {
    return '$name이(가) 나에게 공유하는 정확도';
  }

  @override
  String memberPrecisionConsent(String name) {
    return '바꾸려면 $name의 동의가 필요합니다. 요청을 보내면 상대 기기에 알림이 갑니다.';
  }

  @override
  String get viewerLogTitle => '이 위치를 본 사람';

  @override
  String get viewerLogSubtitle => '조회 기록은 안심 탭에서 전체를 볼 수 있습니다.';

  @override
  String get viewerLogOpen => '기록';

  @override
  String get precisionPrecise => '정확';

  @override
  String get precisionBalanced => '균형';

  @override
  String get precisionArea => '동네만';

  @override
  String get precisionHidden => '숨김';

  @override
  String get relativeJustNow => '방금';

  @override
  String relativeMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String relativeHours(int hours) {
    return '$hours시간';
  }

  @override
  String relativeDays(int days) {
    return '$days일';
  }

  @override
  String get valueUnknown => '—';

  @override
  String get adSlotSemantics => '스폰서 영역';

  @override
  String get adSlotTitle => '스폰서';

  @override
  String get adSlotBody => '위치 데이터와 분리된 광고 영역';

  @override
  String get adSlotBadge => '테스트';

  @override
  String get memberFallbackName => '멤버';

  @override
  String get sharingModePrecise => '정확';

  @override
  String get sharingModeBalanced => '균형';

  @override
  String get sharingModeArea => '동네 범위';

  @override
  String get sharingModeHidden => '숨김';

  @override
  String get sharingModeSosOnly => '긴급 전용';

  @override
  String statusSharing(String mode) {
    return '$mode 공유 중';
  }

  @override
  String get statusWaitingUpdate => '위치 업데이트 대기 중';

  @override
  String get statusLastKnownOnly => '마지막 위치만 표시 중';

  @override
  String get statusLowBattery => '배터리가 낮아 업데이트가 느릴 수 있어요';

  @override
  String metaOldLocation(String time) {
    return '오래된 위치 · $time';
  }

  @override
  String metaLastLocation(String time) {
    return '마지막 위치 · $time';
  }

  @override
  String metaBattery(int percent) {
    return '배터리 $percent%';
  }

  @override
  String metaAccuracy(String distance) {
    return '정확도 $distance';
  }

  @override
  String get metaJustUpdated => '방금 업데이트';

  @override
  String get noteVeryStale => '현재 위치가 아닐 수 있어요. 연결이 돌아오면 다시 업데이트돼요.';

  @override
  String get noteStale => '배터리, 신호, 권한 상태 때문에 늦을 수 있어요.';

  @override
  String get noteLowBattery => '배터리가 낮아 업데이트가 느릴 수 있어요.';

  @override
  String get agoJustNow => '방금';

  @override
  String agoMinutes(int minutes) {
    return '$minutes분 전';
  }

  @override
  String agoHours(int hours) {
    return '$hours시간 전';
  }

  @override
  String agoDays(int days) {
    return '$days일 전';
  }

  @override
  String get demoNameChild => '준';

  @override
  String get demoNameFriend => '하나';

  @override
  String get demoNameElder => '할아버지';

  @override
  String get deviceArrivedStatus => '무사 도착 · 방금 확인';

  @override
  String get deviceArrivedMeta => '동행 공유 종료 · 균형 위치로 알림';

  @override
  String get historyTitle => '오늘 활동';

  @override
  String get historySubtitle => '장소 알림, 조회 로그, 동행 세션, 안전 확인';

  @override
  String get historySyncing => '활동 기록 동기화 중';

  @override
  String get historyLoadFailed => '활동 기록을 불러오지 못했습니다.';

  @override
  String get historyFilterAll => '전체';

  @override
  String get historyFilterCheckIn => '확인';

  @override
  String get historyFilterPlace => '장소';

  @override
  String get historyFilterCompanion => '동행';

  @override
  String get historyFilterData => '데이터';

  @override
  String get historyFilterEmpty => '이 필터의 활동이 없습니다';

  @override
  String get historyFilterEmptyHint => '다른 활동 필터를 선택하면 오늘 기록을 다시 볼 수 있습니다.';

  @override
  String historyCheckInCount(int count) {
    return '안전 확인 $count개';
  }

  @override
  String get historyNoAds => '광고 없음';

  @override
  String get historySafetyLoading => '안전 확인과 동행 종료 기록을 불러오고 있습니다.';

  @override
  String get historySafetyEmpty => '오늘 안전 확인이 없습니다';

  @override
  String get historySafetyEmptyHint => '동행 중 도착 확인을 보내면 이곳에 무사 도착 기록이 남습니다.';

  @override
  String get historySafetyNoRecent => '최근 도착 확인이 아직 없습니다.';

  @override
  String get checkInSafeArrived => '무사 도착';

  @override
  String get checkInPending => '안전 확인 대기';

  @override
  String get checkInNeedsCheck => '확인 필요';

  @override
  String get checkInWeakSignal => '신호가 잠시 약해요';

  @override
  String companionEndedNote(String mode) {
    return '동행 공유 종료 · $mode 위치로 알림';
  }

  @override
  String get demoEventPlaceArrival => '준 학교 도착';

  @override
  String get demoEventPlaceArrivalDetail => '예상보다 4분 빠름';

  @override
  String get demoEventViewed => '미라가 내 위치 확인';

  @override
  String get demoEventViewedDetail => '가족 서클 · 균형 위치';

  @override
  String get demoEventCompanion => '할아버지 산책 시작';

  @override
  String get demoEventCompanionDetail => '15분 동행 세션 · 상호 동의';

  @override
  String get demoEventCheckIn => '준 무사 도착';

  @override
  String get demoEventCheckInDetail => '동행 공유 종료 · 균형 위치로 알림';

  @override
  String get demoEventDataRequest => '위치 기록 삭제 요청';

  @override
  String get demoEventDataRequestDetail => '처리 대기 중';

  @override
  String get historyTypeViewed => '조회';

  @override
  String get authTagline => '가까운 사람끼리만, 필요한 만큼 위치를 나눠요.';

  @override
  String get authBadgeConsent => '동의 기반 공유';

  @override
  String get authBadgeViewerLog => '조회 기록';

  @override
  String get authBadgeNoAdTargeting => '정밀 위치 광고 차단';

  @override
  String get authSignIn => '로그인';

  @override
  String get authSignUp => '가입';

  @override
  String get authSignUpCta => '가입하고 시작';

  @override
  String get authEmail => '이메일';

  @override
  String get authPassword => '비밀번호';

  @override
  String get authDisplayName => '이름 또는 별명';

  @override
  String get authEmailRequired => '이메일을 입력해 주세요.';

  @override
  String get authPasswordTooShort => '6자 이상 입력해 주세요.';

  @override
  String get authGenericError => '처리 중 문제가 생겼습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get authVerifyEmailSent => '가입 확인 메일을 보냈습니다. 메일 확인 후 다시 로그인해 주세요.';

  @override
  String get authConsentNote => '초대받은 서클과 상호 동의한 동행 모드에서만 위치가 공유됩니다.';

  @override
  String get authPrivacyNote => '정밀 위치는 광고에 사용하지 않으며, 언제든 공유를 멈출 수 있어요.';

  @override
  String get privacyTitle => '안심 설정';

  @override
  String get privacySubtitle => '공유, 조회 기록, 광고, 삭제 요청';

  @override
  String get privacySharingScopeTitle => '공유 범위';

  @override
  String get privacySharingScopeBody => '지도와 동행 모드의 기본 위치 공유';

  @override
  String get privacyPauseSharing => '공유 멈춤';

  @override
  String get privacyPausedNotice => '1시간 동안 위치 공유를 멈췄습니다.';

  @override
  String get privacyPauseFailed => '공유 멈춤을 저장하지 못했습니다.';

  @override
  String get privacyPauseNeedsBackend => 'Supabase 연결 후 공유를 멈출 수 있습니다.';

  @override
  String get privacyModePreciseTitle => '정확한 위치';

  @override
  String get privacyModePreciseBody => '공유 정밀도에 맞춰 지도 반경을 표시합니다.';

  @override
  String get privacyModeBalancedTitle => '균형 공유';

  @override
  String get privacyModeBalancedBody => '일상 공유에 맞춰 위치 최신성과 배터리를 함께 봅니다.';

  @override
  String get privacyModeApprox => '대략';

  @override
  String get privacyModeApproxBody => '대략 위치에서는 반경 원으로 표시됩니다.';

  @override
  String get privacyModeAdjusted => '현재 위치를 보정해서 표시';

  @override
  String get privacyModeHidesExact => '정확 좌표 숨김';

  @override
  String get privacyBatteryTitle => '배터리 모드';

  @override
  String get privacyBatteryBody => '배터리가 낮을 때 업데이트 간격을 늘리고 주요 알림을 우선합니다.';

  @override
  String get privacyBatteryRealtime => '실시간';

  @override
  String get privacyBatterySaver => '절전';

  @override
  String get privacyBatteryRealtimeNote => '실시간 우선';

  @override
  String get privacyBatteryBalancedNote => '균형 우선';

  @override
  String get privacyBatterySaverNote => '절전 우선';

  @override
  String get privacyBatteryFast => '빠른 갱신';

  @override
  String get privacyBatterySlow => '느린 갱신';

  @override
  String get privacyInterval15to30 => '15-30초';

  @override
  String get privacyInterval30to90 => '30-90초';

  @override
  String get privacyInterval2to5 => '2-5분';

  @override
  String get privacyCompanionBatteryNote =>
      '동행 중 빠르게 업데이트하며 배터리 사용량이 높아질 수 있습니다.';

  @override
  String get privacyPermissionTitle => '권한 상태';

  @override
  String get privacyPermissionRefresh => '권한 상태 새로고침';

  @override
  String get privacyPermissionFailed => '기기 권한 상태를 확인하지 못했습니다.';

  @override
  String get privacyPermissionBuildOnly => 'Android/iOS 빌드에서 기기 권한을 확인합니다.';

  @override
  String get privacyPermissionBuildOnlyShort => 'Android/iOS에서 실제 권한을 확인합니다.';

  @override
  String get privacyPermissionLocation => '위치 권한';

  @override
  String get privacyPermissionBackground => '배경 위치';

  @override
  String get privacyPermissionNotifications => '알림';

  @override
  String get privacyPermissionDeviceBuild => '기기 빌드';

  @override
  String get privacyPermissionGranted => '허용됨';

  @override
  String get privacyPermissionWhileInUse => '앱 사용 중';

  @override
  String get privacyPermissionUnknown => '확인 전';

  @override
  String get privacyPermissionWhenNeeded => '필요 시';

  @override
  String get privacyPermissionEducationNote => '위치 공유 시작 전에 권한 안내가 필요합니다.';

  @override
  String get privacyPermissionStagedNote => '동행, 장소 알림처럼 켜진 기능에서 단계적으로 요청';

  @override
  String get privacyNotificationsBody => '도착 확인, 장소 알림, SOS 수신';

  @override
  String get privacyNotificationsTitle => '안심 알림';

  @override
  String get privacyViewerLogTitle => '최근 조회';

  @override
  String get privacyViewerLogLabel => '조회 로그';

  @override
  String get privacyViewerLogNote => '내가 확인 가능';

  @override
  String get privacyViewerFamilyBalanced => '가족 서클 · 균형 위치';

  @override
  String get privacyViewerFriendsArea => '친구 서클 · 동네만';

  @override
  String get privacyCircleFamily => '가족 서클';

  @override
  String get privacyCircleFriends => '친구 서클';

  @override
  String get demoNameGuardian => '미라';

  @override
  String get privacyViewer12MinAgo => '12분 전';

  @override
  String get privacyViewerYesterday => '어제';

  @override
  String get privacyAdsTitle => '광고와 데이터';

  @override
  String get privacyAdsPersonalized => '개인화 광고';

  @override
  String get privacyAdsPersonalizedBody => '동의 전에는 비개인화 광고만 사용';

  @override
  String get privacyAdsSensitiveBlock => '민감 카테고리 차단';

  @override
  String get privacyAdsSensitiveBody => '가족, 위치, 응급 상황 문맥 보호';

  @override
  String get privacyAdsNoPreciseTargeting => '정밀 위치 광고 차단';

  @override
  String get privacyAdsLoadFailed => '광고 설정을 불러오지 못했습니다.';

  @override
  String get privacyAdsSaveFailed => '광고 설정을 저장하지 못했습니다.';

  @override
  String get privacyAdsSaved => '광고 설정을 저장했습니다.';

  @override
  String get privacyAdsNeedsBackend => 'Supabase 연결 후 광고 설정을 저장할 수 있습니다.';

  @override
  String get privacyDataTitle => '내 데이터';

  @override
  String get privacyDataExport => '내보내기';

  @override
  String get privacyDataDelete => '기록 삭제';

  @override
  String get privacyDataExportSent => '데이터 내보내기 요청을 보냈습니다.';

  @override
  String get privacyDataDeleteSent => '기록 삭제 요청을 보냈습니다.';

  @override
  String get privacyDataRequestFailed => '데이터 요청을 보내지 못했습니다.';

  @override
  String get privacyDataNeedsBackend => 'Supabase 연결 후 데이터 요청을 보낼 수 있습니다.';

  @override
  String get privacyDataLocationHistory => '위치 기록';

  @override
  String get privacyDataCompanionRoutes => '동행 경로';

  @override
  String get privacyDataCompanionRoutesBody => '동행 세션 · 경로 꼬리';

  @override
  String get privacyRetention30Days => '30일';

  @override
  String get privacyRetention24Hours => '24시간';

  @override
  String get privacyRetentionAutoDelete => '만료 후 자동 삭제';

  @override
  String get privacyRetentionSummaryOnly => '세션 종료 후 요약 보관';

  @override
  String get privacyRecommended => '추천';

  @override
  String get privacySaving => '저장 중';

  @override
  String get privacyRequesting => '요청 중';

  @override
  String get privacyPending => '대기';

  @override
  String get privacyCompanionMode => '동행 모드';

  @override
  String get privacyCompanionConsentNote => '준과 상호 동의 완료 후 시작';

  @override
  String get privacyCompanion15MinLeft => '15분 남음';

  @override
  String get mapOpenCircle => '서클';

  @override
  String get mapOnboardTitle => '첫 서클을 시작하세요';

  @override
  String get mapOnboardBody => '초대가 완료되면 지도에 공유 위치가 표시됩니다.';

  @override
  String get placeDraftTitle => '장소 반경';

  @override
  String get placeDraftSubtitle => '도착/이탈 규칙 저장';

  @override
  String get placeDraftNameLabel => '장소 이름';

  @override
  String get placeDraftNameHint => '새 장소';

  @override
  String get placeDraftSave => '장소 알림 저장';

  @override
  String get placeDraftSaving => '장소 알림 저장 중';

  @override
  String get placeRuleArrival => '도착';

  @override
  String get placeRuleDeparture => '이탈';

  @override
  String get placeRuleLate => '늦음';

  @override
  String get placeRuleLongStay => '오래 머무름';

  @override
  String get quietHoursNone => '없음';

  @override
  String get quietHoursNight => '야간';

  @override
  String get quietHoursClass => '수업';

  @override
  String get quietHoursClassOrWork => '수업/근무';

  @override
  String get quietHoursNoneCopy => '중요한 도착/이탈 알림을 항상 받을 수 있습니다.';

  @override
  String get quietHoursNightCopy => '22:00-07:00에는 긴급하지 않은 장소 알림을 조용히 처리합니다.';

  @override
  String get quietHoursClassCopy => '09:00-17:00에는 반복적인 장소 알림을 줄이는 preset입니다.';

  @override
  String get placeAlertNeedsBackend => 'Supabase 연결 후 저장할 수 있습니다.';

  @override
  String get placeAlertPickTarget => '대상 멤버를 선택해 주세요.';

  @override
  String get placeAlertNeedsName => '장소 이름을 입력해 주세요.';

  @override
  String get placeAlertNeedsRule => '알림 조건을 하나 이상 선택해 주세요.';

  @override
  String get placeAlertSaveFailed => '장소 알림을 저장하지 못했습니다. 대상과 공유 범위를 확인해 주세요.';

  @override
  String get placeAlertNeedsLiveCircle => '실제 서클 위치가 연결되면 저장할 수 있습니다.';

  @override
  String get placeAlertReady => '장소 알림 준비됨';

  @override
  String get placeAlertUnregistered => '장소 알림 반경이 기기에서 해제됨';

  @override
  String get placeAlertSavedPendingDevice => '장소 알림은 저장됨 · 기기 반경 등록 대기 중';

  @override
  String get placeAlertEnter => '저장한 장소 반경에 도착했습니다.';

  @override
  String get placeAlertExit => '저장한 장소 반경을 벗어났습니다.';

  @override
  String get placeAlertTransition => '저장한 장소 반경 변화가 감지됐습니다.';

  @override
  String get companionStart => '시작';

  @override
  String get companionFifteenMinutes => '15분';

  @override
  String get companionUntilArrival => '도착까지';

  @override
  String get companionCheckIn => '도착 확인';

  @override
  String get companionCheckInSending => '도착 확인을 보내는 중';

  @override
  String get companionCheckInFailed => '도착 확인을 보내지 못했습니다.';

  @override
  String get companionArrivedSent => '무사 도착을 보냈어요. 동행 공유는 종료됐습니다.';

  @override
  String get companionStarted => '동행 모드 위치 공유 시작';

  @override
  String get companionStartedWithSession => '동행 모드 위치 공유 시작 · 세션 연결됨';

  @override
  String get companionStopped => '동행 모드 위치 공유 중지';

  @override
  String get companionStartFailed => '동행 모드를 시작하지 못했습니다.';

  @override
  String get companionEndSyncPending => '동행 세션 종료 동기화 대기 중';

  @override
  String get checkInSyncPending => '안전 확인 기록 동기화 대기 중';

  @override
  String get uploadSyncTitle => '위치 동기화';

  @override
  String get uploadFlush => '대기 위치 동기화';

  @override
  String get uploadNothingPending => '업로드할 대기 위치 없음';

  @override
  String get uploadQueueReady => '업로드 큐 준비됨';

  @override
  String get uploadQueueWaiting => '업로드 큐 대기';

  @override
  String get uploadQueueSyncing => '업로드 큐 동기화 중';

  @override
  String get uploadQueueRequesting => '업로드 큐 동기화 요청 중';

  @override
  String get uploadQueueRequested => '업로드 큐 동기화 요청됨';

  @override
  String get uploadQueueRequestFailed => '업로드 큐 동기화를 요청하지 못했습니다.';

  @override
  String get uploadQueueConfigPending => '업로드 큐 설정 대기 중';

  @override
  String get uploadDeviceConfigPending => '기기 업로드 큐 설정 대기 중';

  @override
  String get uploadDeviceReady => '기기 업로드 큐 준비됨';

  @override
  String get uploadDeviceDisconnected => '기기 업로드 큐 연결 해제';

  @override
  String get uploadFailedRetryScheduled => '업로드 실패 · 자동 재시도 예약';

  @override
  String get uploadNeedsSignIn => '로그인 후 업로드 큐 연결';

  @override
  String get uploadIosPending => 'iOS 업로드 큐 구현 대기 중';

  @override
  String get uploadBuildOnly => 'Android/iOS 빌드에서 업로드 큐를 사용할 수 있습니다.';

  @override
  String get deviceLocationBuildOnly => 'Android/iOS 빌드에서 기기 위치를 사용할 수 있습니다.';

  @override
  String get sosBuildOnly => 'Android/iOS 빌드에서 긴급 위치를 보낼 수 있습니다.';

  @override
  String get deviceLocationBridgeNote => '기기 위치는 Android/iOS 빌드에서 연결됩니다.';

  @override
  String get deviceBridgeFailed => '기기 위치 브리지를 연결하지 못했습니다.';

  @override
  String get deviceReceiving => '내 위치 수신 중';

  @override
  String get deviceSharingRunning => '위치 공유 실행 중';

  @override
  String get deviceSharingStopped => '위치 공유 중지됨';

  @override
  String get devicePermissionChecked => '위치 권한 상태 확인됨';

  @override
  String get deviceLocationServiceAvailable => '위치 서비스 사용 가능';

  @override
  String get deviceLocationError => '위치 연결 오류';

  @override
  String get sosRequesting => '긴급 위치 요청 중';

  @override
  String get sosRequestFailed => '긴급 위치를 요청하지 못했습니다.';

  @override
  String get circleLoadFailed => '서클을 불러오지 못했습니다.';

  @override
  String get locationLoadFailed => '위치를 불러오지 못했습니다.';

  @override
  String get sharingHidden => '공유 숨김';

  @override
  String get sharingPausedByPolicy => '공유 정책에 따라 위치 수집 일시정지';

  @override
  String get precisionExactLocation => '정확 위치';

  @override
  String get precisionBalancedLocation => '균형 위치';

  @override
  String get checkInStatusChanged => '상태 변경';

  @override
  String companionMinutesLeft(int minutes) {
    return '$minutes분 남음';
  }

  @override
  String uploadPendingCount(int count) {
    return '대기 $count건';
  }

  @override
  String uploadCompleted(int count) {
    return '위치 업로드 완료 · $count건';
  }

  @override
  String uploadRetryIn(int seconds) {
    return '업로드 재시도 대기 · $seconds초 후';
  }

  @override
  String placeAlertRegistered(int count) {
    return '장소 알림 반경 $count개 기기 등록됨';
  }

  @override
  String placeAlertSaved(String name, int count) {
    return '$name 저장됨 · 대상 $count명';
  }

  @override
  String deviceLocationService(String status) {
    return '위치 서비스 $status';
  }

  @override
  String precisionRange(String mode, String radius) {
    return '$mode · 약 $radius 범위';
  }

  @override
  String precisionRangeStale(String mode, String radius) {
    return '마지막 위치 · $mode · 약 $radius 범위';
  }

  @override
  String companionConfigNote(int seconds, String mode) {
    return '최소 $seconds초 간격 · $mode 공유 · 상호 동의 후 시작';
  }

  @override
  String checkInEventLine(String name, String status, String time) {
    return '$name · $status · $time';
  }

  @override
  String get quietHoursOff => '없음';

  @override
  String get quietHoursOn => '설정됨';

  @override
  String get circleCreate => '서클 만들기';

  @override
  String get circleCreateFirst => '서클을 먼저 만들어 주세요';

  @override
  String get circleCreateFirstBody => '첫 서클을 만들고 가까운 사람을 초대하세요';

  @override
  String get circleSyncing => '서클 동기화 중';

  @override
  String get circleManageMembers => '멤버 관리';

  @override
  String get circleNoMembers => '아직 멤버가 없습니다';

  @override
  String get circleNoMembersBody => '초대 링크를 만들면 이곳에 수락한 멤버가 표시됩니다.';

  @override
  String get inviteLink => '초대 링크';

  @override
  String get inviteCreate => '초대하기';

  @override
  String get inviteNewLink => '새 링크';

  @override
  String get inviteCopy => '복사';

  @override
  String get inviteJoin => '초대 참여';

  @override
  String get inviteAccept => '참여';

  @override
  String get inviteTokenLabel => '초대 링크 또는 토큰';

  @override
  String get inviteTokenRequired => '초대 링크나 토큰을 입력해 주세요.';

  @override
  String get inviteCreated => '24시간 초대 링크를 만들었습니다.';

  @override
  String get inviteCreateFailed => '초대 링크를 만들지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get inviteCopied => '초대 링크를 복사했습니다.';

  @override
  String get inviteAccepted => '초대를 수락했습니다.';

  @override
  String get inviteAcceptFailed => '초대를 수락하지 못했습니다. 만료 여부를 확인해 주세요.';

  @override
  String get inviteNeedsBackend => 'Supabase 연결 후 실제 초대 링크를 만들 수 있습니다.';

  @override
  String get inviteAcceptNeedsBackend => 'Supabase 연결 후 초대를 수락할 수 있습니다.';

  @override
  String get inviteSafetyNote => '1회 사용 · 수락 전 공유 범위 확인 · 원문 토큰 저장 안 함';

  @override
  String get inviteVerifyInviter => '초대자 확인';

  @override
  String get inviteVerifyToken => '토큰 확인';

  @override
  String get inviteConsentLocation => '위치 동의';

  @override
  String get roleGuardian => '보호자';

  @override
  String get roleChild => '자녀';

  @override
  String get roleFriend => '친구';

  @override
  String get roleCare => '케어';

  @override
  String get sharingPreciseShort => '정확 공유';

  @override
  String get sharingBalancedShort => '균형 공유';

  @override
  String get companionWaiting => '동행 대기';

  @override
  String get companionRequest => '동행 요청';

  @override
  String get companionAllow => '동행 허용';

  @override
  String get companionLater => '나중에';

  @override
  String get companionRequestDemo => '준 · 학교에서 집까지';

  @override
  String get companionRequestBody => '15분 동안 균형 위치와 경로 꼬리만 공유됩니다.';

  @override
  String get checkInSectionTitle => '안전 확인';

  @override
  String get checkInLoading => '안전 확인 기록을 불러오는 중입니다.';

  @override
  String get checkInLoadFailed => '안전 확인 기록을 불러오지 못했습니다.';

  @override
  String get checkInSyncFailed => '안전 확인 동기화 실패';

  @override
  String get checkInNoneRecent => '최근 안전 확인이 없습니다';

  @override
  String get checkInEmptyBody => '동행 중 도착 확인을 보내면 이곳에 무사 도착 기록이 표시됩니다.';

  @override
  String get checkInNote => '도착 확인은 서클 멤버에게 짧은 안심 신호로 전달됩니다.';

  @override
  String get checkInTroubleshoot => '배터리, 신호, 권한, 기기 상태를 확인해 주세요.';

  @override
  String get checkInDemoScope => '가족 전체 · 도착 확인';

  @override
  String get checkInDemoLongStay => '할아버지 · 오래 머무름 확인';

  @override
  String get checkInDemoDetail => '동행 공유 종료 · 균형 위치로 알림 · 방금';

  @override
  String get placeAlertSectionTitle => '장소 알림';

  @override
  String get placeAlertLoading => '장소 알림을 불러오는 중입니다.';

  @override
  String get placeAlertLoadFailed => '장소 알림을 불러오지 못했습니다.';

  @override
  String get placeAlertNone => '저장된 장소 알림이 없습니다';

  @override
  String get placeAlertNoneBody => '장소 알림은 서클 멤버와 공유 범위를 정한 뒤 사용할 수 있습니다.';

  @override
  String get placeAlertHint =>
      '지도에서 반경을 미리 보고 대상 멤버를 고른 뒤 안전한 알림 규칙으로 추가할 예정입니다.';

  @override
  String get placeAlertUpdating => '장소 알림 업데이트';

  @override
  String get placeAlertUpdateFailed => '장소 알림 변경 실패';

  @override
  String get placeAlertToggleFailed => '장소 알림 상태를 변경하지 못했습니다.';

  @override
  String get placeAlertPaused => '장소 알림을 일시정지했습니다.';

  @override
  String get placeAlertResumed => '장소 알림을 다시 켰습니다.';

  @override
  String get placeAlertDeleteTitle => '장소 알림 삭제';

  @override
  String get placeAlertDeleted => '장소 알림을 삭제했습니다.';

  @override
  String get placeAlertDeleteFailed => '장소 알림을 삭제하지 못했습니다.';

  @override
  String get quietHoursChange => '조용한 시간 변경';

  @override
  String get quietHoursChangeFailed => '조용한 시간을 변경하지 못했습니다.';

  @override
  String get placeAlertChangeNeedsBackend => 'Supabase 연결 후 장소 알림을 변경할 수 있습니다.';

  @override
  String get placeAlertDeleteNeedsBackend => 'Supabase 연결 후 장소 알림을 삭제할 수 있습니다.';

  @override
  String get quietHoursNeedsBackend => 'Supabase 연결 후 조용한 시간을 변경할 수 있습니다.';

  @override
  String get placeAlertServerOnlyUpdate => '서버 변경은 완료됐고, 기기 반경 동기화는 대기 중입니다.';

  @override
  String get placeAlertServerOnlyDelete => '서버 삭제는 완료됐고, 기기 반경 동기화는 대기 중입니다.';

  @override
  String get deviceSyncPending => '기기 동기화 대기';

  @override
  String get syncLabel => '동기화';

  @override
  String get pauseLabel => '일시정지';

  @override
  String get resumeLabel => '다시 켜기';

  @override
  String get pendingLabel => '대기 중';

  @override
  String get targetsUnset => '대상 미지정';

  @override
  String get rulesNone => '알림 조건 없음';

  @override
  String get mutualConsent => '상호 동의';

  @override
  String get adNotice => '광고 안내';

  @override
  String get sampleLabel => '예시';

  @override
  String get placeHome => '집';

  @override
  String get placeSchool => '학교';

  @override
  String get placeClinic => '병원';

  @override
  String get placeAlertDemoRule => '평일 08:00-17:00 · 도착/이탈 · 10분 지연';

  @override
  String targetCount(int count) {
    return '$count명';
  }

  @override
  String itemCount(int count) {
    return '$count개';
  }

  @override
  String radiusMeters(int meters) {
    return '반경 ${meters}m';
  }

  @override
  String quietHoursSummary(String summary) {
    return '조용한 시간 $summary';
  }

  @override
  String quietHoursChanged(String summary) {
    return '조용한 시간을 $summary(으)로 변경했습니다.';
  }

  @override
  String placeAlertDeleteConfirm(String name) {
    return '$name 알림을 삭제할까요? 대상 멤버에게 더 이상 도착/이탈 알림이 가지 않습니다.';
  }

  @override
  String circleSummary(int count) {
    return '$count명 · 장소 3개 · 동행 세션 1개 대기';
  }

  @override
  String checkInDetailLine(String mode, String time) {
    return '$mode 위치로 알림 · $time';
  }

  @override
  String a11yMemberRow(String name, String status) {
    return '$name, $status. 두 번 눌러 상세 보기';
  }

  @override
  String a11yBatteryLevel(int percent) {
    return '배터리 $percent퍼센트';
  }

  @override
  String get a11yStaleLocation => '위치가 오래됐습니다';

  @override
  String a11yAttentionBadge(int count) {
    return '확인이 필요한 멤버 $count명';
  }

  @override
  String get onboardWelcomeTitle => '가까운 사람과, 필요한 만큼만';

  @override
  String get onboardWelcomeBody =>
      '곁에는 서로 초대하고 동의한 사이에서만 위치를 나눕니다. 몰래 보는 방법은 만들지 않습니다.';

  @override
  String get onboardConsentTitle => '누가 나를 볼 수 있는지 항상 보입니다';

  @override
  String get onboardConsentBody =>
      '서클마다 공유 정확도를 정하고, 언제든 멈출 수 있어요. 누가 언제 내 위치를 봤는지도 기록으로 남습니다.';

  @override
  String get onboardPermissionTitle => '위치 권한이 왜 필요한가요';

  @override
  String get onboardPermissionBody =>
      '지도에 서로의 위치를 그리려면 기기 위치가 필요합니다. 다음 화면에서 시스템이 물어보고, 허용 여부는 직접 정하시면 됩니다.';

  @override
  String get onboardNext => '다음';

  @override
  String get onboardStart => '시작하기';

  @override
  String get onboardSkip => '건너뛰기';

  @override
  String onboardStepOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get primerContinue => '계속';

  @override
  String get primerLater => '나중에';

  @override
  String get primerWhenInUseTitle => '앱을 쓰는 동안 위치가 필요합니다';

  @override
  String get primerWhenInUseBody =>
      '동행 모드에서 지도에 내 위치를 그리려면 필요합니다. 다음 화면에서 시스템이 물어봅니다.';

  @override
  String get primerAlwaysTitle => '장소 알림에는 백그라운드 위치가 필요합니다';

  @override
  String get primerAlwaysBody =>
      '앱이 꺼져 있어도 저장한 장소에 도착·이탈했는지 확인하려면 필요합니다. 이 권한 없이는 장소 알림이 동작하지 않습니다.';

  @override
  String get primerPromise => '정밀 위치는 광고에 쓰지 않고, 공유는 언제든 멈출 수 있습니다.';

  @override
  String get checkInOnTheWay => '가는 중';

  @override
  String get checkInImOk => '괜찮아';

  @override
  String get checkInCallMe => '전화해줘';

  @override
  String get quickReplyTitle => '한 번에 알리기';

  @override
  String quickReplySent(String label) {
    return '$label 보냈어요';
  }

  @override
  String get quickReplyFailed => '보내지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get quickReplyNeedsCircle => '서클에 연결되면 보낼 수 있습니다.';

  @override
  String get meetupSectionTitle => '약속';

  @override
  String get meetupCreate => '약속 만들기';

  @override
  String get meetupNone => '잡힌 약속이 없습니다';

  @override
  String get meetupNoneBody => '집결 장소와 시각을 정하면 서로의 도착까지 남은 시간이 보입니다.';

  @override
  String get meetupNameLabel => '약속 이름';

  @override
  String get meetupNameHint => '저녁 약속';

  @override
  String get meetupPlaceHint => '지도에 표시된 자리가 집결 장소가 됩니다.';

  @override
  String get meetupIn30 => '30분 뒤';

  @override
  String get meetupIn1h => '1시간 뒤';

  @override
  String get meetupIn2h => '2시간 뒤';

  @override
  String get meetupSave => '약속 만들기';

  @override
  String get meetupSaving => '약속 만드는 중';

  @override
  String get meetupCreated => '약속을 만들었습니다.';

  @override
  String get meetupCreateFailed => '약속을 만들지 못했습니다.';

  @override
  String get meetupNeedsCircle => '서클에 연결되면 약속을 만들 수 있습니다.';

  @override
  String get meetupGoing => '참석';

  @override
  String get meetupMaybe => '미정';

  @override
  String get meetupDeclined => '불참';

  @override
  String get meetupRespondFailed => '응답을 저장하지 못했습니다.';

  @override
  String get meetupEnd => '약속 끝내기';

  @override
  String get meetupEndFailed => '약속을 끝내지 못했습니다.';

  @override
  String meetupGoingCount(int going, int total) {
    return '참석 $going/$total';
  }

  @override
  String meetupStartsIn(String time) {
    return '$time 뒤';
  }

  @override
  String meetupStartedAgo(String time) {
    return '$time 지남';
  }

  @override
  String meetupAutoEnds(int minutes) {
    return '약속 시각 $minutes분 뒤 자동으로 사라집니다';
  }

  @override
  String get meetupDestination => '집결 장소';
}
