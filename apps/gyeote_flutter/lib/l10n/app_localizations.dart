import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// 앱 이름
  ///
  /// In ko, this message translates to:
  /// **'곁에'**
  String get appTitle;

  /// No description provided for @navMap.
  ///
  /// In ko, this message translates to:
  /// **'지도'**
  String get navMap;

  /// No description provided for @navCircle.
  ///
  /// In ko, this message translates to:
  /// **'서클'**
  String get navCircle;

  /// No description provided for @navHistory.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get navHistory;

  /// 프라이버시 탭. '설정'이 아니라 '안심'이다 — 감시가 아닌 기다림의 톤
  ///
  /// In ko, this message translates to:
  /// **'안심'**
  String get navPrivacy;

  /// No description provided for @signOut.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get signOut;

  /// No description provided for @mapDefaultCircleName.
  ///
  /// In ko, this message translates to:
  /// **'우리 서클'**
  String get mapDefaultCircleName;

  /// No description provided for @mapLayersTooltip.
  ///
  /// In ko, this message translates to:
  /// **'지도 종류'**
  String get mapLayersTooltip;

  /// No description provided for @mapInvite.
  ///
  /// In ko, this message translates to:
  /// **'초대'**
  String get mapInvite;

  /// No description provided for @mapMeShort.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get mapMeShort;

  /// No description provided for @mapSharingCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}명이 위치 공유 중'**
  String mapSharingCount(int count);

  /// No description provided for @mapAttentionCount.
  ///
  /// In ko, this message translates to:
  /// **'확인 필요 {count}'**
  String mapAttentionCount(int count);

  /// No description provided for @mapConnecting.
  ///
  /// In ko, this message translates to:
  /// **'서클 위치 연결 중'**
  String get mapConnecting;

  /// No description provided for @mapNoCircle.
  ///
  /// In ko, this message translates to:
  /// **'아직 연결된 서클 없음'**
  String get mapNoCircle;

  /// No description provided for @mapDemoNotice.
  ///
  /// In ko, this message translates to:
  /// **'아직 서버 위치가 없어 데모 위치 표시 중'**
  String get mapDemoNotice;

  /// No description provided for @sosLabel.
  ///
  /// In ko, this message translates to:
  /// **'SOS'**
  String get sosLabel;

  /// 탭 한 번으로는 발동하지 않는다는 것을 스크린리더에도 알린다
  ///
  /// In ko, this message translates to:
  /// **'긴급 공유. 길게 눌러 시작'**
  String get sosButtonSemantics;

  /// No description provided for @sosArming.
  ///
  /// In ko, this message translates to:
  /// **'긴급 공유 준비'**
  String get sosArming;

  /// No description provided for @sosSecondsRemaining.
  ///
  /// In ko, this message translates to:
  /// **'초 후 전송'**
  String get sosSecondsRemaining;

  /// No description provided for @sosAudience.
  ///
  /// In ko, this message translates to:
  /// **'{audience}에게\n정확 위치와 배터리를 보냅니다'**
  String sosAudience(String audience);

  /// No description provided for @sosNoAds.
  ///
  /// In ko, this message translates to:
  /// **'이 화면에는 광고가 표시되지 않습니다.'**
  String get sosNoAds;

  /// No description provided for @sosCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get sosCancel;

  /// No description provided for @sosSendNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 보내기'**
  String get sosSendNow;

  /// No description provided for @memberBattery.
  ///
  /// In ko, this message translates to:
  /// **'배터리'**
  String get memberBattery;

  /// No description provided for @memberAccuracy.
  ///
  /// In ko, this message translates to:
  /// **'정확도'**
  String get memberAccuracy;

  /// No description provided for @memberUpdated.
  ///
  /// In ko, this message translates to:
  /// **'갱신'**
  String get memberUpdated;

  /// No description provided for @memberCall.
  ///
  /// In ko, this message translates to:
  /// **'전화'**
  String get memberCall;

  /// No description provided for @memberNudge.
  ///
  /// In ko, this message translates to:
  /// **'깨우기'**
  String get memberNudge;

  /// No description provided for @memberDirections.
  ///
  /// In ko, this message translates to:
  /// **'길찾기'**
  String get memberDirections;

  /// No description provided for @memberPrecisionTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name}이(가) 나에게 공유하는 정확도'**
  String memberPrecisionTitle(String name);

  /// 정확도는 일방적으로 올릴 수 없다. 동의 우선 원칙의 UI 증거
  ///
  /// In ko, this message translates to:
  /// **'바꾸려면 {name}의 동의가 필요합니다. 요청을 보내면 상대 기기에 알림이 갑니다.'**
  String memberPrecisionConsent(String name);

  /// No description provided for @viewerLogTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 위치를 본 사람'**
  String get viewerLogTitle;

  /// No description provided for @viewerLogSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'조회 기록은 안심 탭에서 전체를 볼 수 있습니다.'**
  String get viewerLogSubtitle;

  /// No description provided for @viewerLogOpen.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get viewerLogOpen;

  /// No description provided for @precisionPrecise.
  ///
  /// In ko, this message translates to:
  /// **'정확'**
  String get precisionPrecise;

  /// No description provided for @precisionBalanced.
  ///
  /// In ko, this message translates to:
  /// **'균형'**
  String get precisionBalanced;

  /// No description provided for @precisionArea.
  ///
  /// In ko, this message translates to:
  /// **'동네만'**
  String get precisionArea;

  /// No description provided for @precisionHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨김'**
  String get precisionHidden;

  /// No description provided for @relativeJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get relativeJustNow;

  /// No description provided for @relativeMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String relativeMinutes(int minutes);

  /// No description provided for @relativeHours.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간'**
  String relativeHours(int hours);

  /// No description provided for @relativeDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String relativeDays(int days);

  /// No description provided for @valueUnknown.
  ///
  /// In ko, this message translates to:
  /// **'—'**
  String get valueUnknown;

  /// No description provided for @adSlotSemantics.
  ///
  /// In ko, this message translates to:
  /// **'스폰서 영역'**
  String get adSlotSemantics;

  /// No description provided for @adSlotTitle.
  ///
  /// In ko, this message translates to:
  /// **'스폰서'**
  String get adSlotTitle;

  /// 정밀 위치·SOS·권한 데이터가 광고 타깃팅에 쓰이지 않는다는 사실을 알린다
  ///
  /// In ko, this message translates to:
  /// **'위치 데이터와 분리된 광고 영역'**
  String get adSlotBody;

  /// No description provided for @adSlotBadge.
  ///
  /// In ko, this message translates to:
  /// **'테스트'**
  String get adSlotBadge;

  /// No description provided for @memberFallbackName.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get memberFallbackName;

  /// No description provided for @sharingModePrecise.
  ///
  /// In ko, this message translates to:
  /// **'정확'**
  String get sharingModePrecise;

  /// No description provided for @sharingModeBalanced.
  ///
  /// In ko, this message translates to:
  /// **'균형'**
  String get sharingModeBalanced;

  /// No description provided for @sharingModeArea.
  ///
  /// In ko, this message translates to:
  /// **'동네 범위'**
  String get sharingModeArea;

  /// No description provided for @sharingModeHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨김'**
  String get sharingModeHidden;

  /// No description provided for @sharingModeSosOnly.
  ///
  /// In ko, this message translates to:
  /// **'긴급 전용'**
  String get sharingModeSosOnly;

  /// No description provided for @statusSharing.
  ///
  /// In ko, this message translates to:
  /// **'{mode} 공유 중'**
  String statusSharing(String mode);

  /// No description provided for @statusWaitingUpdate.
  ///
  /// In ko, this message translates to:
  /// **'위치 업데이트 대기 중'**
  String get statusWaitingUpdate;

  /// No description provided for @statusLastKnownOnly.
  ///
  /// In ko, this message translates to:
  /// **'마지막 위치만 표시 중'**
  String get statusLastKnownOnly;

  /// No description provided for @statusLowBattery.
  ///
  /// In ko, this message translates to:
  /// **'배터리가 낮아 업데이트가 느릴 수 있어요'**
  String get statusLowBattery;

  /// No description provided for @metaOldLocation.
  ///
  /// In ko, this message translates to:
  /// **'오래된 위치 · {time}'**
  String metaOldLocation(String time);

  /// No description provided for @metaLastLocation.
  ///
  /// In ko, this message translates to:
  /// **'마지막 위치 · {time}'**
  String metaLastLocation(String time);

  /// No description provided for @metaBattery.
  ///
  /// In ko, this message translates to:
  /// **'배터리 {percent}%'**
  String metaBattery(int percent);

  /// No description provided for @metaAccuracy.
  ///
  /// In ko, this message translates to:
  /// **'정확도 {distance}'**
  String metaAccuracy(String distance);

  /// No description provided for @metaJustUpdated.
  ///
  /// In ko, this message translates to:
  /// **'방금 업데이트'**
  String get metaJustUpdated;

  /// No description provided for @noteVeryStale.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치가 아닐 수 있어요. 연결이 돌아오면 다시 업데이트돼요.'**
  String get noteVeryStale;

  /// No description provided for @noteStale.
  ///
  /// In ko, this message translates to:
  /// **'배터리, 신호, 권한 상태 때문에 늦을 수 있어요.'**
  String get noteStale;

  /// No description provided for @noteLowBattery.
  ///
  /// In ko, this message translates to:
  /// **'배터리가 낮아 업데이트가 느릴 수 있어요.'**
  String get noteLowBattery;

  /// No description provided for @agoJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get agoJustNow;

  /// No description provided for @agoMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 전'**
  String agoMinutes(int minutes);

  /// No description provided for @agoHours.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 전'**
  String agoHours(int hours);

  /// No description provided for @agoDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전'**
  String agoDays(int days);

  /// No description provided for @demoNameChild.
  ///
  /// In ko, this message translates to:
  /// **'준'**
  String get demoNameChild;

  /// No description provided for @demoNameFriend.
  ///
  /// In ko, this message translates to:
  /// **'하나'**
  String get demoNameFriend;

  /// No description provided for @demoNameElder.
  ///
  /// In ko, this message translates to:
  /// **'할아버지'**
  String get demoNameElder;

  /// No description provided for @deviceArrivedStatus.
  ///
  /// In ko, this message translates to:
  /// **'무사 도착 · 방금 확인'**
  String get deviceArrivedStatus;

  /// No description provided for @deviceArrivedMeta.
  ///
  /// In ko, this message translates to:
  /// **'동행 공유 종료 · 균형 위치로 알림'**
  String get deviceArrivedMeta;

  /// No description provided for @historyTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 활동'**
  String get historyTitle;

  /// No description provided for @historySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림, 조회 로그, 동행 세션, 안전 확인'**
  String get historySubtitle;

  /// No description provided for @historySyncing.
  ///
  /// In ko, this message translates to:
  /// **'활동 기록 동기화 중'**
  String get historySyncing;

  /// No description provided for @historyLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'활동 기록을 불러오지 못했습니다.'**
  String get historyLoadFailed;

  /// No description provided for @historyFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get historyFilterAll;

  /// No description provided for @historyFilterCheckIn.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get historyFilterCheckIn;

  /// No description provided for @historyFilterPlace.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get historyFilterPlace;

  /// No description provided for @historyFilterCompanion.
  ///
  /// In ko, this message translates to:
  /// **'동행'**
  String get historyFilterCompanion;

  /// No description provided for @historyFilterData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get historyFilterData;

  /// No description provided for @historyFilterEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 필터의 활동이 없습니다'**
  String get historyFilterEmpty;

  /// No description provided for @historyFilterEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'다른 활동 필터를 선택하면 오늘 기록을 다시 볼 수 있습니다.'**
  String get historyFilterEmptyHint;

  /// No description provided for @historyCheckInCount.
  ///
  /// In ko, this message translates to:
  /// **'안전 확인 {count}개'**
  String historyCheckInCount(int count);

  /// No description provided for @historyNoAds.
  ///
  /// In ko, this message translates to:
  /// **'광고 없음'**
  String get historyNoAds;

  /// No description provided for @historySafetyLoading.
  ///
  /// In ko, this message translates to:
  /// **'안전 확인과 동행 종료 기록을 불러오고 있습니다.'**
  String get historySafetyLoading;

  /// No description provided for @historySafetyEmpty.
  ///
  /// In ko, this message translates to:
  /// **'오늘 안전 확인이 없습니다'**
  String get historySafetyEmpty;

  /// No description provided for @historySafetyEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'동행 중 도착 확인을 보내면 이곳에 무사 도착 기록이 남습니다.'**
  String get historySafetyEmptyHint;

  /// No description provided for @historySafetyNoRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 도착 확인이 아직 없습니다.'**
  String get historySafetyNoRecent;

  /// No description provided for @checkInSafeArrived.
  ///
  /// In ko, this message translates to:
  /// **'무사 도착'**
  String get checkInSafeArrived;

  /// No description provided for @checkInPending.
  ///
  /// In ko, this message translates to:
  /// **'안전 확인 대기'**
  String get checkInPending;

  /// No description provided for @checkInNeedsCheck.
  ///
  /// In ko, this message translates to:
  /// **'확인 필요'**
  String get checkInNeedsCheck;

  /// No description provided for @checkInWeakSignal.
  ///
  /// In ko, this message translates to:
  /// **'신호가 잠시 약해요'**
  String get checkInWeakSignal;

  /// No description provided for @companionEndedNote.
  ///
  /// In ko, this message translates to:
  /// **'동행 공유 종료 · {mode} 위치로 알림'**
  String companionEndedNote(String mode);

  /// No description provided for @demoEventPlaceArrival.
  ///
  /// In ko, this message translates to:
  /// **'준 학교 도착'**
  String get demoEventPlaceArrival;

  /// No description provided for @demoEventPlaceArrivalDetail.
  ///
  /// In ko, this message translates to:
  /// **'예상보다 4분 빠름'**
  String get demoEventPlaceArrivalDetail;

  /// No description provided for @demoEventViewed.
  ///
  /// In ko, this message translates to:
  /// **'미라가 내 위치 확인'**
  String get demoEventViewed;

  /// No description provided for @demoEventViewedDetail.
  ///
  /// In ko, this message translates to:
  /// **'가족 서클 · 균형 위치'**
  String get demoEventViewedDetail;

  /// No description provided for @demoEventCompanion.
  ///
  /// In ko, this message translates to:
  /// **'할아버지 산책 시작'**
  String get demoEventCompanion;

  /// No description provided for @demoEventCompanionDetail.
  ///
  /// In ko, this message translates to:
  /// **'15분 동행 세션 · 상호 동의'**
  String get demoEventCompanionDetail;

  /// No description provided for @demoEventCheckIn.
  ///
  /// In ko, this message translates to:
  /// **'준 무사 도착'**
  String get demoEventCheckIn;

  /// No description provided for @demoEventCheckInDetail.
  ///
  /// In ko, this message translates to:
  /// **'동행 공유 종료 · 균형 위치로 알림'**
  String get demoEventCheckInDetail;

  /// No description provided for @demoEventDataRequest.
  ///
  /// In ko, this message translates to:
  /// **'위치 기록 삭제 요청'**
  String get demoEventDataRequest;

  /// No description provided for @demoEventDataRequestDetail.
  ///
  /// In ko, this message translates to:
  /// **'처리 대기 중'**
  String get demoEventDataRequestDetail;

  /// No description provided for @historyTypeViewed.
  ///
  /// In ko, this message translates to:
  /// **'조회'**
  String get historyTypeViewed;

  /// No description provided for @authTagline.
  ///
  /// In ko, this message translates to:
  /// **'가까운 사람끼리만, 필요한 만큼 위치를 나눠요.'**
  String get authTagline;

  /// No description provided for @authBadgeConsent.
  ///
  /// In ko, this message translates to:
  /// **'동의 기반 공유'**
  String get authBadgeConsent;

  /// No description provided for @authBadgeViewerLog.
  ///
  /// In ko, this message translates to:
  /// **'조회 기록'**
  String get authBadgeViewerLog;

  /// No description provided for @authBadgeNoAdTargeting.
  ///
  /// In ko, this message translates to:
  /// **'정밀 위치 광고 차단'**
  String get authBadgeNoAdTargeting;

  /// No description provided for @authSignIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In ko, this message translates to:
  /// **'가입'**
  String get authSignUp;

  /// No description provided for @authSignUpCta.
  ///
  /// In ko, this message translates to:
  /// **'가입하고 시작'**
  String get authSignUpCta;

  /// No description provided for @authEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get authPassword;

  /// No description provided for @authDisplayName.
  ///
  /// In ko, this message translates to:
  /// **'이름 또는 별명'**
  String get authDisplayName;

  /// No description provided for @authEmailRequired.
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해 주세요.'**
  String get authEmailRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In ko, this message translates to:
  /// **'6자 이상 입력해 주세요.'**
  String get authPasswordTooShort;

  /// No description provided for @authGenericError.
  ///
  /// In ko, this message translates to:
  /// **'처리 중 문제가 생겼습니다. 잠시 후 다시 시도해 주세요.'**
  String get authGenericError;

  /// No description provided for @authVerifyEmailSent.
  ///
  /// In ko, this message translates to:
  /// **'가입 확인 메일을 보냈습니다. 메일 확인 후 다시 로그인해 주세요.'**
  String get authVerifyEmailSent;

  /// No description provided for @authConsentNote.
  ///
  /// In ko, this message translates to:
  /// **'초대받은 서클과 상호 동의한 동행 모드에서만 위치가 공유됩니다.'**
  String get authConsentNote;

  /// No description provided for @authPrivacyNote.
  ///
  /// In ko, this message translates to:
  /// **'정밀 위치는 광고에 사용하지 않으며, 언제든 공유를 멈출 수 있어요.'**
  String get authPrivacyNote;

  /// No description provided for @privacyTitle.
  ///
  /// In ko, this message translates to:
  /// **'안심 설정'**
  String get privacyTitle;

  /// No description provided for @privacySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'공유, 조회 기록, 광고, 삭제 요청'**
  String get privacySubtitle;

  /// No description provided for @privacySharingScopeTitle.
  ///
  /// In ko, this message translates to:
  /// **'공유 범위'**
  String get privacySharingScopeTitle;

  /// No description provided for @privacySharingScopeBody.
  ///
  /// In ko, this message translates to:
  /// **'지도와 동행 모드의 기본 위치 공유'**
  String get privacySharingScopeBody;

  /// No description provided for @privacyPauseSharing.
  ///
  /// In ko, this message translates to:
  /// **'공유 멈춤'**
  String get privacyPauseSharing;

  /// No description provided for @privacyPausedNotice.
  ///
  /// In ko, this message translates to:
  /// **'1시간 동안 위치 공유를 멈췄습니다.'**
  String get privacyPausedNotice;

  /// No description provided for @privacyPauseFailed.
  ///
  /// In ko, this message translates to:
  /// **'공유 멈춤을 저장하지 못했습니다.'**
  String get privacyPauseFailed;

  /// No description provided for @privacyPauseNeedsBackend.
  ///
  /// In ko, this message translates to:
  /// **'Supabase 연결 후 공유를 멈출 수 있습니다.'**
  String get privacyPauseNeedsBackend;

  /// No description provided for @privacyModePreciseTitle.
  ///
  /// In ko, this message translates to:
  /// **'정확한 위치'**
  String get privacyModePreciseTitle;

  /// No description provided for @privacyModePreciseBody.
  ///
  /// In ko, this message translates to:
  /// **'공유 정밀도에 맞춰 지도 반경을 표시합니다.'**
  String get privacyModePreciseBody;

  /// No description provided for @privacyModeBalancedTitle.
  ///
  /// In ko, this message translates to:
  /// **'균형 공유'**
  String get privacyModeBalancedTitle;

  /// No description provided for @privacyModeBalancedBody.
  ///
  /// In ko, this message translates to:
  /// **'일상 공유에 맞춰 위치 최신성과 배터리를 함께 봅니다.'**
  String get privacyModeBalancedBody;

  /// No description provided for @privacyModeApprox.
  ///
  /// In ko, this message translates to:
  /// **'대략'**
  String get privacyModeApprox;

  /// No description provided for @privacyModeApproxBody.
  ///
  /// In ko, this message translates to:
  /// **'대략 위치에서는 반경 원으로 표시됩니다.'**
  String get privacyModeApproxBody;

  /// No description provided for @privacyModeAdjusted.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치를 보정해서 표시'**
  String get privacyModeAdjusted;

  /// No description provided for @privacyModeHidesExact.
  ///
  /// In ko, this message translates to:
  /// **'정확 좌표 숨김'**
  String get privacyModeHidesExact;

  /// No description provided for @privacyBatteryTitle.
  ///
  /// In ko, this message translates to:
  /// **'배터리 모드'**
  String get privacyBatteryTitle;

  /// No description provided for @privacyBatteryBody.
  ///
  /// In ko, this message translates to:
  /// **'배터리가 낮을 때 업데이트 간격을 늘리고 주요 알림을 우선합니다.'**
  String get privacyBatteryBody;

  /// No description provided for @privacyBatteryRealtime.
  ///
  /// In ko, this message translates to:
  /// **'실시간'**
  String get privacyBatteryRealtime;

  /// No description provided for @privacyBatterySaver.
  ///
  /// In ko, this message translates to:
  /// **'절전'**
  String get privacyBatterySaver;

  /// No description provided for @privacyBatteryRealtimeNote.
  ///
  /// In ko, this message translates to:
  /// **'실시간 우선'**
  String get privacyBatteryRealtimeNote;

  /// No description provided for @privacyBatteryBalancedNote.
  ///
  /// In ko, this message translates to:
  /// **'균형 우선'**
  String get privacyBatteryBalancedNote;

  /// No description provided for @privacyBatterySaverNote.
  ///
  /// In ko, this message translates to:
  /// **'절전 우선'**
  String get privacyBatterySaverNote;

  /// No description provided for @privacyBatteryFast.
  ///
  /// In ko, this message translates to:
  /// **'빠른 갱신'**
  String get privacyBatteryFast;

  /// No description provided for @privacyBatterySlow.
  ///
  /// In ko, this message translates to:
  /// **'느린 갱신'**
  String get privacyBatterySlow;

  /// No description provided for @privacyInterval15to30.
  ///
  /// In ko, this message translates to:
  /// **'15-30초'**
  String get privacyInterval15to30;

  /// No description provided for @privacyInterval30to90.
  ///
  /// In ko, this message translates to:
  /// **'30-90초'**
  String get privacyInterval30to90;

  /// No description provided for @privacyInterval2to5.
  ///
  /// In ko, this message translates to:
  /// **'2-5분'**
  String get privacyInterval2to5;

  /// No description provided for @privacyCompanionBatteryNote.
  ///
  /// In ko, this message translates to:
  /// **'동행 중 빠르게 업데이트하며 배터리 사용량이 높아질 수 있습니다.'**
  String get privacyCompanionBatteryNote;

  /// No description provided for @privacyPermissionTitle.
  ///
  /// In ko, this message translates to:
  /// **'권한 상태'**
  String get privacyPermissionTitle;

  /// No description provided for @privacyPermissionRefresh.
  ///
  /// In ko, this message translates to:
  /// **'권한 상태 새로고침'**
  String get privacyPermissionRefresh;

  /// No description provided for @privacyPermissionFailed.
  ///
  /// In ko, this message translates to:
  /// **'기기 권한 상태를 확인하지 못했습니다.'**
  String get privacyPermissionFailed;

  /// No description provided for @privacyPermissionBuildOnly.
  ///
  /// In ko, this message translates to:
  /// **'Android/iOS 빌드에서 기기 권한을 확인합니다.'**
  String get privacyPermissionBuildOnly;

  /// No description provided for @privacyPermissionBuildOnlyShort.
  ///
  /// In ko, this message translates to:
  /// **'Android/iOS에서 실제 권한을 확인합니다.'**
  String get privacyPermissionBuildOnlyShort;

  /// No description provided for @privacyPermissionLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치 권한'**
  String get privacyPermissionLocation;

  /// No description provided for @privacyPermissionBackground.
  ///
  /// In ko, this message translates to:
  /// **'배경 위치'**
  String get privacyPermissionBackground;

  /// No description provided for @privacyPermissionNotifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get privacyPermissionNotifications;

  /// No description provided for @privacyPermissionDeviceBuild.
  ///
  /// In ko, this message translates to:
  /// **'기기 빌드'**
  String get privacyPermissionDeviceBuild;

  /// No description provided for @privacyPermissionGranted.
  ///
  /// In ko, this message translates to:
  /// **'허용됨'**
  String get privacyPermissionGranted;

  /// No description provided for @privacyPermissionWhileInUse.
  ///
  /// In ko, this message translates to:
  /// **'앱 사용 중'**
  String get privacyPermissionWhileInUse;

  /// No description provided for @privacyPermissionUnknown.
  ///
  /// In ko, this message translates to:
  /// **'확인 전'**
  String get privacyPermissionUnknown;

  /// No description provided for @privacyPermissionWhenNeeded.
  ///
  /// In ko, this message translates to:
  /// **'필요 시'**
  String get privacyPermissionWhenNeeded;

  /// No description provided for @privacyPermissionEducationNote.
  ///
  /// In ko, this message translates to:
  /// **'위치 공유 시작 전에 권한 안내가 필요합니다.'**
  String get privacyPermissionEducationNote;

  /// No description provided for @privacyPermissionStagedNote.
  ///
  /// In ko, this message translates to:
  /// **'동행, 장소 알림처럼 켜진 기능에서 단계적으로 요청'**
  String get privacyPermissionStagedNote;

  /// No description provided for @privacyNotificationsBody.
  ///
  /// In ko, this message translates to:
  /// **'도착 확인, 장소 알림, SOS 수신'**
  String get privacyNotificationsBody;

  /// No description provided for @privacyNotificationsTitle.
  ///
  /// In ko, this message translates to:
  /// **'안심 알림'**
  String get privacyNotificationsTitle;

  /// No description provided for @privacyViewerLogTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 조회'**
  String get privacyViewerLogTitle;

  /// No description provided for @privacyViewerLogLabel.
  ///
  /// In ko, this message translates to:
  /// **'조회 로그'**
  String get privacyViewerLogLabel;

  /// No description provided for @privacyViewerLogNote.
  ///
  /// In ko, this message translates to:
  /// **'내가 확인 가능'**
  String get privacyViewerLogNote;

  /// No description provided for @privacyViewerFamilyBalanced.
  ///
  /// In ko, this message translates to:
  /// **'가족 서클 · 균형 위치'**
  String get privacyViewerFamilyBalanced;

  /// No description provided for @privacyViewerFriendsArea.
  ///
  /// In ko, this message translates to:
  /// **'친구 서클 · 동네만'**
  String get privacyViewerFriendsArea;

  /// No description provided for @privacyCircleFamily.
  ///
  /// In ko, this message translates to:
  /// **'가족 서클'**
  String get privacyCircleFamily;

  /// No description provided for @privacyCircleFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구 서클'**
  String get privacyCircleFriends;

  /// No description provided for @demoNameGuardian.
  ///
  /// In ko, this message translates to:
  /// **'미라'**
  String get demoNameGuardian;

  /// No description provided for @privacyViewer12MinAgo.
  ///
  /// In ko, this message translates to:
  /// **'12분 전'**
  String get privacyViewer12MinAgo;

  /// No description provided for @privacyViewerYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get privacyViewerYesterday;

  /// No description provided for @privacyAdsTitle.
  ///
  /// In ko, this message translates to:
  /// **'광고와 데이터'**
  String get privacyAdsTitle;

  /// No description provided for @privacyAdsPersonalized.
  ///
  /// In ko, this message translates to:
  /// **'개인화 광고'**
  String get privacyAdsPersonalized;

  /// No description provided for @privacyAdsPersonalizedBody.
  ///
  /// In ko, this message translates to:
  /// **'동의 전에는 비개인화 광고만 사용'**
  String get privacyAdsPersonalizedBody;

  /// No description provided for @privacyAdsSensitiveBlock.
  ///
  /// In ko, this message translates to:
  /// **'민감 카테고리 차단'**
  String get privacyAdsSensitiveBlock;

  /// No description provided for @privacyAdsSensitiveBody.
  ///
  /// In ko, this message translates to:
  /// **'가족, 위치, 응급 상황 문맥 보호'**
  String get privacyAdsSensitiveBody;

  /// No description provided for @privacyAdsNoPreciseTargeting.
  ///
  /// In ko, this message translates to:
  /// **'정밀 위치 광고 차단'**
  String get privacyAdsNoPreciseTargeting;

  /// No description provided for @privacyAdsLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'광고 설정을 불러오지 못했습니다.'**
  String get privacyAdsLoadFailed;

  /// No description provided for @privacyAdsSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'광고 설정을 저장하지 못했습니다.'**
  String get privacyAdsSaveFailed;

  /// No description provided for @privacyAdsSaved.
  ///
  /// In ko, this message translates to:
  /// **'광고 설정을 저장했습니다.'**
  String get privacyAdsSaved;

  /// No description provided for @privacyAdsNeedsBackend.
  ///
  /// In ko, this message translates to:
  /// **'Supabase 연결 후 광고 설정을 저장할 수 있습니다.'**
  String get privacyAdsNeedsBackend;

  /// No description provided for @privacyDataTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 데이터'**
  String get privacyDataTitle;

  /// No description provided for @privacyDataExport.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get privacyDataExport;

  /// No description provided for @privacyDataDelete.
  ///
  /// In ko, this message translates to:
  /// **'기록 삭제'**
  String get privacyDataDelete;

  /// No description provided for @privacyDataExportSent.
  ///
  /// In ko, this message translates to:
  /// **'데이터 내보내기 요청을 보냈습니다.'**
  String get privacyDataExportSent;

  /// No description provided for @privacyDataDeleteSent.
  ///
  /// In ko, this message translates to:
  /// **'기록 삭제 요청을 보냈습니다.'**
  String get privacyDataDeleteSent;

  /// No description provided for @privacyDataRequestFailed.
  ///
  /// In ko, this message translates to:
  /// **'데이터 요청을 보내지 못했습니다.'**
  String get privacyDataRequestFailed;

  /// No description provided for @privacyDataNeedsBackend.
  ///
  /// In ko, this message translates to:
  /// **'Supabase 연결 후 데이터 요청을 보낼 수 있습니다.'**
  String get privacyDataNeedsBackend;

  /// No description provided for @privacyDataLocationHistory.
  ///
  /// In ko, this message translates to:
  /// **'위치 기록'**
  String get privacyDataLocationHistory;

  /// No description provided for @privacyDataCompanionRoutes.
  ///
  /// In ko, this message translates to:
  /// **'동행 경로'**
  String get privacyDataCompanionRoutes;

  /// No description provided for @privacyDataCompanionRoutesBody.
  ///
  /// In ko, this message translates to:
  /// **'동행 세션 · 경로 꼬리'**
  String get privacyDataCompanionRoutesBody;

  /// No description provided for @privacyRetention30Days.
  ///
  /// In ko, this message translates to:
  /// **'30일'**
  String get privacyRetention30Days;

  /// No description provided for @privacyRetention24Hours.
  ///
  /// In ko, this message translates to:
  /// **'24시간'**
  String get privacyRetention24Hours;

  /// No description provided for @privacyRetentionAutoDelete.
  ///
  /// In ko, this message translates to:
  /// **'만료 후 자동 삭제'**
  String get privacyRetentionAutoDelete;

  /// No description provided for @privacyRetentionSummaryOnly.
  ///
  /// In ko, this message translates to:
  /// **'세션 종료 후 요약 보관'**
  String get privacyRetentionSummaryOnly;

  /// No description provided for @privacyRecommended.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get privacyRecommended;

  /// No description provided for @privacySaving.
  ///
  /// In ko, this message translates to:
  /// **'저장 중'**
  String get privacySaving;

  /// No description provided for @privacyRequesting.
  ///
  /// In ko, this message translates to:
  /// **'요청 중'**
  String get privacyRequesting;

  /// No description provided for @privacyPending.
  ///
  /// In ko, this message translates to:
  /// **'대기'**
  String get privacyPending;

  /// No description provided for @privacyCompanionMode.
  ///
  /// In ko, this message translates to:
  /// **'동행 모드'**
  String get privacyCompanionMode;

  /// No description provided for @privacyCompanionConsentNote.
  ///
  /// In ko, this message translates to:
  /// **'준과 상호 동의 완료 후 시작'**
  String get privacyCompanionConsentNote;

  /// No description provided for @privacyCompanion15MinLeft.
  ///
  /// In ko, this message translates to:
  /// **'15분 남음'**
  String get privacyCompanion15MinLeft;

  /// No description provided for @mapOpenCircle.
  ///
  /// In ko, this message translates to:
  /// **'서클'**
  String get mapOpenCircle;

  /// No description provided for @mapOnboardTitle.
  ///
  /// In ko, this message translates to:
  /// **'첫 서클을 시작하세요'**
  String get mapOnboardTitle;

  /// No description provided for @mapOnboardBody.
  ///
  /// In ko, this message translates to:
  /// **'초대가 완료되면 지도에 공유 위치가 표시됩니다.'**
  String get mapOnboardBody;

  /// No description provided for @placeDraftTitle.
  ///
  /// In ko, this message translates to:
  /// **'장소 반경'**
  String get placeDraftTitle;

  /// No description provided for @placeDraftSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'도착/이탈 규칙 저장'**
  String get placeDraftSubtitle;

  /// No description provided for @placeDraftNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'장소 이름'**
  String get placeDraftNameLabel;

  /// No description provided for @placeDraftNameHint.
  ///
  /// In ko, this message translates to:
  /// **'새 장소'**
  String get placeDraftNameHint;

  /// No description provided for @placeDraftSave.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림 저장'**
  String get placeDraftSave;

  /// No description provided for @placeDraftSaving.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림 저장 중'**
  String get placeDraftSaving;

  /// No description provided for @placeRuleArrival.
  ///
  /// In ko, this message translates to:
  /// **'도착'**
  String get placeRuleArrival;

  /// No description provided for @placeRuleDeparture.
  ///
  /// In ko, this message translates to:
  /// **'이탈'**
  String get placeRuleDeparture;

  /// No description provided for @placeRuleLate.
  ///
  /// In ko, this message translates to:
  /// **'늦음'**
  String get placeRuleLate;

  /// No description provided for @placeRuleLongStay.
  ///
  /// In ko, this message translates to:
  /// **'오래 머무름'**
  String get placeRuleLongStay;

  /// No description provided for @quietHoursNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get quietHoursNone;

  /// No description provided for @quietHoursNight.
  ///
  /// In ko, this message translates to:
  /// **'야간'**
  String get quietHoursNight;

  /// No description provided for @quietHoursClass.
  ///
  /// In ko, this message translates to:
  /// **'수업'**
  String get quietHoursClass;

  /// No description provided for @quietHoursClassOrWork.
  ///
  /// In ko, this message translates to:
  /// **'수업/근무'**
  String get quietHoursClassOrWork;

  /// No description provided for @quietHoursNoneCopy.
  ///
  /// In ko, this message translates to:
  /// **'중요한 도착/이탈 알림을 항상 받을 수 있습니다.'**
  String get quietHoursNoneCopy;

  /// No description provided for @quietHoursNightCopy.
  ///
  /// In ko, this message translates to:
  /// **'22:00-07:00에는 긴급하지 않은 장소 알림을 조용히 처리합니다.'**
  String get quietHoursNightCopy;

  /// No description provided for @quietHoursClassCopy.
  ///
  /// In ko, this message translates to:
  /// **'09:00-17:00에는 반복적인 장소 알림을 줄이는 preset입니다.'**
  String get quietHoursClassCopy;

  /// No description provided for @placeAlertNeedsBackend.
  ///
  /// In ko, this message translates to:
  /// **'Supabase 연결 후 저장할 수 있습니다.'**
  String get placeAlertNeedsBackend;

  /// No description provided for @placeAlertPickTarget.
  ///
  /// In ko, this message translates to:
  /// **'대상 멤버를 선택해 주세요.'**
  String get placeAlertPickTarget;

  /// No description provided for @placeAlertNeedsName.
  ///
  /// In ko, this message translates to:
  /// **'장소 이름을 입력해 주세요.'**
  String get placeAlertNeedsName;

  /// No description provided for @placeAlertNeedsRule.
  ///
  /// In ko, this message translates to:
  /// **'알림 조건을 하나 이상 선택해 주세요.'**
  String get placeAlertNeedsRule;

  /// No description provided for @placeAlertSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림을 저장하지 못했습니다. 대상과 공유 범위를 확인해 주세요.'**
  String get placeAlertSaveFailed;

  /// No description provided for @placeAlertNeedsLiveCircle.
  ///
  /// In ko, this message translates to:
  /// **'실제 서클 위치가 연결되면 저장할 수 있습니다.'**
  String get placeAlertNeedsLiveCircle;

  /// No description provided for @placeAlertReady.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림 준비됨'**
  String get placeAlertReady;

  /// No description provided for @placeAlertUnregistered.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림 반경이 기기에서 해제됨'**
  String get placeAlertUnregistered;

  /// No description provided for @placeAlertSavedPendingDevice.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림은 저장됨 · 기기 반경 등록 대기 중'**
  String get placeAlertSavedPendingDevice;

  /// No description provided for @placeAlertEnter.
  ///
  /// In ko, this message translates to:
  /// **'저장한 장소 반경에 도착했습니다.'**
  String get placeAlertEnter;

  /// No description provided for @placeAlertExit.
  ///
  /// In ko, this message translates to:
  /// **'저장한 장소 반경을 벗어났습니다.'**
  String get placeAlertExit;

  /// No description provided for @placeAlertTransition.
  ///
  /// In ko, this message translates to:
  /// **'저장한 장소 반경 변화가 감지됐습니다.'**
  String get placeAlertTransition;

  /// No description provided for @companionStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get companionStart;

  /// No description provided for @companionFifteenMinutes.
  ///
  /// In ko, this message translates to:
  /// **'15분'**
  String get companionFifteenMinutes;

  /// No description provided for @companionUntilArrival.
  ///
  /// In ko, this message translates to:
  /// **'도착까지'**
  String get companionUntilArrival;

  /// No description provided for @companionCheckIn.
  ///
  /// In ko, this message translates to:
  /// **'도착 확인'**
  String get companionCheckIn;

  /// No description provided for @companionCheckInSending.
  ///
  /// In ko, this message translates to:
  /// **'도착 확인을 보내는 중'**
  String get companionCheckInSending;

  /// No description provided for @companionCheckInFailed.
  ///
  /// In ko, this message translates to:
  /// **'도착 확인을 보내지 못했습니다.'**
  String get companionCheckInFailed;

  /// No description provided for @companionArrivedSent.
  ///
  /// In ko, this message translates to:
  /// **'무사 도착을 보냈어요. 동행 공유는 종료됐습니다.'**
  String get companionArrivedSent;

  /// No description provided for @companionStarted.
  ///
  /// In ko, this message translates to:
  /// **'동행 모드 위치 공유 시작'**
  String get companionStarted;

  /// No description provided for @companionStartedWithSession.
  ///
  /// In ko, this message translates to:
  /// **'동행 모드 위치 공유 시작 · 세션 연결됨'**
  String get companionStartedWithSession;

  /// No description provided for @companionStopped.
  ///
  /// In ko, this message translates to:
  /// **'동행 모드 위치 공유 중지'**
  String get companionStopped;

  /// No description provided for @companionStartFailed.
  ///
  /// In ko, this message translates to:
  /// **'동행 모드를 시작하지 못했습니다.'**
  String get companionStartFailed;

  /// No description provided for @companionEndSyncPending.
  ///
  /// In ko, this message translates to:
  /// **'동행 세션 종료 동기화 대기 중'**
  String get companionEndSyncPending;

  /// No description provided for @checkInSyncPending.
  ///
  /// In ko, this message translates to:
  /// **'안전 확인 기록 동기화 대기 중'**
  String get checkInSyncPending;

  /// No description provided for @uploadSyncTitle.
  ///
  /// In ko, this message translates to:
  /// **'위치 동기화'**
  String get uploadSyncTitle;

  /// No description provided for @uploadFlush.
  ///
  /// In ko, this message translates to:
  /// **'대기 위치 동기화'**
  String get uploadFlush;

  /// No description provided for @uploadNothingPending.
  ///
  /// In ko, this message translates to:
  /// **'업로드할 대기 위치 없음'**
  String get uploadNothingPending;

  /// No description provided for @uploadQueueReady.
  ///
  /// In ko, this message translates to:
  /// **'업로드 큐 준비됨'**
  String get uploadQueueReady;

  /// No description provided for @uploadQueueWaiting.
  ///
  /// In ko, this message translates to:
  /// **'업로드 큐 대기'**
  String get uploadQueueWaiting;

  /// No description provided for @uploadQueueSyncing.
  ///
  /// In ko, this message translates to:
  /// **'업로드 큐 동기화 중'**
  String get uploadQueueSyncing;

  /// No description provided for @uploadQueueRequesting.
  ///
  /// In ko, this message translates to:
  /// **'업로드 큐 동기화 요청 중'**
  String get uploadQueueRequesting;

  /// No description provided for @uploadQueueRequested.
  ///
  /// In ko, this message translates to:
  /// **'업로드 큐 동기화 요청됨'**
  String get uploadQueueRequested;

  /// No description provided for @uploadQueueRequestFailed.
  ///
  /// In ko, this message translates to:
  /// **'업로드 큐 동기화를 요청하지 못했습니다.'**
  String get uploadQueueRequestFailed;

  /// No description provided for @uploadQueueConfigPending.
  ///
  /// In ko, this message translates to:
  /// **'업로드 큐 설정 대기 중'**
  String get uploadQueueConfigPending;

  /// No description provided for @uploadDeviceConfigPending.
  ///
  /// In ko, this message translates to:
  /// **'기기 업로드 큐 설정 대기 중'**
  String get uploadDeviceConfigPending;

  /// No description provided for @uploadDeviceReady.
  ///
  /// In ko, this message translates to:
  /// **'기기 업로드 큐 준비됨'**
  String get uploadDeviceReady;

  /// No description provided for @uploadDeviceDisconnected.
  ///
  /// In ko, this message translates to:
  /// **'기기 업로드 큐 연결 해제'**
  String get uploadDeviceDisconnected;

  /// No description provided for @uploadFailedRetryScheduled.
  ///
  /// In ko, this message translates to:
  /// **'업로드 실패 · 자동 재시도 예약'**
  String get uploadFailedRetryScheduled;

  /// No description provided for @uploadNeedsSignIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인 후 업로드 큐 연결'**
  String get uploadNeedsSignIn;

  /// No description provided for @uploadIosPending.
  ///
  /// In ko, this message translates to:
  /// **'iOS 업로드 큐 구현 대기 중'**
  String get uploadIosPending;

  /// No description provided for @uploadBuildOnly.
  ///
  /// In ko, this message translates to:
  /// **'Android/iOS 빌드에서 업로드 큐를 사용할 수 있습니다.'**
  String get uploadBuildOnly;

  /// No description provided for @deviceLocationBuildOnly.
  ///
  /// In ko, this message translates to:
  /// **'Android/iOS 빌드에서 기기 위치를 사용할 수 있습니다.'**
  String get deviceLocationBuildOnly;

  /// No description provided for @sosBuildOnly.
  ///
  /// In ko, this message translates to:
  /// **'Android/iOS 빌드에서 긴급 위치를 보낼 수 있습니다.'**
  String get sosBuildOnly;

  /// No description provided for @deviceLocationBridgeNote.
  ///
  /// In ko, this message translates to:
  /// **'기기 위치는 Android/iOS 빌드에서 연결됩니다.'**
  String get deviceLocationBridgeNote;

  /// No description provided for @deviceBridgeFailed.
  ///
  /// In ko, this message translates to:
  /// **'기기 위치 브리지를 연결하지 못했습니다.'**
  String get deviceBridgeFailed;

  /// No description provided for @deviceReceiving.
  ///
  /// In ko, this message translates to:
  /// **'내 위치 수신 중'**
  String get deviceReceiving;

  /// No description provided for @deviceSharingRunning.
  ///
  /// In ko, this message translates to:
  /// **'위치 공유 실행 중'**
  String get deviceSharingRunning;

  /// No description provided for @deviceSharingStopped.
  ///
  /// In ko, this message translates to:
  /// **'위치 공유 중지됨'**
  String get deviceSharingStopped;

  /// No description provided for @devicePermissionChecked.
  ///
  /// In ko, this message translates to:
  /// **'위치 권한 상태 확인됨'**
  String get devicePermissionChecked;

  /// No description provided for @deviceLocationServiceAvailable.
  ///
  /// In ko, this message translates to:
  /// **'위치 서비스 사용 가능'**
  String get deviceLocationServiceAvailable;

  /// No description provided for @deviceLocationError.
  ///
  /// In ko, this message translates to:
  /// **'위치 연결 오류'**
  String get deviceLocationError;

  /// No description provided for @sosRequesting.
  ///
  /// In ko, this message translates to:
  /// **'긴급 위치 요청 중'**
  String get sosRequesting;

  /// No description provided for @sosRequestFailed.
  ///
  /// In ko, this message translates to:
  /// **'긴급 위치를 요청하지 못했습니다.'**
  String get sosRequestFailed;

  /// No description provided for @circleLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'서클을 불러오지 못했습니다.'**
  String get circleLoadFailed;

  /// No description provided for @locationLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'위치를 불러오지 못했습니다.'**
  String get locationLoadFailed;

  /// No description provided for @sharingHidden.
  ///
  /// In ko, this message translates to:
  /// **'공유 숨김'**
  String get sharingHidden;

  /// No description provided for @sharingPausedByPolicy.
  ///
  /// In ko, this message translates to:
  /// **'공유 정책에 따라 위치 수집 일시정지'**
  String get sharingPausedByPolicy;

  /// No description provided for @precisionExactLocation.
  ///
  /// In ko, this message translates to:
  /// **'정확 위치'**
  String get precisionExactLocation;

  /// No description provided for @precisionBalancedLocation.
  ///
  /// In ko, this message translates to:
  /// **'균형 위치'**
  String get precisionBalancedLocation;

  /// No description provided for @checkInStatusChanged.
  ///
  /// In ko, this message translates to:
  /// **'상태 변경'**
  String get checkInStatusChanged;

  /// No description provided for @companionMinutesLeft.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 남음'**
  String companionMinutesLeft(int minutes);

  /// No description provided for @uploadPendingCount.
  ///
  /// In ko, this message translates to:
  /// **'대기 {count}건'**
  String uploadPendingCount(int count);

  /// No description provided for @uploadCompleted.
  ///
  /// In ko, this message translates to:
  /// **'위치 업로드 완료 · {count}건'**
  String uploadCompleted(int count);

  /// No description provided for @uploadRetryIn.
  ///
  /// In ko, this message translates to:
  /// **'업로드 재시도 대기 · {seconds}초 후'**
  String uploadRetryIn(int seconds);

  /// No description provided for @placeAlertRegistered.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림 반경 {count}개 기기 등록됨'**
  String placeAlertRegistered(int count);

  /// No description provided for @placeAlertSaved.
  ///
  /// In ko, this message translates to:
  /// **'{name} 저장됨 · 대상 {count}명'**
  String placeAlertSaved(String name, int count);

  /// No description provided for @deviceLocationService.
  ///
  /// In ko, this message translates to:
  /// **'위치 서비스 {status}'**
  String deviceLocationService(String status);

  /// No description provided for @precisionRange.
  ///
  /// In ko, this message translates to:
  /// **'{mode} · 약 {radius} 범위'**
  String precisionRange(String mode, String radius);

  /// No description provided for @precisionRangeStale.
  ///
  /// In ko, this message translates to:
  /// **'마지막 위치 · {mode} · 약 {radius} 범위'**
  String precisionRangeStale(String mode, String radius);

  /// No description provided for @companionConfigNote.
  ///
  /// In ko, this message translates to:
  /// **'최소 {seconds}초 간격 · {mode} 공유 · 상호 동의 후 시작'**
  String companionConfigNote(int seconds, String mode);

  /// No description provided for @checkInEventLine.
  ///
  /// In ko, this message translates to:
  /// **'{name} · {status} · {time}'**
  String checkInEventLine(String name, String status, String time);

  /// No description provided for @quietHoursOff.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get quietHoursOff;

  /// No description provided for @quietHoursOn.
  ///
  /// In ko, this message translates to:
  /// **'설정됨'**
  String get quietHoursOn;

  /// No description provided for @circleCreate.
  ///
  /// In ko, this message translates to:
  /// **'서클 만들기'**
  String get circleCreate;

  /// No description provided for @circleCreateFirst.
  ///
  /// In ko, this message translates to:
  /// **'서클을 먼저 만들어 주세요'**
  String get circleCreateFirst;

  /// No description provided for @circleCreateFirstBody.
  ///
  /// In ko, this message translates to:
  /// **'첫 서클을 만들고 가까운 사람을 초대하세요'**
  String get circleCreateFirstBody;

  /// No description provided for @circleSyncing.
  ///
  /// In ko, this message translates to:
  /// **'서클 동기화 중'**
  String get circleSyncing;

  /// No description provided for @circleManageMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버 관리'**
  String get circleManageMembers;

  /// No description provided for @circleNoMembers.
  ///
  /// In ko, this message translates to:
  /// **'아직 멤버가 없습니다'**
  String get circleNoMembers;

  /// No description provided for @circleNoMembersBody.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크를 만들면 이곳에 수락한 멤버가 표시됩니다.'**
  String get circleNoMembersBody;

  /// No description provided for @inviteLink.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크'**
  String get inviteLink;

  /// No description provided for @inviteCreate.
  ///
  /// In ko, this message translates to:
  /// **'초대하기'**
  String get inviteCreate;

  /// No description provided for @inviteNewLink.
  ///
  /// In ko, this message translates to:
  /// **'새 링크'**
  String get inviteNewLink;

  /// No description provided for @inviteCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get inviteCopy;

  /// No description provided for @inviteJoin.
  ///
  /// In ko, this message translates to:
  /// **'초대 참여'**
  String get inviteJoin;

  /// No description provided for @inviteAccept.
  ///
  /// In ko, this message translates to:
  /// **'참여'**
  String get inviteAccept;

  /// No description provided for @inviteTokenLabel.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크 또는 토큰'**
  String get inviteTokenLabel;

  /// No description provided for @inviteTokenRequired.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크나 토큰을 입력해 주세요.'**
  String get inviteTokenRequired;

  /// No description provided for @inviteCreated.
  ///
  /// In ko, this message translates to:
  /// **'24시간 초대 링크를 만들었습니다.'**
  String get inviteCreated;

  /// No description provided for @inviteCreateFailed.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크를 만들지 못했습니다. 잠시 후 다시 시도해 주세요.'**
  String get inviteCreateFailed;

  /// No description provided for @inviteCopied.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크를 복사했습니다.'**
  String get inviteCopied;

  /// No description provided for @inviteAccepted.
  ///
  /// In ko, this message translates to:
  /// **'초대를 수락했습니다.'**
  String get inviteAccepted;

  /// No description provided for @inviteAcceptFailed.
  ///
  /// In ko, this message translates to:
  /// **'초대를 수락하지 못했습니다. 만료 여부를 확인해 주세요.'**
  String get inviteAcceptFailed;

  /// No description provided for @inviteNeedsBackend.
  ///
  /// In ko, this message translates to:
  /// **'Supabase 연결 후 실제 초대 링크를 만들 수 있습니다.'**
  String get inviteNeedsBackend;

  /// No description provided for @inviteAcceptNeedsBackend.
  ///
  /// In ko, this message translates to:
  /// **'Supabase 연결 후 초대를 수락할 수 있습니다.'**
  String get inviteAcceptNeedsBackend;

  /// No description provided for @inviteSafetyNote.
  ///
  /// In ko, this message translates to:
  /// **'1회 사용 · 수락 전 공유 범위 확인 · 원문 토큰 저장 안 함'**
  String get inviteSafetyNote;

  /// No description provided for @inviteVerifyInviter.
  ///
  /// In ko, this message translates to:
  /// **'초대자 확인'**
  String get inviteVerifyInviter;

  /// No description provided for @inviteVerifyToken.
  ///
  /// In ko, this message translates to:
  /// **'토큰 확인'**
  String get inviteVerifyToken;

  /// No description provided for @inviteConsentLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치 동의'**
  String get inviteConsentLocation;

  /// No description provided for @roleGuardian.
  ///
  /// In ko, this message translates to:
  /// **'보호자'**
  String get roleGuardian;

  /// No description provided for @roleChild.
  ///
  /// In ko, this message translates to:
  /// **'자녀'**
  String get roleChild;

  /// No description provided for @roleFriend.
  ///
  /// In ko, this message translates to:
  /// **'친구'**
  String get roleFriend;

  /// No description provided for @roleCare.
  ///
  /// In ko, this message translates to:
  /// **'케어'**
  String get roleCare;

  /// No description provided for @sharingPreciseShort.
  ///
  /// In ko, this message translates to:
  /// **'정확 공유'**
  String get sharingPreciseShort;

  /// No description provided for @sharingBalancedShort.
  ///
  /// In ko, this message translates to:
  /// **'균형 공유'**
  String get sharingBalancedShort;

  /// No description provided for @companionWaiting.
  ///
  /// In ko, this message translates to:
  /// **'동행 대기'**
  String get companionWaiting;

  /// No description provided for @companionRequest.
  ///
  /// In ko, this message translates to:
  /// **'동행 요청'**
  String get companionRequest;

  /// No description provided for @companionAllow.
  ///
  /// In ko, this message translates to:
  /// **'동행 허용'**
  String get companionAllow;

  /// No description provided for @companionLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get companionLater;

  /// No description provided for @companionRequestDemo.
  ///
  /// In ko, this message translates to:
  /// **'준 · 학교에서 집까지'**
  String get companionRequestDemo;

  /// No description provided for @companionRequestBody.
  ///
  /// In ko, this message translates to:
  /// **'15분 동안 균형 위치와 경로 꼬리만 공유됩니다.'**
  String get companionRequestBody;

  /// No description provided for @checkInSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'안전 확인'**
  String get checkInSectionTitle;

  /// No description provided for @checkInLoading.
  ///
  /// In ko, this message translates to:
  /// **'안전 확인 기록을 불러오는 중입니다.'**
  String get checkInLoading;

  /// No description provided for @checkInLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'안전 확인 기록을 불러오지 못했습니다.'**
  String get checkInLoadFailed;

  /// No description provided for @checkInSyncFailed.
  ///
  /// In ko, this message translates to:
  /// **'안전 확인 동기화 실패'**
  String get checkInSyncFailed;

  /// No description provided for @checkInNoneRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 안전 확인이 없습니다'**
  String get checkInNoneRecent;

  /// No description provided for @checkInEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'동행 중 도착 확인을 보내면 이곳에 무사 도착 기록이 표시됩니다.'**
  String get checkInEmptyBody;

  /// No description provided for @checkInNote.
  ///
  /// In ko, this message translates to:
  /// **'도착 확인은 서클 멤버에게 짧은 안심 신호로 전달됩니다.'**
  String get checkInNote;

  /// No description provided for @checkInTroubleshoot.
  ///
  /// In ko, this message translates to:
  /// **'배터리, 신호, 권한, 기기 상태를 확인해 주세요.'**
  String get checkInTroubleshoot;

  /// No description provided for @checkInDemoScope.
  ///
  /// In ko, this message translates to:
  /// **'가족 전체 · 도착 확인'**
  String get checkInDemoScope;

  /// No description provided for @checkInDemoLongStay.
  ///
  /// In ko, this message translates to:
  /// **'할아버지 · 오래 머무름 확인'**
  String get checkInDemoLongStay;

  /// No description provided for @checkInDemoDetail.
  ///
  /// In ko, this message translates to:
  /// **'동행 공유 종료 · 균형 위치로 알림 · 방금'**
  String get checkInDemoDetail;

  /// No description provided for @placeAlertSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림'**
  String get placeAlertSectionTitle;

  /// No description provided for @placeAlertLoading.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림을 불러오는 중입니다.'**
  String get placeAlertLoading;

  /// No description provided for @placeAlertLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림을 불러오지 못했습니다.'**
  String get placeAlertLoadFailed;

  /// No description provided for @placeAlertNone.
  ///
  /// In ko, this message translates to:
  /// **'저장된 장소 알림이 없습니다'**
  String get placeAlertNone;

  /// No description provided for @placeAlertNoneBody.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림은 서클 멤버와 공유 범위를 정한 뒤 사용할 수 있습니다.'**
  String get placeAlertNoneBody;

  /// No description provided for @placeAlertHint.
  ///
  /// In ko, this message translates to:
  /// **'지도에서 반경을 미리 보고 대상 멤버를 고른 뒤 안전한 알림 규칙으로 추가할 예정입니다.'**
  String get placeAlertHint;

  /// No description provided for @placeAlertUpdating.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림 업데이트'**
  String get placeAlertUpdating;

  /// No description provided for @placeAlertUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림 변경 실패'**
  String get placeAlertUpdateFailed;

  /// No description provided for @placeAlertToggleFailed.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림 상태를 변경하지 못했습니다.'**
  String get placeAlertToggleFailed;

  /// No description provided for @placeAlertPaused.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림을 일시정지했습니다.'**
  String get placeAlertPaused;

  /// No description provided for @placeAlertResumed.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림을 다시 켰습니다.'**
  String get placeAlertResumed;

  /// No description provided for @placeAlertDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림 삭제'**
  String get placeAlertDeleteTitle;

  /// No description provided for @placeAlertDeleted.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림을 삭제했습니다.'**
  String get placeAlertDeleted;

  /// No description provided for @placeAlertDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'장소 알림을 삭제하지 못했습니다.'**
  String get placeAlertDeleteFailed;

  /// No description provided for @quietHoursChange.
  ///
  /// In ko, this message translates to:
  /// **'조용한 시간 변경'**
  String get quietHoursChange;

  /// No description provided for @quietHoursChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'조용한 시간을 변경하지 못했습니다.'**
  String get quietHoursChangeFailed;

  /// No description provided for @placeAlertChangeNeedsBackend.
  ///
  /// In ko, this message translates to:
  /// **'Supabase 연결 후 장소 알림을 변경할 수 있습니다.'**
  String get placeAlertChangeNeedsBackend;

  /// No description provided for @placeAlertDeleteNeedsBackend.
  ///
  /// In ko, this message translates to:
  /// **'Supabase 연결 후 장소 알림을 삭제할 수 있습니다.'**
  String get placeAlertDeleteNeedsBackend;

  /// No description provided for @quietHoursNeedsBackend.
  ///
  /// In ko, this message translates to:
  /// **'Supabase 연결 후 조용한 시간을 변경할 수 있습니다.'**
  String get quietHoursNeedsBackend;

  /// No description provided for @placeAlertServerOnlyUpdate.
  ///
  /// In ko, this message translates to:
  /// **'서버 변경은 완료됐고, 기기 반경 동기화는 대기 중입니다.'**
  String get placeAlertServerOnlyUpdate;

  /// No description provided for @placeAlertServerOnlyDelete.
  ///
  /// In ko, this message translates to:
  /// **'서버 삭제는 완료됐고, 기기 반경 동기화는 대기 중입니다.'**
  String get placeAlertServerOnlyDelete;

  /// No description provided for @deviceSyncPending.
  ///
  /// In ko, this message translates to:
  /// **'기기 동기화 대기'**
  String get deviceSyncPending;

  /// No description provided for @syncLabel.
  ///
  /// In ko, this message translates to:
  /// **'동기화'**
  String get syncLabel;

  /// No description provided for @pauseLabel.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get pauseLabel;

  /// No description provided for @resumeLabel.
  ///
  /// In ko, this message translates to:
  /// **'다시 켜기'**
  String get resumeLabel;

  /// No description provided for @pendingLabel.
  ///
  /// In ko, this message translates to:
  /// **'대기 중'**
  String get pendingLabel;

  /// No description provided for @targetsUnset.
  ///
  /// In ko, this message translates to:
  /// **'대상 미지정'**
  String get targetsUnset;

  /// No description provided for @rulesNone.
  ///
  /// In ko, this message translates to:
  /// **'알림 조건 없음'**
  String get rulesNone;

  /// No description provided for @mutualConsent.
  ///
  /// In ko, this message translates to:
  /// **'상호 동의'**
  String get mutualConsent;

  /// No description provided for @adNotice.
  ///
  /// In ko, this message translates to:
  /// **'광고 안내'**
  String get adNotice;

  /// No description provided for @sampleLabel.
  ///
  /// In ko, this message translates to:
  /// **'예시'**
  String get sampleLabel;

  /// No description provided for @placeHome.
  ///
  /// In ko, this message translates to:
  /// **'집'**
  String get placeHome;

  /// No description provided for @placeSchool.
  ///
  /// In ko, this message translates to:
  /// **'학교'**
  String get placeSchool;

  /// No description provided for @placeClinic.
  ///
  /// In ko, this message translates to:
  /// **'병원'**
  String get placeClinic;

  /// No description provided for @placeAlertDemoRule.
  ///
  /// In ko, this message translates to:
  /// **'평일 08:00-17:00 · 도착/이탈 · 10분 지연'**
  String get placeAlertDemoRule;

  /// No description provided for @targetCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String targetCount(int count);

  /// No description provided for @itemCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String itemCount(int count);

  /// No description provided for @radiusMeters.
  ///
  /// In ko, this message translates to:
  /// **'반경 {meters}m'**
  String radiusMeters(int meters);

  /// No description provided for @quietHoursSummary.
  ///
  /// In ko, this message translates to:
  /// **'조용한 시간 {summary}'**
  String quietHoursSummary(String summary);

  /// No description provided for @quietHoursChanged.
  ///
  /// In ko, this message translates to:
  /// **'조용한 시간을 {summary}(으)로 변경했습니다.'**
  String quietHoursChanged(String summary);

  /// No description provided for @placeAlertDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name} 알림을 삭제할까요? 대상 멤버에게 더 이상 도착/이탈 알림이 가지 않습니다.'**
  String placeAlertDeleteConfirm(String name);

  /// No description provided for @circleSummary.
  ///
  /// In ko, this message translates to:
  /// **'{count}명 · 장소 3개 · 동행 세션 1개 대기'**
  String circleSummary(int count);

  /// No description provided for @checkInDetailLine.
  ///
  /// In ko, this message translates to:
  /// **'{mode} 위치로 알림 · {time}'**
  String checkInDetailLine(String mode, String time);
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'ko':
      return AppL10nKo();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
