import 'package:test/test.dart'; // Dart test package
import 'package:flutter_charts/flutter_charts.dart';
import 'dart:ui' as ui show Rect;

void main() {
  test('outerRectangle - test creating outer rectangle from a list of rectangles', () {
    ui.Rect rect1 = const ui.Rect.fromLTRB(1.0, 2.0, 4.0, 6.0);
    ui.Rect rect2 = const ui.Rect.fromLTRB(10.0, 20.0, 40.0, 50.0);
    expect(
      outerRectangle([rect1, rect2]),
      const ui.Rect.fromLTRB(1.0, 2.0, 39.0, 48.0),
    );
  });
}