
import 'dart:ui' show Offset;

import '../../util/util_dart.dart' show Interval, ToPixelsLTransform1D;
import '../container/constraints.dart';
import '../container/container_layouter_base.dart';

import '../container/chart_support/chart_series_orientation.dart';

class PointOffsetOrig20230331 extends Offset {
  const PointOffsetOrig20230331({
    required double inputValue,
    required double outputValue,
  }) : super(inputValue, outputValue);

  PointOffsetOrig20230331.fromOffset(Offset offset)
      : this(
          inputValue: offset.dx,
          outputValue: offset.dy,
        );

  double get inputValue => dx;
  double get outputValue => dy;
  @override
  PointOffsetOrig20230331 operator +(Offset other) => PointOffsetOrig20230331(
        inputValue: inputValue + other.dx,
        outputValue: outputValue + other.dy,
      );
  @override
  PointOffsetOrig20230331 operator -(Offset other) => PointOffsetOrig20230331(
    inputValue: inputValue - other.dx,
    outputValue: outputValue - other.dy,
  );

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
  PointOffsetOrig20230331 lextrInContextOf({
    required ChartSeriesOrientation  chartSeriesOrientation,
    required BoxContainerConstraints constraintsOnImmediateOwner,
    required Interval                inputDataRange,
    required Interval                outputDataRange,
    required double                  heightToLextr,
    required double                  widthToLextr,
    required bool                    isLextrOnlyToValueSignPortion, // default true
    required bool                    isLextrUseSizerInsteadOfConstraint, // default false
  }) {
    ChartSeriesOrientation orientation = chartSeriesOrientation;
    BoxContainerConstraints constraints = constraintsOnImmediateOwner;

    double inputPixels = 0.0;
    double outputPixels = 0.0;

    Interval fromValuesRange1 , fromValuesRange2;
    Interval toPixelsRange1   , toPixelsRange2  ;
    bool     doInvertDomain1  , doInvertDomain2 ;
    double   fromValue1       , fromValue2      ;

    switch (orientation) {
      case ChartSeriesOrientation.column:
        // 1.1.1:
        fromValuesRange1 = inputDataRange;
        toPixelsRange1   = Interval(0.0, isLextrUseSizerInsteadOfConstraint ? widthToLextr : constraints.width);
        doInvertDomain1  = !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.horizontal);
        fromValue1       = inputValue;
        
        inputPixels = lextrToPixelsFromValueInContext(
          fromValue: fromValue1,
          fromValuesRange: fromValuesRange1,
          toPixelsRange: toPixelsRange1,
          doInvertDomain: doInvertDomain1,
          isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );

        // 1.2.1:
        fromValuesRange2 = outputDataRange;
        toPixelsRange2   = Interval(0.0, heightToLextr);
        doInvertDomain2  = !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.vertical);
        fromValue2       = outputValue;

        outputPixels    = lextrToPixelsFromValueInContext(
          fromValue: fromValue2,
          fromValuesRange: fromValuesRange2,
          toPixelsRange: toPixelsRange2,
          doInvertDomain: doInvertDomain2,
          isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );
        break;
      case ChartSeriesOrientation.row:
      // 1.2.2:
        fromValuesRange1 = outputDataRange;
        toPixelsRange1   = Interval(0.0, widthToLextr);
        doInvertDomain1  = !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.horizontal);
        fromValue1       = outputValue;

        inputPixels     = lextrToPixelsFromValueInContext(
          fromValue: fromValue1,
          fromValuesRange: fromValuesRange1,
          toPixelsRange: toPixelsRange1,
          doInvertDomain: doInvertDomain1,
          isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );
        // 1.1.2:
        fromValuesRange2 = inputDataRange;
        toPixelsRange2   = Interval(0.0, isLextrUseSizerInsteadOfConstraint ? heightToLextr : constraints.height);
        doInvertDomain2  = !orientation.isPixelsAndValuesSameDirectionFor(lextrToRangeOrientation: LayoutAxis.vertical);
        fromValue2       = inputValue;

        outputPixels    = lextrToPixelsFromValueInContext(
          fromValue: fromValue2,
          fromValuesRange: fromValuesRange2,
          toPixelsRange: toPixelsRange2,
          doInvertDomain: doInvertDomain2,
          isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );
        break;
    }

    return PointOffsetOrig20230331(
      inputValue: inputPixels,
      outputValue: outputPixels,
    );
  }

  /// Lextr [fromValue] taking into account value and pixel range, domain invert, and whether
  /// to use only the portion of from range that has same sign as inputValue
  double lextrToPixelsFromValueInContext({
    required double   fromValue,
    required Interval fromValuesRange,
    required Interval toPixelsRange,
    required bool     doInvertDomain,
    required bool     isLextrOnlyToValueSignPortion, // default true
    required bool     isLextrUseSizerInsteadOfConstraint, // default false
  }) {
    assert (toPixelsRange.min == 0.0);
    var portion = _FromAndToPortionForFromValueOrig20230331(
      fromValue: fromValue,
      fromValuesRange: fromValuesRange,
      toPixelsRange: toPixelsRange,
      isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
    );
    fromValuesRange = portion.fromValuesPortion;
    toPixelsRange = portion.toPixelsPortion;

    var transform = ToPixelsLTransform1D(
        fromValuesMin: fromValuesRange.min,
        fromValuesMax: fromValuesRange.max,
        toPixelsMin: toPixelsRange.min,
        toPixelsMax: toPixelsRange.max,
        doInvertToDomain: doInvertDomain,
    );
    double inputPixels;
    if (isLextrUseSizerInsteadOfConstraint) {
      inputPixels = transform.apply(fromValue);
    } else {
      inputPixels = transform.applyOnlyScaleOnLength(fromValue);
    }

    return inputPixels;
  }
}

/// Helper class mutates [fromValuesRange] and [toPixelsRange] for lextr-ing only using
/// the portions corresponding to sign of [fromValue];
class _FromAndToPortionForFromValueOrig20230331 {
  _FromAndToPortionForFromValueOrig20230331({
    required this.fromValue,
    required this.fromValuesRange,
    required this.toPixelsRange,
    required this.isLextrOnlyToValueSignPortion,
  }) {
    if (isLextrOnlyToValueSignPortion) {
      fromValuesPortion = fromValuesRange.portionForSignOfValue(fromValue);
      toPixelsPortion = fromValuesRange.portionOfIntervalAsMyPosNegRatio(toPixelsRange, fromValue);
    } else {
      // 0.0 <= fromValue
      fromValuesPortion = fromValuesRange;
      toPixelsPortion = toPixelsRange;
    }
  }

  final double fromValue;
  final Interval fromValuesRange;
  final Interval toPixelsRange;
  final bool isLextrOnlyToValueSignPortion;

  late final Interval fromValuesPortion;
  late final Interval toPixelsPortion;
}