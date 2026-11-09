import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/widgets/common/remote_album_sliver_app_bar.dart';

void main() {
  testWidgets('server album header contracts to its details and grows for longer content', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    late double shortAlbum;
    late double sharedAlbum;
    late double describedAlbum;
    late double longAlbum;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (outerContext) => MediaQuery(
            data: MediaQuery.of(outerContext).copyWith(textScaler: const TextScaler.linear(1.2)),
            child: Builder(
              builder: (context) {
                double height({required String name, String description = '', bool shared = false}) {
                  return calculateCompactRemoteAlbumHeaderHeight(
                    context,
                    name: name,
                    description: description,
                    isShared: shared,
                  );
                }

                shortAlbum = height(name: 'Photos');
                sharedAlbum = height(name: 'Photos', shared: true);
                describedAlbum = height(
                  name: 'Photos',
                  description: 'An album description that remains visible in the compact header.',
                  shared: true,
                );
                longAlbum = height(
                  name: 'A very long server album name that wraps onto several lines in the narrow Q25 viewport',
                  shared: true,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    expect(shortAlbum, lessThan(400));
    expect(sharedAlbum, greaterThan(shortAlbum));
    expect(sharedAlbum, lessThan(300));
    expect(describedAlbum, greaterThan(sharedAlbum));
    expect(longAlbum, greaterThan(sharedAlbum));
    expect(describedAlbum, lessThan(400));
    expect(longAlbum, lessThan(400));
  });
}
