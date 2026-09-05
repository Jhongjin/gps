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
}
