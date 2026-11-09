import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/domain/services/timeline.service.dart';
import 'package:immich_mobile/extensions/datetime_extensions.dart';
import 'package:immich_mobile/providers/infrastructure/asset_viewer/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/utils/timezone.dart';

class Bbos6TimelineDateFooter extends ConsumerStatefulWidget {
  const Bbos6TimelineDateFooter({required this.selectedIndex, super.key});

  final int? selectedIndex;

  @override
  ConsumerState<Bbos6TimelineDateFooter> createState() => _Bbos6TimelineDateFooterState();
}

class _Bbos6TimelineDateFooterState extends ConsumerState<Bbos6TimelineDateFooter> {
  TimelineService? _service;
  int? _loadedIndex;
  Future<BaseAsset?>? _assetFuture;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(timelineServiceProvider);
    if (!identical(service, _service) || _loadedIndex != widget.selectedIndex) {
      _service = service;
      _loadedIndex = widget.selectedIndex;
      _assetFuture = widget.selectedIndex == null ? null : service.getAssetAsync(widget.selectedIndex!);
    }

    if (_assetFuture == null) {
      return const Text('No image selected', style: TextStyle(color: Colors.white70, fontSize: 14));
    }

    return FutureBuilder<BaseAsset?>(
      key: ValueKey((service, widget.selectedIndex)),
      future: _assetFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Text('Loading date…', style: TextStyle(color: Colors.white70, fontSize: 14));
        }
        final asset = snapshot.data;
        if (asset == null) {
          return const Text('Date unavailable', style: TextStyle(color: Colors.white70, fontSize: 14));
        }
        return _Bbos6AssetDate(asset: asset);
      },
    );
  }
}

class _Bbos6AssetDate extends ConsumerWidget {
  const _Bbos6AssetDate({required this.asset});

  final BaseAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exif = ref.watch(assetExifProvider(asset)).valueOrNull;
    final (dateTime, _) = resolveAssetDateTime(asset, exif);
    final date = DateFormat.yMMMEd(resolvedDateTimeLocale()).format(dateTime);
    final time = dateTime.formatTime(alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          time,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFFB3C1CE), fontSize: 12),
        ),
      ],
    );
  }
}
