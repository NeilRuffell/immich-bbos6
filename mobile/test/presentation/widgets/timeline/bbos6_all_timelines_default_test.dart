import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/timeline/timeline.widget.dart';

void main() {
  test('Timeline image galleries use the BBOS6 helper by default', () {
    expect(const Timeline().bbosGallery, isTrue);
    expect(const Timeline(bbosGallery: false).bbosGallery, isFalse);
  });
}
