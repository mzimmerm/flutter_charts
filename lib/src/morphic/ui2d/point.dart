import 'dart:ui' show Offset;

import '../../util/util_dart.dart' show DomainLTransform1D, Interval, ToPixelsLTransform1D;
import '../container/constraints.dart';
import '../container/container_layouter_base.dart';

import '../container/chart_support/chart_series_orientation.dart';

class PointOffset extends Offset {
  const PointOffset({
    required double inputValue,
    required double outputValue,
  }) : super(inputValue, outputValue);

  PointOffset.fromOffset(Offset offset)
      : this(
          inputValue: offset.dx,
          outputValue: offset.dy,
        );

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

  /// Lextr this [PointOffset] to it's pixel scale.
  ///
  /// The Lextr takes into account chart orientation [chartSeriesOrientation],
  /// which may cause the x and y (input and output) values to flip
  /// (transpose around left-right bottom-up diagonal) during the lextr.
  ///
  ///   - [chartSeriesOrientation] describes the orientation. [ChartSeriesOrientation.column] transforms
  ///     only once on each axis: between value-domain and pixel-domain on the same axis.
  ///     [ChartSeriesOrientation.column] transforms twice on each axis:
  ///       - first transforms value on each axis to value on cross-axis, using their respective value-domains,
  ///       - second on each cross axis, from value-domain to pixel-domain
  ///
  ///   - [constraintsOnImmediateOwner] constraints set the width and height of the the pixel-domains;
  ///     used IF [isLextrUseSizerInsteadOfConstraint] is false (default).
  ///   - [heightToLextr] is the height used for pixel-domain,
  ///     used IF  [isLextrUseSizerInsteadOfConstraint] is true. Flip use with [constraintsOnImmediateOwner]
  ///   - [widthToLextr] - equivalent to [heightToLextr]
  ///   - [inputDataRange] is the data value-range on the input domain (1st coordinate, x)
  ///   - [outputDataRange] is the data value-range on the output domain (2nd coordinate, y)
  ///   - [isLextrOnlyToValueSignPortion] UNUSED CURRENTLY. Default false
  ///   - [isLextrUseSizerInsteadOfConstraint] if true, processing uses [heightToLextr] and [widthToLextr]
  ///      instead of [constraintsOnImmediateOwner] to set height and width of the pixel-domains. Default false.
  ///
  /// Items below summarize the rules for lextr-ing [PointOffset] depending on it's [chartSeriesOrientation]
  /// being [ChartSeriesOrientation.column] or the [ChartSeriesOrientation.row].
  ///
  /// Below:
  ///   - 'x' means the same as in-code 'inputValue', 'y' the same as 'outputValue'.
  ///   - 'min' means the same as in-code 'domainStart', 'max' the same as 'domainEnd'
  ///   - the transforms are depicting starting on the left.
  ///   - 'row' causes 2 transforms, 'column' 1 transform
  ///
  /// Description of transforms:
  ///
  ///   1. The [ChartSeriesOrientation.column] causes 1 transform, shown here on min and max values:
  ///     - Transform steps
  ///       - 1st coordinate : x min -> x pixel min (placed in 1st coordinate)
  ///       - 1st coordinate : x max -> x pixel max (placed in 1st coordinate)
  ///       - 2nd coordinate : y min -> y pixel max (placed in 2nd coordinate)
  ///       - 2nd coordinate : y max -> y pixel min (placed in 2nd coordinate)
  ///     -  Ex: AxisLineContainer FOR X AXIS LINE: we define a HORIZONTAL line, which draws HORIZONTAL line
  ///            on position Y pixels corresponding to outputValue 0
  ///            (in the middle of a chart, if both positive and negative present)
  ///       ``` dart
  ///         fromPointOffset: PointOffset(inputValue: xLabelsGenerator.dataRange.min, outputValue: yLabelsGenerator.dataRange.max),
  ///         toPointOffset:   PointOffset(inputValue: xLabelsGenerator.dataRange.max, outputValue: yLabelsGenerator.dataRange.max),
  ///       ```
  ///       - Using the transform steps, the `fromPointOffset` and `toPointOffset` draws
  ///         a HORIZONTAL line at x = x pixel min, where we want the Y Axis:
  ///         - fromPointOffset: (x min, y max) is drawn as PIXEL PointOffset (x pixel min, y pixel min)
  ///         - toPointOffset:   (x max, y max) is drawn as PIXEL PointOffset (x pixel max, y pixel min)
  ///
  ///       - Adding numbers to the example:
  ///         - x value range = (0, 100)
  ///         - x pixel range = (0, 300)
  ///         - y value range = (-1,000, +3,400)
  ///         - y pixel range = (0, 500)
  ///         - fromPointOffset: (0,   3,400) is drawn as PIXEL (0,   0) to
  ///         - fromPointOffset: (100, 3,400) is drawn as PIXEL (300, 0)
  ///         - THIS IS HORIZONTAL LINE AT Y = 0, WHICH GIVES THE CONTAINER HEIGHT=0.
  ///           LAYOUT PLACES THE LINE BETWEEN POSITIVE AND NEGATIVE SECTIONS
  ///
  ///
  ///   2. The [ChartSeriesOrientation.row] causes 2 consecutive transforms, shown here on min and max values:
  ///     - Transform steps
  ///       - 1st coordinate : x min -> y min -> y pixel max (placed in 2nd coordinate)
  ///       - 1st coordinate : x max -> y max -> y pixel min (placed in 2nd coordinate)
  ///       - 2nd coordinate : y min -> x min -> x pixel min (placed in 1st coordinate)
  ///       - 2nd coordinate : y max -> x max -> x pixel max (placed in 1st coordinate)
  ///     -  Ex: AxisLineContainer FOR Y AXIS LINE : we define a HORIZONTAL line, which draws VERTICAL line
  ///            on position X pixels = 0 (in DataContainer coordinates) due to the transpose of coordinates:
  ///       ``` dart
  ///         fromPointOffset: PointOffset(inputValue: xLabelsGenerator.dataRange.min, outputValue: yLabelsGenerator.dataRange.min),
  ///         toPointOffset:   PointOffset(inputValue: xLabelsGenerator.dataRange.max, outputValue: yLabelsGenerator.dataRange.min),
  ///       ```
  ///       - Using the transform steps, the `fromPointOffset` and `toPointOffset` draws
  ///         a vertical line at x = x pixel min, where we want the Y Axis:
  ///         - fromPointOffset: (x min, y min) is drawn as PIXEL PointOffset (x pixel min, y pixel max)
  ///         - toPointOffset:   (x max, y min) is drawn as PIXEL PointOffset (x pixel min, y pixel min)
  ///
  ///       - Adding numbers to the example:
  ///         - x value range = (0, 100)
  ///         - x pixel range = (0, 300)
  ///         - y value range = (-1,000, +3,400)
  ///         - y pixel range = (0, 500)
  ///         - fromPointOffset: (0,   -1,000) is drawn as PIXEL (0, 500) to
  ///         - fromPointOffset: (100, -1,000) is drawn as PIXEL (0,   0)
  ///         - THIS IS VERTICAL LINE AT X = 0, WHICH GIVES THE CONTAINER WIDTH = 0.
  ///           LAYOUT PLACES THE LINE JUST AFTER LABELS
  ///
  PointOffset lextrInContextOf({
    required ChartSeriesOrientation  chartSeriesOrientation,
    required BoxContainerConstraints constraintsOnImmediateOwner,
    required Interval                inputDataRange,
    required Interval                outputDataRange,
    required double                  heightToLextr,
    required double                  widthToLextr,
    required bool                    isLextrOnlyToValueSignPortion, // default false
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
        doInvertDomain1  = false;
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
        toPixelsRange2   = Interval(0.0, heightToLextr); // NOT inverted domain - pixels are within some container!!
        doInvertDomain2  = true;
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
        toPixelsRange1   = Interval(0.0, heightToLextr);
        doInvertDomain1  = true; // inverted domain
        // for position of inputValue in inputDataRange(x), FIRST find corresponding position in outputDataRange(y)
        // this new position will be transformed to pixels on the output(y)
        fromValue1 = DomainLTransform1D(
          fromDomainStart: inputDataRange.min,
          fromDomainEnd: inputDataRange.max,
          toDomainStart: outputDataRange.min,
          toDomainEnd: outputDataRange.max,
        ).apply(inputValue);

        outputPixels     = lextrToPixelsFromValueInContext(
          fromValue: fromValue1,
          fromValuesRange: fromValuesRange1,
          toPixelsRange: toPixelsRange1,
          doInvertDomain: doInvertDomain1,
          isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );

        // 1.1.2:
        fromValuesRange2 = inputDataRange;
        toPixelsRange2   = Interval(0.0, isLextrUseSizerInsteadOfConstraint ? widthToLextr : constraints.width);
        doInvertDomain2  = false;
        // for position of outputValue in outputDataRange, FIRST find corresponding position in inputDataRange
        // this new position will be transformed to pixels in the input (x)
        fromValue2 =  DomainLTransform1D(
          fromDomainStart: outputDataRange.min,
          fromDomainEnd: outputDataRange.max,
          toDomainStart: inputDataRange.min,
          toDomainEnd: inputDataRange.max,
        ).apply(outputValue);
        inputPixels    = lextrToPixelsFromValueInContext(
          fromValue: fromValue2,
          fromValuesRange: fromValuesRange2,
          toPixelsRange: toPixelsRange2,
          doInvertDomain: doInvertDomain2,
          isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );
        break;
    }

    // todo-00 : also figure out and store a barPointSize, which represents the HBar or VBar representing the point,
    //            automatically due to the row or column orientation.
    //           - in one direction, it will be outputPixels (column) or inputPixels (row)
    //           - in the cross direction, it will be width of the constraints (column) or height of constraints (row)
    //           - it can be used to get the rectangle representing the bar in VBarPointContainer
    return PointOffset(
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
    required bool     isLextrOnlyToValueSignPortion, // default false
    required bool     isLextrUseSizerInsteadOfConstraint, // default false
  }) {
    assert (toPixelsRange.min == 0.0);
    // todo-010 : assumed false at all times. But KEEP THE isLextrOnlyToValueSignPortion VARIABLES FOR NOW
    assert (isLextrOnlyToValueSignPortion == false);

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
      // todo-010 : DEAD END, because condition assumed false at all times. But KEEP THE isLextrOnlyToValueSignPortion VARIABLES FOR NOW
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