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
