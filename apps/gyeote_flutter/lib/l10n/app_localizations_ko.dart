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
}
