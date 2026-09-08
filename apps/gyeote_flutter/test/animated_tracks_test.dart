import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeote/src/core/location/location_models.dart';
import 'package:gyeote/src/features/map/map_models.dart';
import 'package:gyeote/src/features/map/widgets/animated_tracks.dart';
import 'package:gyeote/src/theme/gyeote_theme.dart';
import 'package:latlong2/latlong.dart';

MapMemberTrack _track(LatLng point) => MapMemberTrack(
      id: 'a',
      name: '준',
      point: point,
      tone: GyeoteTone.brand,
      recordedAt: DateTime(2026, 1, 1),
      sharingMode: SharingMode.balanced,
    );

void main() {
  /// 현재 그려지고 있는 좌표를 꺼내 본다.
  late LatLng seen;

  Widget host(List<MapMemberTrack> members, {bool reduceMotion = false}) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedMemberTracks(
          members: members,
          builder: (context, animated) {
            seen = animated.single.point;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  testWidgets('markers travel to the new position instead of teleporting',
      (tester) async {
    await tester.pumpWidget(host([_track(const LatLng(37.5, 127.0))]));
    expect(seen.latitude, closeTo(37.5, 1e-9));

    await tester.pumpWidget(host([_track(const LatLng(37.6, 127.0))]));
    await tester.pump(const Duration(milliseconds: 200));

    // 아직 목적지에 닿지 않았어야 한다. 닿았다면 순간이동한 것이다.
    expect(seen.latitude, greaterThan(37.5));
    expect(seen.latitude, lessThan(37.6));

    await tester.pumpAndSettle();
    expect(seen.latitude, closeTo(37.6, 1e-6));
  });

  testWidgets('reduced motion moves the marker immediately', (tester) async {
    await tester.pumpWidget(
      host([_track(const LatLng(37.5, 127.0))], reduceMotion: true),
    );
    await tester.pumpWidget(
      host([_track(const LatLng(37.6, 127.0))], reduceMotion: true),
    );
    await tester.pump();

    // 움직임이 불편해서 끈 사람에게 부드러움을 강요하지 않는다.
    expect(seen.latitude, closeTo(37.6, 1e-9));
  });

  testWidgets('a rebuild without movement does not restart the animation',
      (tester) async {
    await tester.pumpWidget(host([_track(const LatLng(37.5, 127.0))]));
    await tester.pumpWidget(host([_track(const LatLng(37.5, 127.0))]));
    await tester.pump(const Duration(milliseconds: 10));

    expect(seen.latitude, closeTo(37.5, 1e-9));
  });
}
