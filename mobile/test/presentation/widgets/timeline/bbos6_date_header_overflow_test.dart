import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/domain/services/timeline.service.dart';
import 'package:immich_mobile/presentation/widgets/timeline/header.widget.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment_builder.dart';
import 'package:immich_mobile/providers/infrastructure/readonly_mode.provider.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';

class _EditableReadonlyMode extends ReadOnlyModeNotifier {
  @override
  bool build() => false;
}

class _EmptyTimelineService implements TimelineService {
  @override
  List<BaseAsset> getAssets(int index, int count) => <BaseAsset>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('compact headers fit their dates and selection button without overflow', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(720, 1280);
    addTearDown(tester.view.reset);

    for (final headerType in [HeaderType.monthAndDay, HeaderType.month, HeaderType.day]) {
      final height = SegmentBuilder.headerExtent(headerType, compact: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            timelineServiceProvider.overrideWithValue(_EmptyTimelineService()),
            readonlyModeProvider.overrideWith(_EditableReadonlyMode.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
                child: TimelineHeader(
                  bucket: TimeBucket(date: DateTime(2026, 9, 29), assetCount: 3),
                  header: headerType,
                  height: height,
                  assetOffset: 0,
                  compact: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: '$headerType must not overflow at 120% text scale');
      expect(find.byType(TimelineHeader), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(tester.getSize(find.byType(IconButton)).height, greaterThanOrEqualTo(48));
    }
  });
}
