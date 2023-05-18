import 'package:test/test.dart'; // Dart test package
import 'dart:ui' show Rect, Size;

import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
// import 'package:flutter_charts/src/morphic/container/constraints.dart';
import 'package:flutter_charts/src/util/util_flutter.dart';
import 'package:flutter_charts/src/util/util_dart.dart';
import 'package:flutter_charts/src/morphic/ui2d/point.dart';

void main() {
  test('outerRectangle - test creating outer rectangle from a list of rectangles', () {
    Rect rect1 = const Rect.fromLTRB(1.0, 2.0, 4.0, 6.0);
    Rect rect2 = const Rect.fromLTRB(10.0, 20.0, 40.0, 50.0);
    expect(
      boundingRect([rect1, rect2]),
      const Rect.fromLTRB(1.0, 2.0, 40.0, 50.0),
    );
  });

  group('PointOffset affmap - invokes ToPixelsAffineMap1D', () {
    PointOffset pointOffset;
    PointOffset pixelPointOffset;

    group('row, manual affmap of nonStacked, full range', () {
      var chartOrientation = ChartOrientation.row;
      var fromTransposing2DValueRange = FromTransposing2DValueRange(
        chartOrientation: chartOrientation,
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
      );
      // todo-00-done-KEEP : var withinConstraints = BoxContainerConstraints.insideBox(size: const Size(300, 20));
      var to2DPixelRange = To2DPixelRange(
        width: 300,
        height: 400,
      );

      test('row, manual affmap of nonStacked, map outputMin from full output range', () {
        pointOffset = PointOffset(inputValue: 0, outputValue: -1000, /*isLayouterPositioningMeInCrossDirection: false,*/);
        pixelPointOffset = pointOffset.affmapBetweenRanges(
          chartOrientation: chartOrientation,
          fromTransposing2DValueRange: fromTransposing2DValueRange,
          to2DPixelRange: to2DPixelRange,
        );
        assertOffsetResultsSame(
            pixelPointOffset, PointOffset(inputValue: 0, outputValue: 400,));
        assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(300 * (1000.0 / (1000 + 2300)), 400));
      });

      test('row, manual affmap of nonStacked, map outputMax from full output range', () {
        pointOffset = PointOffset(inputValue: 0, outputValue: 2300, /*isLayouterPositioningMeInCrossDirection: false,*/);
        pixelPointOffset = pointOffset.affmapBetweenRanges(
          chartOrientation: chartOrientation,
          fromTransposing2DValueRange: fromTransposing2DValueRange,
          to2DPixelRange: to2DPixelRange,
        );
        assertOffsetResultsSame(
            pixelPointOffset, PointOffset(inputValue: 300, outputValue: 400,));
        assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(300 * (2300.0 / (1000 + 2300)), 400));
      });

      test('row, manual affmap of nonStacked, map inputMin from full input range', () {
        pointOffset = PointOffset(inputValue: 0, outputValue: 0, /*isLayouterPositioningMeInCrossDirection: false,*/);
        pixelPointOffset = pointOffset.affmapBetweenRanges(
          chartOrientation: chartOrientation,
          fromTransposing2DValueRange: fromTransposing2DValueRange,
          to2DPixelRange: to2DPixelRange,
        );
        assertOffsetResultsSame(
            pixelPointOffset, PointOffset(inputValue: 300 * (1000.0 / (1000 + 2300)), outputValue: 400,));
        assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(0, 400));
      });

      test('row, manual affmap of nonStacked, map inputMax from full input range', () {
        pointOffset = PointOffset(inputValue: 100, outputValue: 0, /*isLayouterPositioningMeInCrossDirection: false,*/);
        pixelPointOffset = pointOffset.affmapBetweenRanges(
          chartOrientation: chartOrientation,
          fromTransposing2DValueRange: fromTransposing2DValueRange,
          to2DPixelRange: to2DPixelRange,
        );
        assertOffsetResultsSame(
            pixelPointOffset, PointOffset(inputValue: 300 * (1000.0 / (1000 + 2300)), outputValue: 0,));
        assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(0, 400));
      });
    });

    group('row, manual affmap of nonStacked, only positive range', () {
      var chartOrientation = ChartOrientation.row;
      var fromTransposing2DValueRange = FromTransposing2DValueRange(
        chartOrientation: chartOrientation,
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
      );
      // todo-00-done-KEEP : var withinConstraints = BoxContainerConstraints.insideBox(size: const Size(300, 20));
      var to2DPixelRange = To2DPixelRange(
        width: 300,
        height: 400,
      );

      test('row, manual affmap of nonStacked, map outputMin from only positive output range', () {
        // todo-0100-next : change test
        pointOffset = PointOffset(inputValue: 0, outputValue: -1000, /*isLayouterPositioningMeInCrossDirection: false,*/);
        pixelPointOffset = pointOffset.affmapBetweenRanges(
          chartOrientation: chartOrientation,
          fromTransposing2DValueRange: fromTransposing2DValueRange,
          to2DPixelRange: to2DPixelRange,
        );
        assertOffsetResultsSame(
            pixelPointOffset, PointOffset(inputValue: 0, outputValue: 400,));
        assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(300 * (1000.0 / (1000 + 2300)), 400));
      });

      test('row, manual affmap of nonStacked, map outputMax from only positive output range', () {
        // todo-0100-next : change test
        pointOffset = PointOffset(inputValue: 0, outputValue: 2300, /*isLayouterPositioningMeInCrossDirection: false,*/);
        pixelPointOffset = pointOffset.affmapBetweenRanges(
          chartOrientation: chartOrientation,
          fromTransposing2DValueRange: fromTransposing2DValueRange,
          to2DPixelRange: to2DPixelRange,
        );
        assertOffsetResultsSame(
            pixelPointOffset, PointOffset(inputValue: 300, outputValue: 400,));
        assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(300 * (2300.0 / (1000 + 2300)), 400));
      });

      test('row, manual affmap of nonStacked, map inputMin from only positive input range', () {
        // todo-0100-next : change test
        pointOffset = PointOffset(inputValue: 0, outputValue: 0, /*isLayouterPositioningMeInCrossDirection: false,*/);
        pixelPointOffset = pointOffset.affmapBetweenRanges(
          chartOrientation: chartOrientation,
          fromTransposing2DValueRange: fromTransposing2DValueRange,
          to2DPixelRange: to2DPixelRange,
        );
        assertOffsetResultsSame(
            pixelPointOffset, PointOffset(inputValue: 300 * (1000.0 / (1000 + 2300)), outputValue: 400,));
        assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(0, 400));
      });

      test('row, manual affmap of nonStacked, map inputMax from only positive input range', () {
        // todo-0100-next : change test
        pointOffset = PointOffset(inputValue: 100, outputValue: 0, /*isLayouterPositioningMeInCrossDirection: false,*/);
        pixelPointOffset = pointOffset.affmapBetweenRanges(
          chartOrientation: chartOrientation,
          fromTransposing2DValueRange: fromTransposing2DValueRange,
          to2DPixelRange: to2DPixelRange,
        );
        assertOffsetResultsSame(
            pixelPointOffset, PointOffset(inputValue: 300 * (1000.0 / (1000 + 2300)), outputValue: 0,));
        assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(0, 400));
      });
    });

  });


}
