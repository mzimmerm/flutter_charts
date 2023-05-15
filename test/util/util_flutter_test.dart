import 'package:test/test.dart'; // Dart test package
import 'dart:ui' show Rect, Size;

import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
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

  group('LTransform affmap', () {
    PointOffset pointOffset;
    PointOffset pixelPointOffset;


    /// Column, nonStacked
    test('column, nonStacked', () {

      pointOffset = PointOffset(inputValue: 8.333333333333334, outputValue: 2000.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        withinConstraints: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        sizerHeight: 435.42857142857144,
        sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 0.699404761904762, outputValue: 39.58441558441558,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 263.8961038961039));


      pointOffset = PointOffset(inputValue: 8.333333333333334, outputValue: 1100.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        withinConstraints: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        sizerHeight: 435.42857142857144,
        sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 0.699404761904762, outputValue: 158.33766233766232,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 145.14285714285714));


      pointOffset = PointOffset(inputValue: 8.333333333333334, outputValue: 0.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        withinConstraints: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        sizerHeight: 435.42857142857144,
        sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 0.699404761904762, outputValue: 303.4805194805195,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 0.0));


      pointOffset = PointOffset(inputValue: 41.66666666666667, outputValue: -200.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        withinConstraints: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        sizerHeight: 435.42857142857144,
        sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 3.49702380952381, outputValue: 329.87012987012986,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 26.38961038961039));


      pointOffset = PointOffset(inputValue: 91.66666666666667, outputValue: -250.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.column,
        withinConstraints: BoxContainerConstraints.insideBox(
            size: const Size(8.392857142857144, 435.42857142857144)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        sizerHeight: 435.42857142857144,
        sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 7.693452380952382, outputValue: 336.46753246753246,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(8.392857142857144, 32.98701298701299));
    });

    /// Row, nonStacked, manual
    test('row, nonStacked, manual', () {
      pointOffset = PointOffset(inputValue: 0, outputValue: -1000,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        sizerHeight: 435.42857142857144,
        sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(
          pixelPointOffset, PointOffset(inputValue: 0, outputValue: 309.42857142857144,));
      // todo-00-next : assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(23.441558441558445, 13.642857142857142));
    });

      /// Row, nonStacked
    test('row, nonStacked', () {
      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: -250.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        sizerHeight: 435.42857142857144,
        sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 239.10389610389612,outputValue: 12.505952380952381,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(23.441558441558445, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: -150.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        sizerHeight: 435.42857142857144,
        sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 229.72727272727275,outputValue: 12.505952380952381,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(14.064935064935066, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 25.0,outputValue: 1800.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        sizerHeight: 435.42857142857144,
        sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 46.883116883116884,outputValue: 3.4107142857142856,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(168.7792207792208, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: 0.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        sizerHeight: 435.42857142857144,
        sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 215.66233766233768,outputValue: 1.1369047619047619,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(0.0, 13.642857142857142));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: 2000.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
        chartOrientation: ChartOrientation.row,
        withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 13.642857142857142)),
        inputDataRange: const Interval(0.0, 100.0),
        outputDataRange: const Interval(-1000.0, 2300.0),
        sizerHeight: 435.42857142857144,
        sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 28.12987012987014,outputValue: 1.1369047619047619,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(187.53246753246756, 13.642857142857142));

    });


    /// Row, stacked
    test('row, stacked', () {

      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: -250.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      sizerHeight: 435.42857142857144,
      sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 256.68506493506493,outputValue: 55.52380952380952,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(17.58116883116883, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: -150.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      sizerHeight: 435.42857142857144,
      sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 249.65259740259742,outputValue: 55.52380952380952,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(10.5487012987013, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 91.66666666666667,outputValue: 1800.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      sizerHeight: 435.42857142857144,
      sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 112.51948051948051,outputValue: 55.52380952380952,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(126.5844155844156, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: 2000.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      sizerHeight: 435.42857142857144,
      sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 98.45454545454544,outputValue: 5.0476190476190474,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(140.64935064935065, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: 1100.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      sizerHeight: 435.42857142857144,
      sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 161.74675324675326,outputValue: 5.0476190476190474,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(77.35714285714286, 60.57142857142857));


      pointOffset = PointOffset(inputValue: 8.333333333333334,outputValue: 0.0,);
      pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
      chartOrientation: ChartOrientation.row,
      withinConstraints: BoxContainerConstraints.insideBox(size: const Size(309.42857142857144, 60.57142857142857)),
      inputDataRange: const Interval(0.0, 100.0),
      outputDataRange: const Interval(-1000.0, 3400.0),
      sizerHeight: 435.42857142857144,
      sizerWidth: 309.42857142857144,
      );
      assertOffsetResultsSame(pixelPointOffset, PointOffset(inputValue: 239.10389610389612,outputValue: 5.0476190476190474,));
      assertSizeResultsSame(pixelPointOffset.barPointRectSize, const Size(0.0, 60.57142857142857));

    });

  });


}
