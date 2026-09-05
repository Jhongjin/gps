// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gyeote';

  @override
  String get navMap => 'Map';

  @override
  String get navCircle => 'Circle';

  @override
  String get navHistory => 'History';

  @override
  String get navPrivacy => 'Safety';

  @override
  String get signOut => 'Sign out';

  @override
  String get mapDefaultCircleName => 'Our circle';

  @override
  String get mapLayersTooltip => 'Map style';

  @override
  String get mapInvite => 'Invite';

  @override
  String get mapMeShort => 'Me';

  @override
  String mapSharingCount(int count) {
    return '$count sharing location';
  }

  @override
  String mapAttentionCount(int count) {
    return '$count need a check';
  }

  @override
  String get mapConnecting => 'Connecting to your circle';

  @override
  String get mapNoCircle => 'No circle connected yet';

  @override
  String get mapDemoNotice =>
      'Showing sample locations until your circle reports in';

  @override
  String get sosLabel => 'SOS';

  @override
  String get sosButtonSemantics => 'Emergency share. Press and hold to start';

  @override
  String get sosArming => 'Emergency share ready';

  @override
  String get sosSecondsRemaining => 'sec until sent';

  @override
  String sosAudience(String audience) {
    return 'Sending your exact location and battery\nto $audience';
  }

  @override
  String get sosNoAds => 'No ads appear on this screen.';

  @override
  String get sosCancel => 'Cancel';

  @override
  String get sosSendNow => 'Send now';

  @override
  String get memberBattery => 'Battery';

  @override
  String get memberAccuracy => 'Accuracy';

  @override
  String get memberUpdated => 'Updated';

  @override
  String get memberCall => 'Call';

  @override
  String get memberNudge => 'Nudge';

  @override
  String get memberDirections => 'Directions';

  @override
  String memberPrecisionTitle(String name) {
    return 'What $name shares with you';
  }

  @override
  String memberPrecisionConsent(String name) {
    return 'Changing this needs $name\'s consent. Sending a request notifies their device.';
  }

  @override
  String get viewerLogTitle => 'Who viewed this location';

  @override
  String get viewerLogSubtitle => 'The full view log lives in the Safety tab.';

  @override
  String get viewerLogOpen => 'View log';

  @override
  String get precisionPrecise => 'Exact';

  @override
  String get precisionBalanced => 'Balanced';

  @override
  String get precisionArea => 'Neighborhood';

  @override
  String get precisionHidden => 'Hidden';

  @override
  String get relativeJustNow => 'just now';

  @override
  String relativeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String relativeHours(int hours) {
    return '$hours hr';
  }

  @override
  String relativeDays(int days) {
    return '$days d';
  }

  @override
  String get valueUnknown => '—';

  @override
  String get adSlotSemantics => 'Sponsored area';

  @override
  String get adSlotTitle => 'Sponsored';

  @override
  String get adSlotBody => 'Ads are kept separate from your location data';

  @override
  String get adSlotBadge => 'Test';

  @override
  String get memberFallbackName => 'Member';

  @override
  String get sharingModePrecise => 'Exact';

  @override
  String get sharingModeBalanced => 'Balanced';

  @override
  String get sharingModeArea => 'Neighborhood';

  @override
  String get sharingModeHidden => 'Hidden';

  @override
  String get sharingModeSosOnly => 'Emergency only';

  @override
  String statusSharing(String mode) {
    return 'Sharing $mode';
  }

  @override
  String get statusWaitingUpdate => 'Waiting for a location update';

  @override
  String get statusLastKnownOnly => 'Showing last known location';

  @override
  String get statusLowBattery => 'Low battery may slow updates';

  @override
  String metaOldLocation(String time) {
    return 'Old location · $time';
  }

  @override
  String metaLastLocation(String time) {
    return 'Last location · $time';
  }

  @override
  String metaBattery(int percent) {
    return 'Battery $percent%';
  }

  @override
  String metaAccuracy(String distance) {
    return 'Accuracy $distance';
  }

  @override
  String get metaJustUpdated => 'Updated just now';

  @override
  String get noteVeryStale =>
      'This may not be the current location. It will update when the connection returns.';

  @override
  String get noteStale =>
      'Battery, signal, or permission state can delay this.';

  @override
  String get noteLowBattery => 'Low battery may slow updates.';

  @override
  String get agoJustNow => 'just now';

  @override
  String agoMinutes(int minutes) {
    return '$minutes min ago';
  }

  @override
  String agoHours(int hours) {
    return '$hours hr ago';
  }

  @override
  String agoDays(int days) {
    return '$days d ago';
  }

  @override
  String get demoNameChild => 'Jun';

  @override
  String get demoNameFriend => 'Hana';

  @override
  String get demoNameElder => 'Grandpa';

  @override
  String get deviceArrivedStatus => 'Arrived safely · just confirmed';

  @override
  String get deviceArrivedMeta =>
      'Companion sharing ended · notified with balanced location';

  @override
  String get historyTitle => 'Today';

  @override
  String get historySubtitle =>
      'Place alerts, view log, companion sessions, check-ins';

  @override
  String get historySyncing => 'Syncing activity';

  @override
  String get historyLoadFailed => 'Could not load activity.';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyFilterCheckIn => 'Check-ins';

  @override
  String get historyFilterPlace => 'Places';

  @override
  String get historyFilterCompanion => 'Companion';

  @override
  String get historyFilterData => 'Data';

  @override
  String get historyFilterEmpty => 'Nothing under this filter';

  @override
  String get historyFilterEmptyHint =>
      'Pick another filter to see today\'s activity again.';

  @override
  String historyCheckInCount(int count) {
    return '$count check-ins';
  }

  @override
  String get historyNoAds => 'No ads';

  @override
  String get historySafetyLoading => 'Loading check-ins and companion endings.';

  @override
  String get historySafetyEmpty => 'No check-ins today';

  @override
  String get historySafetyEmptyHint =>
      'Send an arrival check-in during a companion session and it lands here.';

  @override
  String get historySafetyNoRecent => 'No recent arrival check-ins yet.';

  @override
  String get checkInSafeArrived => 'Arrived safely';

  @override
  String get checkInPending => 'Waiting for a check-in';

  @override
  String get checkInNeedsCheck => 'Needs a check';

  @override
  String get checkInWeakSignal => 'Signal is weak right now';

  @override
  String companionEndedNote(String mode) {
    return 'Companion sharing ended · notified with $mode location';
  }

  @override
  String get demoEventPlaceArrival => 'Jun arrived at school';

  @override
  String get demoEventPlaceArrivalDetail => '4 min earlier than expected';

  @override
  String get demoEventViewed => 'Mira checked your location';

  @override
  String get demoEventViewedDetail => 'Family circle · balanced location';

  @override
  String get demoEventCompanion => 'Grandpa started a walk';

  @override
  String get demoEventCompanionDetail =>
      '15 min companion session · mutual consent';

  @override
  String get demoEventCheckIn => 'Jun arrived safely';

  @override
  String get demoEventCheckInDetail =>
      'Companion sharing ended · notified with balanced location';

  @override
  String get demoEventDataRequest => 'Location history deletion request';

  @override
  String get demoEventDataRequestDetail => 'Pending';

  @override
  String get historyTypeViewed => 'Viewed';

  @override
  String get authTagline =>
      'Share your location with the people close to you, only as much as you want.';

  @override
  String get authBadgeConsent => 'Consent-based sharing';

  @override
  String get authBadgeViewerLog => 'View log';

  @override
  String get authBadgeNoAdTargeting => 'No precise-location ads';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authSignUpCta => 'Create an account';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authDisplayName => 'Name or nickname';

  @override
  String get authEmailRequired => 'Enter your email.';

  @override
  String get authPasswordTooShort => 'Use at least 6 characters.';

  @override
  String get authGenericError =>
      'Something went wrong. Please try again in a moment.';

  @override
  String get authVerifyEmailSent =>
      'We sent a confirmation email. Confirm it, then sign in again.';

  @override
  String get authConsentNote =>
      'Location is shared only inside circles you joined and companion sessions you both agreed to.';

  @override
  String get authPrivacyNote =>
      'Precise location is never used for ads, and you can stop sharing at any time.';

  @override
  String get privacyTitle => 'Safety settings';

  @override
  String get privacySubtitle => 'Sharing, view log, ads, deletion requests';

  @override
  String get privacySharingScopeTitle => 'Sharing scope';

  @override
  String get privacySharingScopeBody =>
      'Default location sharing for the map and companion mode';

  @override
  String get privacyPauseSharing => 'Pause sharing';

  @override
  String get privacyPausedNotice => 'Location sharing is paused for one hour.';

  @override
  String get privacyPauseFailed => 'Could not save the sharing pause.';

  @override
  String get privacyPauseNeedsBackend => 'Connect Supabase to pause sharing.';

  @override
  String get privacyModePreciseTitle => 'Exact location';

  @override
  String get privacyModePreciseBody =>
      'The map radius follows your sharing precision.';

  @override
  String get privacyModeBalancedTitle => 'Balanced sharing';

  @override
  String get privacyModeBalancedBody =>
      'Balances freshness and battery for everyday sharing.';

  @override
  String get privacyModeApprox => 'Approximate';

  @override
  String get privacyModeApproxBody =>
      'Approximate locations show as a radius circle.';

  @override
  String get privacyModeAdjusted => 'Shows an adjusted position';

  @override
  String get privacyModeHidesExact => 'Hides exact coordinates';

  @override
  String get privacyBatteryTitle => 'Battery mode';

  @override
  String get privacyBatteryBody =>
      'When the battery is low, updates slow down and key alerts take priority.';

  @override
  String get privacyBatteryRealtime => 'Live';

  @override
  String get privacyBatterySaver => 'Saver';

  @override
  String get privacyBatteryRealtimeNote => 'Live first';

  @override
  String get privacyBatteryBalancedNote => 'Balanced';

  @override
  String get privacyBatterySaverNote => 'Battery first';

  @override
  String get privacyBatteryFast => 'Fast updates';

  @override
  String get privacyBatterySlow => 'Slow updates';

  @override
  String get privacyInterval15to30 => '15-30 s';

  @override
  String get privacyInterval30to90 => '30-90 s';

  @override
  String get privacyInterval2to5 => '2-5 min';

  @override
  String get privacyCompanionBatteryNote =>
      'Companion mode updates faster and uses more battery.';

  @override
  String get privacyPermissionTitle => 'Permission status';

  @override
  String get privacyPermissionRefresh => 'Refresh permission status';

  @override
  String get privacyPermissionFailed =>
      'Could not read the device permission status.';

  @override
  String get privacyPermissionBuildOnly =>
      'Device permissions are read in the Android and iOS builds.';

  @override
  String get privacyPermissionBuildOnlyShort =>
      'Real permissions are read on Android and iOS.';

  @override
  String get privacyPermissionLocation => 'Location permission';

  @override
  String get privacyPermissionBackground => 'Background location';

  @override
  String get privacyPermissionNotifications => 'Notifications';

  @override
  String get privacyPermissionDeviceBuild => 'Device build';

  @override
  String get privacyPermissionGranted => 'Granted';

  @override
  String get privacyPermissionWhileInUse => 'While using the app';

  @override
  String get privacyPermissionUnknown => 'Not checked';

  @override
  String get privacyPermissionWhenNeeded => 'When needed';

  @override
  String get privacyPermissionEducationNote =>
      'Explain the permission before location sharing starts.';

  @override
  String get privacyPermissionStagedNote =>
      'Requested step by step, from the features you turn on.';

  @override
  String get privacyNotificationsBody => 'Arrival check-ins, place alerts, SOS';

  @override
  String get privacyNotificationsTitle => 'Safety notifications';

  @override
  String get privacyViewerLogTitle => 'Recent views';

  @override
  String get privacyViewerLogLabel => 'View log';

  @override
  String get privacyViewerLogNote => 'Visible to you';

  @override
  String get privacyViewerFamilyBalanced => 'Family circle · balanced location';

  @override
  String get privacyViewerFriendsArea => 'Friends circle · neighborhood only';

  @override
  String get privacyCircleFamily => 'Family circle';

  @override
  String get privacyCircleFriends => 'Friends circle';

  @override
  String get demoNameGuardian => 'Mira';

  @override
  String get privacyViewer12MinAgo => '12 min ago';

  @override
  String get privacyViewerYesterday => 'Yesterday';

  @override
  String get privacyAdsTitle => 'Ads and data';

  @override
  String get privacyAdsPersonalized => 'Personalized ads';

  @override
  String get privacyAdsPersonalizedBody =>
      'Without consent, only non-personalized ads are used';

  @override
  String get privacyAdsSensitiveBlock => 'Block sensitive categories';

  @override
  String get privacyAdsSensitiveBody =>
      'Protects family, location, and emergency contexts';

  @override
  String get privacyAdsNoPreciseTargeting => 'No precise-location ad targeting';

  @override
  String get privacyAdsLoadFailed => 'Could not load ad settings.';

  @override
  String get privacyAdsSaveFailed => 'Could not save ad settings.';

  @override
  String get privacyAdsSaved => 'Ad settings saved.';

  @override
  String get privacyAdsNeedsBackend => 'Connect Supabase to save ad settings.';

  @override
  String get privacyDataTitle => 'My data';

  @override
  String get privacyDataExport => 'Export';

  @override
  String get privacyDataDelete => 'Delete history';

  @override
  String get privacyDataExportSent => 'Export request sent.';

  @override
  String get privacyDataDeleteSent => 'Deletion request sent.';

  @override
  String get privacyDataRequestFailed => 'Could not send the data request.';

  @override
  String get privacyDataNeedsBackend =>
      'Connect Supabase to send data requests.';

  @override
  String get privacyDataLocationHistory => 'Location history';

  @override
  String get privacyDataCompanionRoutes => 'Companion routes';

  @override
  String get privacyDataCompanionRoutesBody =>
      'Companion sessions · route tails';

  @override
  String get privacyRetention30Days => '30 days';

  @override
  String get privacyRetention24Hours => '24 hours';

  @override
  String get privacyRetentionAutoDelete =>
      'Deleted automatically when it expires';

  @override
  String get privacyRetentionSummaryOnly =>
      'Only a summary is kept after the session ends';

  @override
  String get privacyRecommended => 'Recommended';

  @override
  String get privacySaving => 'Saving';

  @override
  String get privacyRequesting => 'Sending';

  @override
  String get privacyPending => 'Pending';

  @override
  String get privacyCompanionMode => 'Companion mode';

  @override
  String get privacyCompanionConsentNote => 'Starts after both people agree';

  @override
  String get privacyCompanion15MinLeft => '15 min left';
}
