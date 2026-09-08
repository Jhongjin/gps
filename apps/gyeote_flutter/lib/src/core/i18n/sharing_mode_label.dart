import '../../../l10n/app_localizations.dart';
import '../location/location_models.dart';

/// 공유 정확도의 로케일 표현.
///
/// enum 은 코어에 있고 문구는 화면마다 필요하다. 각 화면이 자기 switch 를
/// 들고 있으면 정확도를 하나 더하는 날 어느 화면 하나가 조용히 빠진다.
String sharingModeLabel(AppL10n l10n, SharingMode mode) {
  return switch (mode) {
    SharingMode.precise => l10n.sharingModePrecise,
    SharingMode.balanced => l10n.sharingModeBalanced,
    SharingMode.area => l10n.sharingModeArea,
    SharingMode.hidden => l10n.sharingModeHidden,
    SharingMode.sosOnly => l10n.sharingModeSosOnly,
  };
}
