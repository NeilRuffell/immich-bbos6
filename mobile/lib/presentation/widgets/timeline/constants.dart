import 'dart:ui';

const double kTimelineHeaderExtent = 80.0;

// Compact BBOS6 date headers: include the 48dp selection touch target and
// explicit spacing in the exact extent reserved by the virtualized timeline.
const double kBbos6TimelineDateRowHeight = 48.0;
const double kBbos6TimelineDateTopPadding = 4.0;
const double kBbos6TimelineSingleDateHeaderHeight = kBbos6TimelineDateRowHeight + kBbos6TimelineDateTopPadding;
// Month and day labels share a compact text stack; the 48dp selection
// target sits independently beside them instead of forcing two 48dp rows.
const double kBbos6TimelineCombinedDateHeaderHeight = 72.0;
const double kBbos6TimelineCombinedTextGap = 2.0;
const Size kTimelineFixedTileExtent = Size.square(256);
const double kTimelineSpacing = 2.0;
const int kTimelineColumnCount = 3;

const double kScrubberThumbHeight = 48.0;
const Duration kTimelineScrubberFadeInDuration = Duration(milliseconds: 300);
const Duration kTimelineScrubberFadeOutDuration = Duration(milliseconds: 800);

const Size kThumbnailResolution = Size.square(320);
