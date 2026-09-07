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
  String get privacyCircleFamily => 'Family circle';

  @override
  String get privacyCircleFriends => 'Friends circle';

  @override
  String get demoNameGuardian => 'Mira';

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

  @override
  String get mapOpenCircle => 'Circle';

  @override
  String get mapOnboardTitle => 'Start your first circle';

  @override
  String get mapOnboardBody =>
      'Once someone accepts an invite, their shared location appears on the map.';

  @override
  String get placeDraftTitle => 'Place radius';

  @override
  String get placeDraftSubtitle => 'Save arrival and departure rules';

  @override
  String get placeDraftNameLabel => 'Place name';

  @override
  String get placeDraftNameHint => 'New place';

  @override
  String get placeDraftSave => 'Save place alert';

  @override
  String get placeDraftSaving => 'Saving place alert';

  @override
  String get placeRuleArrival => 'Arrival';

  @override
  String get placeRuleDeparture => 'Departure';

  @override
  String get placeRuleLate => 'Late';

  @override
  String get placeRuleLongStay => 'Long stay';

  @override
  String get quietHoursNone => 'None';

  @override
  String get quietHoursNight => 'Night';

  @override
  String get quietHoursClass => 'Class';

  @override
  String get quietHoursClassOrWork => 'Class or work';

  @override
  String get quietHoursNoneCopy =>
      'Important arrival and departure alerts always come through.';

  @override
  String get quietHoursNightCopy =>
      'Between 22:00 and 07:00, non-urgent place alerts stay quiet.';

  @override
  String get quietHoursClassCopy =>
      'Between 09:00 and 17:00, repeated place alerts are reduced.';

  @override
  String get placeAlertNeedsBackend => 'Connect Supabase to save.';

  @override
  String get placeAlertPickTarget => 'Pick at least one member.';

  @override
  String get placeAlertNeedsName => 'Enter a place name.';

  @override
  String get placeAlertNeedsRule => 'Pick at least one alert condition.';

  @override
  String get placeAlertSaveFailed =>
      'Could not save the place alert. Check the targets and sharing scope.';

  @override
  String get placeAlertNeedsLiveCircle =>
      'You can save this once your circle reports real locations.';

  @override
  String get placeAlertReady => 'Place alert ready';

  @override
  String get placeAlertUnregistered => 'Place radius removed from this device';

  @override
  String get placeAlertSavedPendingDevice =>
      'Place alert saved · waiting for the device radius';

  @override
  String get placeAlertEnter => 'Arrived inside a saved place radius.';

  @override
  String get placeAlertExit => 'Left a saved place radius.';

  @override
  String get placeAlertTransition => 'A saved place radius changed.';

  @override
  String get companionStart => 'Start';

  @override
  String get companionFifteenMinutes => '15 min';

  @override
  String get companionUntilArrival => 'Until arrival';

  @override
  String get companionCheckIn => 'Confirm arrival';

  @override
  String get companionCheckInSending => 'Sending your arrival check-in';

  @override
  String get companionCheckInFailed => 'Could not send the arrival check-in.';

  @override
  String get companionArrivedSent =>
      'Arrival sent. Companion sharing has ended.';

  @override
  String get companionStarted => 'Companion sharing started';

  @override
  String get companionStartedWithSession =>
      'Companion sharing started · session connected';

  @override
  String get companionStopped => 'Companion sharing stopped';

  @override
  String get companionStartFailed => 'Could not start companion mode.';

  @override
  String get companionEndSyncPending => 'Waiting to sync the session ending';

  @override
  String get checkInSyncPending => 'Waiting to sync check-in history';

  @override
  String get uploadSyncTitle => 'Location sync';

  @override
  String get uploadFlush => 'Sync pending locations';

  @override
  String get uploadNothingPending => 'No pending locations to upload';

  @override
  String get uploadQueueReady => 'Upload queue ready';

  @override
  String get uploadQueueWaiting => 'Upload queue waiting';

  @override
  String get uploadQueueSyncing => 'Syncing the upload queue';

  @override
  String get uploadQueueRequesting => 'Requesting an upload sync';

  @override
  String get uploadQueueRequested => 'Upload sync requested';

  @override
  String get uploadQueueRequestFailed => 'Could not request an upload sync.';

  @override
  String get uploadQueueConfigPending => 'Waiting for upload queue setup';

  @override
  String get uploadDeviceConfigPending =>
      'Waiting for device upload queue setup';

  @override
  String get uploadDeviceReady => 'Device upload queue ready';

  @override
  String get uploadDeviceDisconnected => 'Device upload queue disconnected';

  @override
  String get uploadFailedRetryScheduled => 'Upload failed · retry scheduled';

  @override
  String get uploadNeedsSignIn => 'Sign in to connect the upload queue';

  @override
  String get uploadIosPending => 'iOS upload queue is not implemented yet';

  @override
  String get uploadBuildOnly =>
      'The upload queue works in the Android and iOS builds.';

  @override
  String get deviceLocationBuildOnly =>
      'Device location works in the Android and iOS builds.';

  @override
  String get sosBuildOnly =>
      'Emergency location works in the Android and iOS builds.';

  @override
  String get deviceLocationBridgeNote =>
      'Device location connects in the Android and iOS builds.';

  @override
  String get deviceBridgeFailed =>
      'Could not connect the device location bridge.';

  @override
  String get deviceReceiving => 'Receiving your location';

  @override
  String get deviceSharingRunning => 'Location sharing is running';

  @override
  String get deviceSharingStopped => 'Location sharing stopped';

  @override
  String get devicePermissionChecked => 'Permission status checked';

  @override
  String get deviceLocationServiceAvailable => 'Location service available';

  @override
  String get deviceLocationError => 'Location connection error';

  @override
  String get sosRequesting => 'Requesting emergency location';

  @override
  String get sosRequestFailed => 'Could not request the emergency location.';

  @override
  String get circleLoadFailed => 'Could not load your circle.';

  @override
  String get locationLoadFailed => 'Could not load locations.';

  @override
  String get sharingHidden => 'Hidden';

  @override
  String get sharingPausedByPolicy => 'Collection paused by the sharing policy';

  @override
  String get precisionExactLocation => 'Exact location';

  @override
  String get precisionBalancedLocation => 'Balanced location';

  @override
  String get checkInStatusChanged => 'Status changed';

  @override
  String companionMinutesLeft(int minutes) {
    return '$minutes min left';
  }

  @override
  String uploadPendingCount(int count) {
    return '$count pending';
  }

  @override
  String uploadCompleted(int count) {
    return 'Uploaded $count locations';
  }

  @override
  String uploadRetryIn(int seconds) {
    return 'Retrying upload in ${seconds}s';
  }

  @override
  String placeAlertRegistered(int count) {
    return '$count place radii registered on this device';
  }

  @override
  String placeAlertSaved(String name, int count) {
    return '$name saved · $count targets';
  }

  @override
  String deviceLocationService(String status) {
    return 'Location service $status';
  }

  @override
  String precisionRange(String mode, String radius) {
    return '$mode · about $radius';
  }

  @override
  String precisionRangeStale(String mode, String radius) {
    return 'Last location · $mode · about $radius';
  }

  @override
  String companionConfigNote(int seconds, String mode) {
    return 'Every ${seconds}s at most · $mode sharing · starts after both agree';
  }

  @override
  String checkInEventLine(String name, String status, String time) {
    return '$name · $status · $time';
  }

  @override
  String get quietHoursOff => 'Off';

  @override
  String get quietHoursOn => 'On';

  @override
  String get circleCreate => 'Create a circle';

  @override
  String get circleCreateFirst => 'Create a circle first';

  @override
  String get circleCreateFirstBody =>
      'Create your first circle and invite the people close to you';

  @override
  String get circleSyncing => 'Syncing your circle';

  @override
  String get circleManageMembers => 'Manage members';

  @override
  String get circleNoMembers => 'No members yet';

  @override
  String get circleNoMembersBody =>
      'Create an invite link and everyone who accepts shows up here.';

  @override
  String get inviteLink => 'Invite link';

  @override
  String get inviteCreate => 'Invite';

  @override
  String get inviteNewLink => 'New link';

  @override
  String get inviteCopy => 'Copy';

  @override
  String get inviteJoin => 'Join with an invite';

  @override
  String get inviteAccept => 'Join';

  @override
  String get inviteTokenLabel => 'Invite link or token';

  @override
  String get inviteTokenRequired => 'Enter an invite link or token.';

  @override
  String get inviteCreated => 'Created a 24-hour invite link.';

  @override
  String get inviteCreateFailed =>
      'Could not create an invite link. Please try again in a moment.';

  @override
  String get inviteCopied => 'Invite link copied.';

  @override
  String get inviteAccepted => 'Invite accepted.';

  @override
  String get inviteAcceptFailed =>
      'Could not accept the invite. Check whether it has expired.';

  @override
  String get inviteNeedsBackend =>
      'Connect Supabase to create real invite links.';

  @override
  String get inviteAcceptNeedsBackend => 'Connect Supabase to accept invites.';

  @override
  String get inviteSafetyNote =>
      'Single use · sharing scope shown before accepting · raw token is never stored';

  @override
  String get inviteVerifyInviter => 'Inviter verified';

  @override
  String get inviteVerifyToken => 'Token verified';

  @override
  String get inviteConsentLocation => 'Location consent';

  @override
  String get roleGuardian => 'Guardian';

  @override
  String get roleChild => 'Child';

  @override
  String get roleFriend => 'Friend';

  @override
  String get roleCare => 'Care';

  @override
  String get sharingPreciseShort => 'Exact sharing';

  @override
  String get sharingBalancedShort => 'Balanced sharing';

  @override
  String get companionWaiting => 'Companion pending';

  @override
  String get companionRequest => 'Companion request';

  @override
  String get companionAllow => 'Allow';

  @override
  String get companionLater => 'Later';

  @override
  String get companionRequestDemo => 'Jun · school to home';

  @override
  String get companionRequestBody =>
      'For 15 minutes, only balanced location and a route tail are shared.';

  @override
  String get checkInSectionTitle => 'Check-ins';

  @override
  String get checkInLoading => 'Loading check-in history.';

  @override
  String get checkInLoadFailed => 'Could not load check-in history.';

  @override
  String get checkInSyncFailed => 'Check-in sync failed';

  @override
  String get checkInNoneRecent => 'No recent check-ins';

  @override
  String get checkInEmptyBody =>
      'Send an arrival check-in during a companion session and it shows up here.';

  @override
  String get checkInNote =>
      'An arrival check-in reaches your circle as a short all-clear.';

  @override
  String get checkInTroubleshoot =>
      'Check battery, signal, permissions, and device state.';

  @override
  String get checkInDemoScope => 'Whole family · arrival check-in';

  @override
  String get checkInDemoLongStay => 'Grandpa · long-stay check';

  @override
  String get checkInDemoDetail =>
      'Companion sharing ended · notified with balanced location · just now';

  @override
  String get placeAlertSectionTitle => 'Place alerts';

  @override
  String get placeAlertLoading => 'Loading place alerts.';

  @override
  String get placeAlertLoadFailed => 'Could not load place alerts.';

  @override
  String get placeAlertNone => 'No saved place alerts';

  @override
  String get placeAlertNoneBody =>
      'Place alerts become available once you set circle members and a sharing scope.';

  @override
  String get placeAlertHint =>
      'Preview the radius on the map, pick the members, then add a safe alert rule.';

  @override
  String get placeAlertUpdating => 'Updating place alert';

  @override
  String get placeAlertUpdateFailed => 'Place alert update failed';

  @override
  String get placeAlertToggleFailed => 'Could not change the place alert.';

  @override
  String get placeAlertPaused => 'Place alert paused.';

  @override
  String get placeAlertResumed => 'Place alert turned back on.';

  @override
  String get placeAlertDeleteTitle => 'Delete place alert';

  @override
  String get placeAlertDeleted => 'Place alert deleted.';

  @override
  String get placeAlertDeleteFailed => 'Could not delete the place alert.';

  @override
  String get quietHoursChange => 'Change quiet hours';

  @override
  String get quietHoursChangeFailed => 'Could not change quiet hours.';

  @override
  String get placeAlertChangeNeedsBackend =>
      'Connect Supabase to change place alerts.';

  @override
  String get placeAlertDeleteNeedsBackend =>
      'Connect Supabase to delete place alerts.';

  @override
  String get quietHoursNeedsBackend =>
      'Connect Supabase to change quiet hours.';

  @override
  String get placeAlertServerOnlyUpdate =>
      'Saved on the server; the device radius is still syncing.';

  @override
  String get placeAlertServerOnlyDelete =>
      'Deleted on the server; the device radius is still syncing.';

  @override
  String get deviceSyncPending => 'Device sync pending';

  @override
  String get syncLabel => 'Sync';

  @override
  String get pauseLabel => 'Paused';

  @override
  String get resumeLabel => 'Turn back on';

  @override
  String get targetsUnset => 'No targets';

  @override
  String get rulesNone => 'No alert rules';

  @override
  String get mutualConsent => 'Mutual consent';

  @override
  String get adNotice => 'Ad notice';

  @override
  String get sampleLabel => 'Sample';

  @override
  String get placeHome => 'Home';

  @override
  String get placeSchool => 'School';

  @override
  String get placeClinic => 'Clinic';

  @override
  String get placeAlertDemoRule =>
      'Weekdays 08:00-17:00 · arrival and departure · 10 min delay';

  @override
  String targetCount(int count) {
    return '$count people';
  }

  @override
  String itemCount(int count) {
    return '$count';
  }

  @override
  String radiusMeters(int meters) {
    return '$meters m radius';
  }

  @override
  String quietHoursSummary(String summary) {
    return 'Quiet hours $summary';
  }

  @override
  String quietHoursChanged(String summary) {
    return 'Quiet hours changed to $summary.';
  }

  @override
  String placeAlertDeleteConfirm(String name) {
    return 'Delete the $name alert? Its members stop receiving arrival and departure alerts.';
  }

  @override
  String circleSummary(int count) {
    return '$count members · 3 places · 1 companion session pending';
  }

  @override
  String checkInDetailLine(String mode, String time) {
    return 'Notified with $mode location · $time';
  }

  @override
  String a11yMemberRow(String name, String status) {
    return '$name, $status. Double tap for details';
  }

  @override
  String a11yBatteryLevel(int percent) {
    return 'Battery $percent percent';
  }

  @override
  String get a11yStaleLocation => 'Location is out of date';

  @override
  String a11yAttentionBadge(int count) {
    return '$count members need a check';
  }

  @override
  String get onboardWelcomeTitle => 'Close people, only as much as you choose';

  @override
  String get onboardWelcomeBody =>
      'Gyeote shares location only between people who invited each other and agreed. There is no way to watch someone quietly.';

  @override
  String get onboardConsentTitle => 'You always see who can see you';

  @override
  String get onboardConsentBody =>
      'Set a sharing precision per circle and pause it whenever you want. Every view of your location is recorded.';

  @override
  String get onboardPermissionTitle => 'Why location permission';

  @override
  String get onboardPermissionBody =>
      'Drawing each other on the map needs your device location. The system asks next, and the answer is yours.';

  @override
  String get onboardNext => 'Next';

  @override
  String get onboardStart => 'Get started';

  @override
  String get onboardSkip => 'Skip';

  @override
  String onboardStepOf(int current, int total) {
    return '$current of $total';
  }

  @override
  String get primerContinue => 'Continue';

  @override
  String get primerLater => 'Later';

  @override
  String get primerWhenInUseTitle => 'Location is needed while you use the app';

  @override
  String get primerWhenInUseBody =>
      'Companion mode draws your position on the map. The system asks on the next screen.';

  @override
  String get primerAlwaysTitle => 'Place alerts need background location';

  @override
  String get primerAlwaysBody =>
      'Checking arrivals and departures while the app is closed needs this. Place alerts do not work without it.';

  @override
  String get primerPromise =>
      'Precise location is never used for ads, and you can stop sharing at any time.';

  @override
  String get checkInOnTheWay => 'On my way';

  @override
  String get checkInImOk => 'I\'m OK';

  @override
  String get checkInCallMe => 'Call me';

  @override
  String get quickReplyTitle => 'Say it in one tap';

  @override
  String quickReplySent(String label) {
    return 'Sent: $label';
  }

  @override
  String get quickReplyFailed =>
      'Could not send. Please try again in a moment.';

  @override
  String get quickReplyNeedsCircle => 'Join a circle to send these.';

  @override
  String get meetupSectionTitle => 'Meetups';

  @override
  String get meetupCreate => 'Plan a meetup';

  @override
  String get meetupNone => 'No meetup planned';

  @override
  String get meetupNoneBody =>
      'Set a place and a time, and everyone\'s time to arrive shows up here.';

  @override
  String get meetupNameLabel => 'Meetup name';

  @override
  String get meetupNameHint => 'Dinner';

  @override
  String get meetupPlaceHint =>
      'The point shown on the map becomes the meeting place.';

  @override
  String get meetupIn30 => 'In 30 min';

  @override
  String get meetupIn1h => 'In 1 hour';

  @override
  String get meetupIn2h => 'In 2 hours';

  @override
  String get meetupSave => 'Create meetup';

  @override
  String get meetupSaving => 'Creating the meetup';

  @override
  String get meetupCreated => 'Meetup created.';

  @override
  String get meetupCreateFailed => 'Could not create the meetup.';

  @override
  String get meetupNeedsCircle => 'Join a circle to plan a meetup.';

  @override
  String get meetupGoing => 'Going';

  @override
  String get meetupMaybe => 'Maybe';

  @override
  String get meetupDeclined => 'Can\'t make it';

  @override
  String get meetupRespondFailed => 'Could not save your response.';

  @override
  String get meetupEnd => 'End meetup';

  @override
  String get meetupEndFailed => 'Could not end the meetup.';

  @override
  String meetupGoingCount(int going, int total) {
    return '$going of $total going';
  }

  @override
  String meetupStartsIn(String time) {
    return 'in $time';
  }

  @override
  String meetupStartedAgo(String time) {
    return '$time ago';
  }

  @override
  String meetupAutoEnds(int minutes) {
    return 'Disappears on its own $minutes min after the meeting time';
  }

  @override
  String get meetupDestination => 'Meeting place';

  @override
  String get movementStopped => 'Not moving';

  @override
  String get movementWalking => 'Walking';

  @override
  String get movementRiding => 'On the move';

  @override
  String get movementDriving => 'Moving fast';

  @override
  String etaMinutesTo(String place, int minutes) {
    return 'About $minutes min to $place';
  }

  @override
  String etaLeaving(String place) {
    return 'Moving away from $place';
  }

  @override
  String etaDistanceTo(String place, String distance) {
    return '$distance to $place';
  }

  @override
  String etaNearby(String place) {
    return 'Near $place';
  }

  @override
  String etaMineMinutes(int minutes) {
    return 'You: about $minutes min away';
  }

  @override
  String get etaEstimateNote => 'Estimated from straight-line distance';

  @override
  String get privatePlacesTitle => 'Private places';

  @override
  String get privatePlacesBody =>
      'Inside a place you add here, only its centre point is shared instead of your exact position. The list stays on this device and is never sent to the server.';

  @override
  String get privatePlacesEmpty => 'Nothing added yet';

  @override
  String get privatePlacesAddHere => 'Add where I am now';

  @override
  String get privatePlacesAdding => 'Checking location';

  @override
  String get privatePlacesNameLabel => 'What should we call this place?';

  @override
  String get privatePlacesNameHint => 'Home';

  @override
  String get privatePlacesRadius => 'Area to hide';

  @override
  String get privatePlacesSave => 'Add';

  @override
  String get privatePlacesRemove => 'Remove';

  @override
  String get privatePlacesSaved =>
      'Your exact position is no longer shared inside this place.';

  @override
  String get privatePlacesRemoved => 'Place removed.';

  @override
  String get privatePlacesNoFix => 'Could not read your current location.';

  @override
  String privatePlacesFull(int max) {
    return 'You can add up to $max places.';
  }

  @override
  String privatePlacesRadiusValue(int meters) {
    return '$meters m radius';
  }

  @override
  String get privatePlacesUnnamed => 'Unnamed place';

  @override
  String get viewerLogSheetTitle => 'Who looked at my location';

  @override
  String get viewerLogSheetBody =>
      'Times a circle member opened your location in the last 30 days. Your own views are not counted.';

  @override
  String get viewerLogEmpty => 'Nobody has looked yet';

  @override
  String get viewerLogLoadFailed => 'Could not load the viewing record.';

  @override
  String get viewerLogUnknownViewer => 'Unnamed member';

  @override
  String get viewerLogNeedsBackend =>
      'Viewing records start once you join a circle.';

  @override
  String viewerLogEntryDetail(String precision) {
    return 'Seen at $precision precision';
  }

  @override
  String get viewerLogSeeAll => 'See all';

  @override
  String get playbackTitle => 'Replay today\'s movement';

  @override
  String get playbackOpen => 'Replay';

  @override
  String get playbackSubtitle =>
      'Only stored positions are joined up. No precision is invented.';

  @override
  String get playbackLoading => 'Loading the route';

  @override
  String get playbackEmpty => 'Not enough recorded to replay';

  @override
  String get playbackEmptyHint =>
      'Replay needs at least two positions stored while sharing was on.';

  @override
  String get playbackLoadFailed => 'Could not load the route.';

  @override
  String get playbackNeedsBackend =>
      'Past movement becomes available once you join a circle.';

  @override
  String get playbackPlay => 'Play';

  @override
  String get playbackPause => 'Pause';

  @override
  String get playbackGapNotice => 'Nothing was recorded during this stretch';

  @override
  String playbackTravelled(String distance) {
    return '$distance travelled';
  }

  @override
  String playbackWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String get playbackViewerLogNote =>
      'Replaying someone else\'s movement appears in their viewing record.';
}
