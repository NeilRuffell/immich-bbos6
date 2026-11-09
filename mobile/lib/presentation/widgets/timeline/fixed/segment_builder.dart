import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/fixed/segment.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment.model.dart';
import 'package:immich_mobile/presentation/widgets/timeline/segment_builder.dart';

class FixedSegmentBuilder extends SegmentBuilder {
  final double tileHeight;
  final int columnCount;
  final bool compactDateHeaders;

  const FixedSegmentBuilder({
    required super.buckets,
    required this.tileHeight,
    required this.columnCount,
    this.compactDateHeaders = false,
    super.spacing,
    super.groupBy,
  });

  List<Segment> generate() {
    final segments = <Segment>[];
    int firstIndex = 0;
    double startOffset = 0;
    int assetIndex = 0;
    DateTime? previousDate;

    for (int i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];

      final assetCount = bucket.assetCount;
      final numberOfRows = (assetCount / columnCount).ceil();
      final segmentCount = numberOfRows + 1;

      final segmentFirstIndex = firstIndex;
      firstIndex += segmentCount;
      final segmentLastIndex = firstIndex - 1;

      final timelineHeader = switch (groupBy) {
        GroupAssetsBy.month => HeaderType.month,
        GroupAssetsBy.day || GroupAssetsBy.auto =>
          bucket is TimeBucket && bucket.date.month != previousDate?.month ? HeaderType.monthAndDay : HeaderType.day,
        GroupAssetsBy.none => HeaderType.none,
      };
      final headerExtent = SegmentBuilder.headerExtent(timelineHeader, compact: compactDateHeaders);

      final segmentStartOffset = startOffset;
      // Compact headers include the first header-to-row gap in the segment
      // extent, matching the scroll offset used by FixedSegment.gridOffset.
      startOffset += headerExtent +
          (tileHeight * numberOfRows) +
          spacing * (compactDateHeaders ? numberOfRows : numberOfRows - 1);
      final segmentEndOffset = startOffset;

      segments.add(
        FixedSegment(
          firstIndex: segmentFirstIndex,
          lastIndex: segmentLastIndex,
          startOffset: segmentStartOffset,
          endOffset: segmentEndOffset,
          firstAssetIndex: assetIndex,
          bucket: bucket,
          tileHeight: tileHeight,
          columnCount: columnCount,
          headerExtent: headerExtent,
          spacing: spacing,
          header: timelineHeader,
          compactDateHeaders: compactDateHeaders,
        ),
      );

      assetIndex += assetCount;
      if (bucket is TimeBucket) {
        previousDate = bucket.date;
      }
    }
    return segments;
  }
}
