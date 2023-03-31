
import 'dart:ui' show Offset;

import '../../util/util_dart.dart' show Interval, ToPixelsLTransform1D;
import '../container/constraints.dart';
import '../container/container_layouter_base.dart';

import '../container/chart_support/chart_series_orientation.dart';

class PointOffset extends Offset {
  const PointOffset({
    required double inputValue,
    required double outputValue,
    // todo-00-done : this.isLextrOnlyToValueSignPortion = true,
  }) : super(inputValue, outputValue);

  PointOffset.fromOffset(Offset offset)  // todo-00-done : , [bool isLextrOnlyToValueSignPortion = true])
      : this(
          inputValue: offset.dx,
          outputValue: offset.dy,
    // todo-00-done : isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
        );

  // todo-00-done : final bool isLextrOnlyToValueSignPortion;

  double get inputValue => dx;
  double get outputValue => dy;
  @override
  PointOffset operator +(Offset other) => PointOffset(
        inputValue: inputValue + other.dx,
        outputValue: outputValue + other.dy,
    // todo-00-done : isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
      );
  @override
  PointOffset operator -(Offset other) => PointOffset(
    inputValue: inputValue - other.dx,
    outputValue: outputValue - other.dy,
    // todo-00-done : isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
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
  PointOffset lextrInContextOf({
    required ChartSeriesOrientation  chartSeriesOrientation,
    required BoxContainerConstraints constraintsOnImmediateOwner,
    required Interval                inputDataRange,
    required Interval                outputDataRange,
    required double                  heightToLextr,
    required double                  widthToLextr,
    required bool                    isLextrOnlyToValueSignPortion, // default true
    required bool                    isLextrUseSizerInsteadOfConstraint, // default false todo-00-document
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
        
        inputPixels = lextrFromValueInContext(
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

        outputPixels    = lextrFromValueInContext(
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

        inputPixels     = lextrFromValueInContext(
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

        outputPixels    = lextrFromValueInContext(
          fromValue: fromValue2,
          fromValuesRange: fromValuesRange2,
          toPixelsRange: toPixelsRange2,
          doInvertDomain: doInvertDomain2,
          isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );
        break;
    }

    return PointOffset(
      inputValue: inputPixels,
      outputValue: outputPixels,
    );
  }

  /// Lextr [fromValue] taking into account value and pixel range, domain invert, and whether
  /// to use only the portion of from range that has same sign as inputValue
  double lextrFromValueInContext({
    required double   fromValue,
    required Interval fromValuesRange,
    required Interval toPixelsRange,
    required bool     doInvertDomain,
    required bool     isLextrOnlyToValueSignPortion, // default true
    required bool     isLextrUseSizerInsteadOfConstraint, // default false
  }) {
    assert (toPixelsRange.min == 0.0);
    var portion = _FromAndToPortionForFromValue(
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
class _FromAndToPortionForFromValue {
  _FromAndToPortionForFromValue({
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