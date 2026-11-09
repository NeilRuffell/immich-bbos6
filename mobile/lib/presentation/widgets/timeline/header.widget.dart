import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/models/timeline.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/datetime_extensions.dart';
import 'package:immich_mobile/extensions/theme_extensions.dart';
import 'package:immich_mobile/presentation/widgets/timeline/constants.dart';
import 'package:immich_mobile/providers/haptic_feedback.provider.dart';
import 'package:immich_mobile/providers/infrastructure/readonly_mode.provider.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';

class TimelineHeader extends HookWidget {
  final Bucket bucket;
  final HeaderType header;
  final double height;
  final int assetOffset;
  final bool compact;

  const TimelineHeader({
    super.key,
    required this.bucket,
    required this.header,
    required this.height,
    required this.assetOffset,
    this.compact = false,
  });

  String _formatMonth(DateTime date) {
    final formatter = date.year == DateTime.now().year
        ? DateFormat.MMMM(resolvedDateTimeLocale())
        : DateFormat.yMMMM(resolvedDateTimeLocale());
    return formatter.format(date);
  }

  String _formatDay(DateTime date) {
    final formatter = DateFormat.yMMMEd(resolvedDateTimeLocale());
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (bucket is! TimeBucket || header == HeaderType.none) {
      return const SizedBox.shrink();
    }

    final date = (bucket as TimeBucket).date;
    final isMonthHeader = header == HeaderType.month || header == HeaderType.monthAndDay;
    final isDayHeader = header == HeaderType.day || header == HeaderType.monthAndDay;

    // A combined month/day header is two text lines, not two full-height
    // rows. The date-group selection control retains its 48dp touch target
    // independently on the right, aligned with the lower date line.
    if (compact && header == HeaderType.monthAndDay) {
      return SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.only(
            top: kBbos6TimelineDateTopPadding,
            left: 12.0,
            right: 12.0,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: kBbos6TimelineDateRowHeight),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toBeginningOfSentenceCase(_formatMonth(date)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelLarge?.copyWith(fontSize: 24, height: 1.05),
                      ),
                      const SizedBox(height: kBbos6TimelineCombinedTextGap),
                      Text(
                        toBeginningOfSentenceCase(_formatDay(date)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelLarge?.copyWith(fontSize: 15, height: 1.05),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: _BulkSelectIconButton(bucket: bucket, assetOffset: assetOffset),
              ),
            ],
          ),
        ),
      );
    }

    Widget dateRow(Widget child) => compact
        ? SizedBox(height: kBbos6TimelineDateRowHeight, child: child)
        : child;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: compact ? MainAxisAlignment.spaceBetween : MainAxisAlignment.spaceEvenly,
      children: [
        if (isMonthHeader)
          dateRow(Row(
            children: [
              Text(
                toBeginningOfSentenceCase(_formatMonth(date)),
                style: context.textTheme.labelLarge?.copyWith(fontSize: 24),
              ),
              const Spacer(),
              if (header != HeaderType.monthAndDay) _BulkSelectIconButton(bucket: bucket, assetOffset: assetOffset),
            ],
          )),
        if (isDayHeader)
          dateRow(Row(
            children: [
              Text(
                toBeginningOfSentenceCase(_formatDay(date)),
                style: context.textTheme.labelLarge?.copyWith(fontSize: 15),
              ),
              const Spacer(),
              _BulkSelectIconButton(bucket: bucket, assetOffset: assetOffset),
            ],
          )),
      ],
    );

    final padding = EdgeInsets.only(
      top: isMonthHeader ? (compact ? kBbos6TimelineDateTopPadding : 8.0) : 0.0,
      left: 12.0,
      right: 12.0,
    );

    // The compact header's padding must fit *inside* its reported extent so
    // virtualized row offsets remain aligned with the rendered date header.
    if (compact) {
      return SizedBox(height: height, child: Padding(padding: padding, child: content));
    }

    return Padding(
      padding: padding,
      child: SizedBox(height: height, child: content),
    );
  }
}

class _BulkSelectIconButton extends ConsumerWidget {
  final Bucket bucket;
  final int assetOffset;

  const _BulkSelectIconButton({required this.bucket, required this.assetOffset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<BaseAsset> bucketAssets;
    try {
      bucketAssets = ref.watch(timelineServiceProvider).getAssets(assetOffset, bucket.assetCount);
    } catch (e) {
      bucketAssets = <BaseAsset>[];
    }

    final isReadonlyModeEnabled = ref.watch(readonlyModeProvider);
    final isAllSelected = ref.watch(
      multiSelectProvider.select(
        (state) => bucketAssets.isNotEmpty && bucketAssets.every(state.selectedAssets.contains),
      ),
    );

    return isReadonlyModeEnabled
        ? const SizedBox.shrink()
        : IconButton(
            onPressed: () {
              unawaited(ref.read(multiSelectProvider.notifier).toggleBucketSelection(assetOffset, bucket.assetCount));
              ref.read(hapticFeedbackProvider.notifier).heavyImpact();
            },
            icon: isAllSelected
                ? Icon(Icons.check_circle_rounded, size: 26, color: context.primaryColor)
                : Icon(Icons.check_circle_outline_rounded, size: 26, color: context.colorScheme.onSurfaceSecondary),
          );
  }
}
