import 'package:test/test.dart'; // Dart test package
import 'package:flutter_charts/src/util/util_flutter.dart';
import 'dart:ui' as ui show Rect;

void main() {
  test('outerRectangle - test creating outer rectangle from a list of rectangles', () {
    ui.Rect rect1 = const ui.Rect.fromLTRB(1.0, 2.0, 4.0, 6.0);
    ui.Rect rect2 = const ui.Rect.fromLTRB(10.0, 20.0, 40.0, 50.0);
    expect(
      boundingRectOfRects([rect1, rect2]),
      const ui.Rect.fromLTRB(1.0, 2.0, 40.0, 50.0),
    );
  });
}
