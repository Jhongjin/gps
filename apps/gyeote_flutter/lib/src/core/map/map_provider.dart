import '../location/location_models.dart';

abstract interface class MapProviderController {
  Future<void> focusCoordinate(Coordinate coordinate, {double zoom});

  Future<void> showMember({
    required String memberId,
    required Coordinate coordinate,
    required SharingMode sharingMode,
  });

  Future<void> showRoute({
    required String memberId,
    required List<Coordinate> route,
  });

  Future<void> showPlaceRadius({
    required String placeId,
    required Coordinate center,
    required double radiusM,
  });
}

enum MapProviderKind {
  openStreetMap,
  naver,
  google,
  mapbox,
  prototype,
}
