
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

  PointOffset.fromOffset(Offset offset) : this(inputValue: offset.dx, outputValue: offset.dy);

  double get inputValue => dx;
  double get outputValue => dy;
  @override
  PointOffset operator +(Offset other) => PointOffset(inputValue: other.dx, outputValue: other.dy);

  Offset get asOffset => Offset(inputValue, outputValue);

  /// Lextr this [PointOffset] to it's pixel scale.
  ///
  /// This takes into account chart orientation [chartSeriesOrientation], which may cause the x and y (input and output)
  /// values to flip (invert) during the lextr.
  ///
  /// todo-01-doc : document all parameters
  ///
  /// Items below summarize the rules for lextr-ing [PointOffset] depending on it's [chartSeriesOrientation]
  /// being [ChartSeriesOrientation.column] or [ChartSeriesOrientation.row]:
  ///
  ///  1. COMBINED Rules for how PointOffset changes after lextr:
  ///     - ChartSeriesOrientation.column: PointOffset(inputValue, outputValue)
  ///       => pixel PointOffset(
  ///                             1.1.1: lextr inputValue to constraints.width,
  ///                             1.2.1: lextr outputValue to HeightSizer.length)
  ///     - ChartSeriesOrientation.row:    PointOffset(inputValue, outputValue)
  ///       => pixel PointOffset(
  ///                             1.2.2: lextr outputValue to WidthSizer.length,
  ///                             1.1.2: lextr inputValue to constraints.height)
  ///   2. Another rephrase of rules in 1.
  ///     - in column orientation:
  ///        - inputPixels  <= lextr inputValue  to constraints.width
  ///        - outputPixels <= lextr outputValue to HeightSizer.length
  ///     - in row orientation, input and output switches:
  ///        - inputPixels  <= lextr outputValue to WidthSizer.length
  ///        - outputPixels <= lextr inputValue  to constraints.height
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
