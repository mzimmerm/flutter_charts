import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:test/test.dart'; // Dart test package
import 'dart:ui' show Rect, Size;

import 'package:flutter_charts/src/morphic/container/constraints.dart';
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

  group('LTransform lextr', ()
  {
    PointOffset pointOffset;
    PointOffset pixelPointOffset;

    test('column, nonStacked', () {

      pointOffset = PointOffset(inputValue: 8.333333333333334, outputValue: 2000.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 0.699404761904762, outputValue: 39.58441558441558,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 263.8961038961039));


      pointOffset = PointOffset(inputValue: 8.333333333333334, outputValue: 1100.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 0.699404761904762, outputValue: 158.33766233766232,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 145.14285714285714));


      pointOffset = PointOffset(inputValue: 8.333333333333334, outputValue: 0.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 0.699404761904762, outputValue: 303.4805194805195,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 0.0));


      pointOffset = PointOffset(inputValue: 25.0, outputValue: 1800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 2.098214285714286, outputValue: 65.97402597402595,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 237.5064935064935));


      pointOffset = PointOffset(inputValue: 25.0, outputValue: 1000.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 2.098214285714286, outputValue: 171.53246753246754,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 131.94805194805195));


      pointOffset = PointOffset(inputValue: 25.0, outputValue: 100.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 2.098214285714286, outputValue: 290.28571428571433,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 13.194805194805195));


      pointOffset = PointOffset(inputValue: 41.66666666666667, outputValue: 2200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 3.49702380952381, outputValue: 13.194805194805213,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 290.2857142857143));


      pointOffset = PointOffset(inputValue: 41.66666666666667, outputValue: 1200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 3.49702380952381, outputValue: 145.14285714285717,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 158.33766233766235));


      pointOffset = PointOffset(inputValue: 58.333333333333336, outputValue: 2300.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 4.895833333333334, outputValue: 0.0,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 303.4805194805195));


      pointOffset = PointOffset(inputValue: 58.333333333333336, outputValue: 800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 4.895833333333334, outputValue: 197.92207792207793,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 105.55844155844156));


      pointOffset = PointOffset(inputValue: 58.333333333333336, outputValue: 150.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 4.895833333333334, outputValue: 283.6883116883117,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 19.792207792207794));


      pointOffset = PointOffset(inputValue: 75.0, outputValue: 1700.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 6.294642857142858, outputValue: 79.16883116883116,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 224.31168831168833));


      pointOffset = PointOffset(inputValue: 75.0, outputValue: 700.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 6.294642857142858, outputValue: 211.11688311688312,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 92.36363636363637));


      pointOffset = PointOffset(inputValue: 91.66666666666667, outputValue: 1800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 7.693452380952382, outputValue: 65.97402597402595,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 237.5064935064935));


      pointOffset = PointOffset(inputValue: 91.66666666666667, outputValue: 800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 7.693452380952382, outputValue: 197.92207792207793,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 105.55844155844156));


      pointOffset = PointOffset(inputValue: 8.333333333333334, outputValue: -800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 0.699404761904762, outputValue: 409.0389610389611,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 105.55844155844156));


      pointOffset = PointOffset(inputValue: 25.0, outputValue: -400.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 2.098214285714286, outputValue: 356.2597402597403,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 52.77922077922078));


      pointOffset = PointOffset(inputValue: 41.66666666666667, outputValue: -200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 3.49702380952381, outputValue: 329.87012987012986,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 26.38961038961039));


      pointOffset = PointOffset(inputValue: 41.66666666666667, outputValue: -300.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 3.49702380952381, outputValue: 343.06493506493507,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 39.58441558441559));


      pointOffset = PointOffset(inputValue: 58.333333333333336, outputValue: -400.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 4.895833333333334, outputValue: 356.2597402597403,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 52.77922077922078));


      pointOffset = PointOffset(inputValue: 75.0, outputValue: -100.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 6.294642857142858, outputValue: 316.6753246753247,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 13.194805194805195));


      pointOffset = PointOffset(inputValue: 75.0, outputValue: -200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 6.294642857142858, outputValue: 329.87012987012986,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 26.38961038961039));


      pointOffset = PointOffset(inputValue: 91.66666666666667, outputValue: -150.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 7.693452380952382, outputValue: 323.27272727272725,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 19.792207792207794));


      pointOffset = PointOffset(inputValue: 91.66666666666667, outputValue: -250.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 7.693452380952382, outputValue: 336.46753246753246,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 32.98701298701299));
    });

    test('row, nonStacked', () {
      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: -250.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 239.10389610389612,outputValue: 12.505952380952381,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(23.441558441558445, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: -150.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 229.72727272727275,outputValue: 12.505952380952381,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(14.064935064935066, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 75.0,outputValue: -200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 234.41558441558442,outputValue: 10.232142857142858,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(18.753246753246756, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 75.0,outputValue: -100.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 225.03896103896105,outputValue: 10.232142857142858,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(9.376623376623378, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 58.333333333333336,outputValue: -400.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 253.1688311688312,outputValue: 7.958333333333334,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(37.50649350649351, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 41.66666666666667,outputValue: -300.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 243.79220779220782,outputValue: 5.68452380952381,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(28.12987012987013, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 41.66666666666667,outputValue: -200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 234.41558441558442,outputValue: 5.68452380952381,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(18.753246753246756, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 25.0,outputValue: -400.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 253.1688311688312,outputValue: 3.4107142857142856,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(37.50649350649351, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: -800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 290.6753246753247,outputValue: 1.1369047619047619,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(75.01298701298703, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: 800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 140.64935064935065,outputValue: 12.505952380952381,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(75.01298701298703, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: 1800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 46.883116883116884,outputValue: 12.505952380952381,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(168.7792207792208, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 75.0,outputValue: 700.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 150.02597402597402,outputValue: 10.232142857142858,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(65.63636363636364, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 75.0,outputValue: 1700.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 56.259740259740255,outputValue: 10.232142857142858,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(159.40259740259742, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 58.333333333333336,outputValue: 150.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 201.5974025974026,outputValue: 7.958333333333334,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(14.064935064935066, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 58.333333333333336,outputValue: 800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 140.64935064935065,outputValue: 7.958333333333334,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(75.01298701298703, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 58.333333333333336,outputValue: 2300.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 0.0,outputValue: 7.958333333333334,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(215.66233766233768, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 41.66666666666667,outputValue: 1200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 103.14285714285714,outputValue: 5.68452380952381,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(112.51948051948052, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 41.66666666666667,outputValue: 2200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 9.376623376623343,outputValue: 5.68452380952381,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(206.2857142857143, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 25.0,outputValue: 100.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 206.28571428571428,outputValue: 3.4107142857142856,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(9.376623376623378, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 25.0,outputValue: 1000.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 121.89610389610388,outputValue: 3.4107142857142856,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(93.76623376623378, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 25.0,outputValue: 1800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 46.883116883116884,outputValue: 3.4107142857142856,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(168.7792207792208, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: 0.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 215.66233766233768,outputValue: 1.1369047619047619,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(0.0, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: 1100.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 112.51948051948051,outputValue: 1.1369047619047619,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(103.14285714285715, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: 2000.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        heightToLextr: 435.42857142857144,
        widthToLextr: 309.42857142857144,
        // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 28.12987012987014,outputValue: 1.1369047619047619,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(187.53246753246756, 13.642857142857142));

    });

    test('row, stacked', () {

      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: -250.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 256.68506493506493,outputValue: 55.52380952380952,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(17.58116883116883, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: -150.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 249.65259740259742,outputValue: 55.52380952380952,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(10.5487012987013, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 75.0,outputValue: -200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 253.1688311688312,outputValue: 45.42857142857142,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(14.064935064935066, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 75.0,outputValue: -100.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 246.13636363636365,outputValue: 45.42857142857142,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(7.032467532467533, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 58.333333333333336,outputValue: -400.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 267.23376623376623,outputValue: 35.33333333333333,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(28.12987012987013, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 41.66666666666667,outputValue: -300.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 260.2012987012987,outputValue: 25.238095238095237,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(21.0974025974026, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 41.66666666666667,outputValue: -200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 253.1688311688312,outputValue: 25.238095238095237,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(14.064935064935066, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 25.0,outputValue: -400.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 267.23376623376623,outputValue: 15.14285714285714,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(28.12987012987013, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: -800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 295.3636363636364,outputValue: 5.0476190476190474,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(56.25974025974026, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: 1800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 112.51948051948051,outputValue: 55.52380952380952,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(126.5844155844156, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: 800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 182.84415584415586,outputValue: 55.52380952380952,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(56.25974025974026, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 75.0,outputValue: 1700.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 119.55194805194805,outputValue: 45.42857142857142,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(119.55194805194806, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 75.0,outputValue: 700.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 189.8766233766234,outputValue: 45.42857142857142,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(49.227272727272734, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 58.333333333333336,outputValue: 2300.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 77.35714285714286,outputValue: 35.33333333333333,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(161.74675324675326, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 58.333333333333336,outputValue: 800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 182.84415584415586,outputValue: 35.33333333333333,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(56.25974025974026, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 58.333333333333336,outputValue: 150.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 228.55519480519482,outputValue: 35.33333333333333,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(10.5487012987013, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 41.66666666666667,outputValue: 2200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 84.3896103896104,outputValue: 25.238095238095237,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(154.71428571428572, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 41.66666666666667,outputValue: 1200.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 154.71428571428572,outputValue: 25.238095238095237,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(84.3896103896104, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 25.0,outputValue: 1800.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 112.51948051948051,outputValue: 15.14285714285714,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(126.5844155844156, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 25.0,outputValue: 1000.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 168.7792207792208,outputValue: 15.14285714285714,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(70.32467532467533, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 25.0,outputValue: 100.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 232.07142857142858,outputValue: 15.14285714285714,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(7.032467532467533, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: 2000.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 98.45454545454544,outputValue: 5.0476190476190474,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(140.64935064935065, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: 1100.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 161.74675324675326,outputValue: 5.0476190476190474,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(77.35714285714286, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: 0.0,);
      pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      // todo-00-last-last-done : isLextrUseSizerInsteadOfConstraint: false,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 239.10389610389612,outputValue: 5.0476190476190474,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(0.0, 60.57142857142857));

    });

  });


}
