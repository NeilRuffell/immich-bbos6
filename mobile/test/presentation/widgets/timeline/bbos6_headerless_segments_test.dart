import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/fixed/segment_builder.dart';
import 'package:immich_mobile/presentation/widgets/timeline/header.widget.dart';

void main() {
  testWidgets('BBOS6 layout omits all date headers and bucket-selection controls', (tester) async {
    final buckets = [
      TimeBucket(date: DateTime(2026, 11, 8), assetCount: 2),
      TimeBucket(date: DateTime(2026, 11, 7), assetCount: 4),
    ];

    final segments = FixedSegmentBuilder(
      buckets: buckets,
      columnCount: 3,
      tileHeight: 100,
      spacing: 4,
      groupBy: GroupAssetsBy.day,
      omitHeaders: true,
    ).generate();

    expect(segments.length, 2);
    expect(segments.every((segment) => !segment.hasHeader && segment.header == HeaderType.none), isTrue);
    expect(segments[0].firstIndex, 0);
    expect(segments[0].lastIndex, 0);
    expect(segments[0].gridIndex, 0);
    expect(segments[0].gridOffset, 0);
    expect(segments[0].endOffset, 104);
    expect(segments[1].firstIndex, 1);
    expect(segments[1].lastIndex, 2);
    expect(segments[1].gridIndex, 1);
    expect(segments[1].gridOffset, 104);
    expect(segments[1].firstAssetIndex, 2);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final firstRow = segments[0].builder(context, 0);
            final nextBucketRow = segments[1].builder(context, 1);
            expect(firstRow, isNot(isA<TimelineHeader>()));
            expect(nextBucketRow, isNot(isA<TimelineHeader>()));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(find.byType(TimelineHeader), findsNothing);
  });

  test('stock layout continues rendering date headers', () {
    final segments = FixedSegmentBuilder(
      buckets: [TimeBucket(date: DateTime(2026, 11, 8), assetCount: 2)],
      columnCount: 3,
      tileHeight: 100,
      spacing: 4,
      groupBy: GroupAssetsBy.day,
    ).generate();

    expect(segments.single.hasHeader, isTrue);
    expect(segments.single.header, HeaderType.monthAndDay);
    expect(segments.single.gridIndex, 1);
    expect(segments.single.firstIndex, 0);
    expect(segments.single.lastIndex, 1);
  });

  test('empty gallery buckets produce no blank header rows', () {
    final segments = FixedSegmentBuilder(
      buckets: [
        TimeBucket(date: DateTime(2026, 11, 8), assetCount: 0),
        TimeBucket(date: DateTime(2026, 11, 7), assetCount: 1),
      ],
      columnCount: 3,
      tileHeight: 100,
      groupBy: GroupAssetsBy.day,
      omitHeaders: true,
    ).generate();

    expect(segments.length, 1);
    expect(segments.single.firstIndex, 0);
    expect(segments.single.firstAssetIndex, 0);
  });
}
