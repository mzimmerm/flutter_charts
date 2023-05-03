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

  test('LTransform lextr', () {
    PointOffset pointOffset;
    PointOffset pixelPointOffset;


    pointOffset = PointOffset(inputValue: 8.333333333333334, outputValue: 2000.0,);
    pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.column,
      constraintsOnImmediateOwner: BoxContainerConstraints.insideBox(
          size: const Size(8.392857142857144, 435.42857142857144)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 2300.0),
      heightToLextr: 435.42857142857144,
      widthToLextr: 309.42857142857144,
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
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
      isLextrUseSizerInsteadOfConstraint: false,
    );
    assertOffsetResultsSame(
        pixelPointOffset, PointOffset(inputValue: 7.693452380952382, outputValue: 336.46753246753246,));
    assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 32.98701298701299));
  });
}
