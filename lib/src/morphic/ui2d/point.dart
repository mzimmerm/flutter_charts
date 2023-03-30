
import 'dart:ui' show Offset;

import '../../util/util_dart.dart' show Interval, ToPixelsExtrapolation1D;
import '../container/constraints.dart';
import '../container/container_layouter_base.dart';

import '../container/chart_support/chart_series_orientation.dart';

class PointOffset extends Offset {
  const PointOffset({
    required double inputValue,
    required double outputValue,
    this.isLextrIntoValueSignPortion = true,
  }) : super(inputValue, outputValue);

  PointOffset.fromOffset(Offset offset) : this(inputValue: offset.dx, outputValue: offset.dy);

  final bool isLextrIntoValueSignPortion;

  double get inputValue => dx;
  double get outputValue => dy;
  @override
  PointOffset operator +(Offset other) => PointOffset(
        inputValue: inputValue + other.dx,
        outputValue: outputValue + other.dy,
      );
  @override
  PointOffset operator -(Offset other) => PointOffset(
    inputValue: inputValue - other.dx,
    outputValue: outputValue - other.dy,
  );

  Offset get asOffset => Offset(inputValue, outputValue);

  // todo-00-last-last-progress : Add a method that creates new ranges from same sign portions for
  //         inputDataRange: chartViewMaker.xLabelsGenerator.dataRange,
  //       outputDataRange: chartViewMaker.yLabelsGenerator.dataRange,
  //      - first, return full range, and incorporate to existing code
  //      - next, return only same-sign-portion of ranges for fromPointOffset, toPointOffset.


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
  }) {
    ChartSeriesOrientation orientation = chartSeriesOrientation;
    BoxContainerConstraints constraints = constraintsOnImmediateOwner;

    double inputPixels = 0.0;
    double outputPixels = 0.0;

    Interval fromValuesRange;
    Interval toPixelsRange;
    bool doInvertDomain;
    double lextredValue;

    switch (orientation) {
      case ChartSeriesOrientation.column:
        // 1.1.1:
        fromValuesRange = inputDataRange;
        toPixelsRange   = Interval(0.0, constraints.width);
        doInvertDomain  = !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.horizontal);
        lextredValue    = inputValue;
        inputPixels = ToPixelsExtrapolation1D(
          fromValuesMin: fromValuesRange.min,
          fromValuesMax: fromValuesRange.max,
          toPixelsMin: toPixelsRange.min,
          toPixelsMax: toPixelsRange.max,
          doInvertToDomain: doInvertDomain,
        ).apply(lextredValue);
        // 1.2.1:
        fromValuesRange = outputDataRange;
        toPixelsRange   = Interval(0.0, heightToLextr);
        doInvertDomain  = !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.vertical);
        lextredValue    = outputValue;
        outputPixels = ToPixelsExtrapolation1D(
          fromValuesMin: fromValuesRange.min,
          fromValuesMax: fromValuesRange.max,
          toPixelsMin: toPixelsRange.min,
          toPixelsMax: toPixelsRange.max,
          doInvertToDomain: doInvertDomain,
        ).apply(lextredValue);
        break;
      case ChartSeriesOrientation.row:
      // 1.2.2:
        fromValuesRange = outputDataRange;
        toPixelsRange   = Interval(0.0, widthToLextr);
        doInvertDomain  = !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.horizontal);
        lextredValue    = outputValue;
        inputPixels     = ToPixelsExtrapolation1D(
          fromValuesMin: fromValuesRange.min,
          fromValuesMax: fromValuesRange.max,
          toPixelsMin: toPixelsRange.min,
          toPixelsMax: toPixelsRange.max,
          doInvertToDomain: doInvertDomain,
        ).apply(lextredValue);
        // 1.1.2:
        fromValuesRange = inputDataRange;
        toPixelsRange   = Interval(0.0, constraints.height);
        doInvertDomain  = !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.vertical);
        lextredValue    = inputValue;
        outputPixels = ToPixelsExtrapolation1D(
          fromValuesMin: fromValuesRange.min,
          fromValuesMax: fromValuesRange.max,
          toPixelsMin: toPixelsRange.min,
          toPixelsMax: toPixelsRange.max,
          doInvertToDomain: doInvertDomain,
        ).apply(lextredValue);
        break;
    }

    return PointOffset(
      inputValue: inputPixels,
      outputValue: outputPixels,
    );
  }
  /* todo-00-last : KEEP FOR NOW
  PointOffset lextrColumnInContextOf({
    required ChartSeriesOrientation  chartSeriesOrientation,
    required BoxContainerConstraints constraintsOnImmediateOwner,
    required Interval                inputDataRange,
    required Interval                outputDataRange,
    required double                  heightToLextr,
  }) {
    assert (chartSeriesOrientation == ChartSeriesOrientation.column);

    ChartSeriesOrientation orientation = chartSeriesOrientation;
    BoxContainerConstraints constraints = constraintsOnImmediateOwner;

    double inputPixels = 0.0;
    double outputPixels = 0.0;

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

    return PointOffset(
      inputValue: inputPixels,
      outputValue: outputPixels,
    );
  }

  PointOffset lextrRowInContextOf({
    required ChartSeriesOrientation  chartSeriesOrientation,
    required BoxContainerConstraints constraintsOnImmediateOwner,
    required Interval                inputDataRange,
    required Interval                outputDataRange,
    required double                  widthToLextr,
  }) {
    assert (chartSeriesOrientation == ChartSeriesOrientation.row);

    ChartSeriesOrientation orientation = chartSeriesOrientation;
    BoxContainerConstraints constraints = constraintsOnImmediateOwner;

    double inputPixels = 0.0;
    double outputPixels = 0.0;

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
          fromValuesMin: inputDataRange.min,
          fromValuesMax: inputDataRange.max,
          toPixelsMin: 0.0,
          toPixelsMax: constraints.height,
          doInvertToDomain: !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.vertical),
        ).apply(inputValue);

    return PointOffset(
      inputValue: inputPixels,
      outputValue: outputPixels,
    );
  }

 */
}

/// Helper class mutates [fromInterval] and [toInterval] for lextr-ing only using
/// the portions corresponding to sign of [fromValue];
class _FromAndToPortionForValue {
  _FromAndToPortionForValue({
    required this.fromValue,
    required this.fromInterval,
    required this.toInterval,
    required this.isLextrIntoValueSignPortion,
  }) {
    if (isLextrIntoValueSignPortion) {
      fromIntervalPortion = fromInterval.sameSignPortionOrExceptionForValue(fromValue);
      toIntervalPortion = fromInterval.ratioPortionOfPositiveOtherForValueOrException(toInterval, fromValue);
      } else {
        // 0.0 <= fromValue
      fromIntervalPortion = fromInterval;
      toIntervalPortion = toInterval;
      }
    }

  final double fromValue;
  final Interval fromInterval;
  final Interval toInterval;
  final bool isLextrIntoValueSignPortion;

  late final Interval fromIntervalPortion;
  late final Interval toIntervalPortion;

}