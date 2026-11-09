import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/fixed/segment_builder.dart';
import 'package:immich_mobile/presentation/widgets/timeline/header.widget.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment_builder.dart';

void main() {
  test('compact timeline date rows use reduced virtualized extents', () {
    final segments = FixedSegmentBuilder(
      buckets: [
        TimeBucket(date: DateTime(2026, 11, 8), assetCount: 2),
        TimeBucket(date: DateTime(2026, 11, 7), assetCount: 4),
      ],
      tileHeight: 100,
      columnCount: 3,
      spacing: 2,
      compactDateHeaders: true,
    ).generate();

    expect(segments.length, 2);
    expect(segments.first.header, HeaderType.monthAndDay);
    expect(segments.first.headerExtent, 72);
    expect(segments.first.gridOffset, 74);
    expect(segments.first.endOffset, 174);
    expect(segments.last.header, HeaderType.day);
    expect(segments.last.headerExtent, 52);
    expect(segments.last.startOffset, 174);
    expect(segments.last.gridOffset, 228);
    expect(segments.last.endOffset, 430);
    expect(segments.last.firstAssetIndex, 2);
  });

  test('stock timeline keeps original date row heights', () {
    final segments = FixedSegmentBuilder(
      buckets: [
        TimeBucket(date: DateTime(2026, 11, 8), assetCount: 2),
        TimeBucket(date: DateTime(2026, 11, 7), assetCount: 4),
      ],
      tileHeight: 100,
      columnCount: 3,
      spacing: 2,
    ).generate();

    expect(segments.first.headerExtent, 128);
    expect(segments.last.headerExtent, 72);
    expect(SegmentBuilder.headerExtent(HeaderType.month), 80);
    expect(SegmentBuilder.headerExtent(HeaderType.month, compact: true), 52);
  });

  testWidgets('compact date rows retain original header and select button widget', (tester) async {
    final segments = FixedSegmentBuilder(
      buckets: [TimeBucket(date: DateTime(2026, 11, 8), assetCount: 2)],
      tileHeight: 100,
      columnCount: 3,
      compactDateHeaders: true,
    ).generate();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final header = segments.first.builder(context, segments.first.firstIndex);
            expect(header, isA<TimelineHeader>());
            final dateHeader = header as TimelineHeader;
            expect(dateHeader.compact, isTrue);
            expect(dateHeader.header, HeaderType.monthAndDay);
            expect(dateHeader.height, 72);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
