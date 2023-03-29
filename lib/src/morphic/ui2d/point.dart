
import 'dart:ui' show Offset;

import '../../util/util_dart.dart' show Interval, ToPixelsExtrapolation1D;
import '../container/constraints.dart';
import '../container/container_layouter_base.dart';

import '../container/chart_support/chart_series_orientation.dart';

class PointOffset extends Offset {
  PointOffset({
    required double inputValue,
    required double outputValue,
}) : super(inputValue, outputValue);

  double get inputValue => dx;
  double get outputValue => dy;

  /// Lextr this point to it's pixel scale.
  ///
  /// This takes into account chart orientation [chartSeriesOrientation], which may cause the x and y (input and output)
  /// values to flip (invert) during the lextr.
  ///
  /// todo-01-doc : document all parameters
  ///
  /// If the [chartSeriesOrientation]
  /// 1. Rules for lextr-ing of inputValue and outputValue values of PointOffset
  ///   1.1 inputValue: PointOffset component is lextr-ed to constraints width (or height)
  ///     1.1.1 ChartSeriesOrientation.column: inputValue lextr-ed to constraints.width
  ///     1.1.2 ChartSeriesOrientation.row:    inputValue lextr-ed to constraints.height
  ///   1.2 outputValue:   PointOffset component is lextr-ed, to the available WidthSizer.length (or HeightSizer.length)
  ///     1.2.1 ChartSeriesOrientation.column: inputValue lextr-ed to <0, HeightSizer.length>  (dataRange on  dependent axis)
  ///     1.2.2 ChartSeriesOrientation.row:    inputValue lextr-ed to <0, WidthSizer.length>   (dataRange on  dependent axis - SAME) todo-00-last : is this true at all?
  ///  2. COMBINED Rules for how PointOffset changes after lextr:
  ///     - ChartSeriesOrientation.column: PointOffset(inputValue, outputValue)
  ///       => pixel PointOffset(
  ///                             1.1.1: lextr inputValue to constraints.width,
  ///                             1.2.1: lextr outputValue to HeightSizer.length)
  ///     - ChartSeriesOrientation.row:    PointOffset(inputValue, outputValue)
  ///       => pixel PointOffset(
  ///                             1.2.2: lextr outputValue to WidthSizer.length,
  ///                             1.1.2: lextr inputValue to constraints.height)
  ///   3. Another rephrase of 2.
  ///     - in column orientation:
  ///        - pixelsInputValue  <= lextr inputValue  to constraints.width
  ///        - pixelsOutputValue <= lextr outputValue to HeightSizer.length
  ///     - in row orientation, input and output switches:
  ///        - pixelsInputValue  <= lextr outputValue to WidthSizer.length
  ///        - pixelsOutputValue <= lextr inputValue  to constraints.height
  ///
  PointOffset lextrInContextOf({
    required ChartSeriesOrientation  chartSeriesOrientation,
    required BoxContainerConstraints constraintsOnImmediateOwner,
    required Interval                inputDataRange,
    required Interval                outputDataRange,
    required double                  heightToLextr,
    required double                  widthToLextr,
    // required HeightSizerLayouter     heightSizerLayouter,
    // required WidthSizerLayouter      widthSizerLayouter,
  }) {
    ChartSeriesOrientation orientation = chartSeriesOrientation;
    BoxContainerConstraints constraints = constraintsOnImmediateOwner;

    double inputPixels = 0.0;
    double outputPixels = 0.0;

    switch (orientation) {
      case ChartSeriesOrientation.column:
        // 1.1.1:
        inputPixels = ToPixelsExtrapolation1D(
          fromValuesMin: inputDataRange.min,
          fromValuesMax: inputDataRange.max,
          toPixelsMin: 0.0,
          toPixelsMax: constraints.width,
          doInvertToDomain: !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.horizontal),
        ).apply(inputValue);
        // 1.2.1:
        outputPixels = ToPixelsExtrapolation1D(
          fromValuesMin: outputDataRange.min,
          fromValuesMax: outputDataRange.max,
          toPixelsMin: 0.0,
          toPixelsMax: heightToLextr,
          doInvertToDomain: !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.vertical),
        ).apply(outputValue);
        break;
      case ChartSeriesOrientation.row:
        // 1.2.2:
        inputPixels = ToPixelsExtrapolation1D(
          fromValuesMin: outputDataRange.min,
          fromValuesMax: outputDataRange.max,
          toPixelsMin: 0.0,
          toPixelsMax: widthToLextr,
          doInvertToDomain: !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.horizontal),
        ).apply(outputValue);
        // 1.1.2:
        outputPixels = ToPixelsExtrapolation1D(
          fromValuesMin: outputDataRange.min,
          fromValuesMax: outputDataRange.max,
          toPixelsMin: 0.0,
          toPixelsMax: constraints.height,
          doInvertToDomain: !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.vertical),
        ).apply(inputValue);
        break;
    }

    return PointOffset(
      inputValue: inputPixels,
      outputValue: outputPixels,
    );
  }

}

/*

    container_base.LayoutAxis chartPointsMainLayoutAxis = chartSeriesOrientation.mainLayoutAxis;

    switch(chartPointsMainLayoutAxis) {
      case container_base.LayoutAxis.horizontal:
        // Assuming Row, X is constraints.width, Y is extrapolating value to constraints.height
        labelInfosGenerator = chartViewMaker.yLabelsGenerator;
        pixelFromX = 0;
        pixelToX = constraints.width;
        pixelFromY = labelInfosGenerator.lextrValueToPixels(
          value: pointFrom.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.height,
        );
        pixelToY = labelInfosGenerator.lextrValueToPixels(
          value: pointTo.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.height,
        );
        break;
      case container_base.LayoutAxis.vertical:
      // Assuming Row, Y is constraints.height, X is extrapolating value to constraints.width
        labelInfosGenerator = chartViewMaker.xLabelsGenerator;
        pixelFromY = 0;
        pixelToY = constraints.height;
        pixelFromX = labelInfosGenerator.lextrValueToPixels(
          value: pointFrom.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.width,
        );
        pixelToX = labelInfosGenerator.lextrValueToPixels(
          value: pointTo.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.width,
        );
        break;
    }

 */