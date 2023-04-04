import 'dart:ui' show Offset, Size;

import '../../util/util_dart.dart' show DomainLTransform1D, Interval, ToPixelsLTransform1D;
import '../container/constraints.dart';
// import '../container/container_layouter_base.dart';
import '../container/chart_support/chart_orientation.dart';

/// Like [Offset] but in addition, can manage lextr-ing inside chart to chart value domains and pixel domains,
/// utilizing [lextrToPixelsMaybeTransposeInContextOf] which returns a new [PointOffset] in pixels, created from this [PointOffset]'s
/// position and chart value domains and pixel domains.
class PointOffset extends Offset {
  PointOffset({
    required double inputValue,
    required double outputValue,
  }) : super(inputValue, outputValue);

  PointOffset.fromOffset(Offset offset)
      : this(
          inputValue: offset.dx,
          outputValue: offset.dy,
        );

  /// Size of the rectangle which represents one value point on either horizontal bar or vertical bar,
  /// depending on chart orientation. Calculated by the call to [lextrToPixelsMaybeTransposeInContextOf].
  ///
  /// For [ChartSeriesOrientation.column] width is constraints.width on column, height is outputValuePixels
  /// For [ChartSeriesOrientation.row]    width is inputValuePixels, height is constraints.height on row
  ///
  /// Used to get the rectangle representing the bar in chart [BarPointContainer].
  ///
  /// todo-010 : make it return, do not keep on state
  late final Size barPointRectSize;

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

  /// Lextr this [PointOffset] to it's pixel scale, first possibly transposing
  /// it if [chartSeriesOrientation] is [ChartSeriesOrientation.row].
  ///
  /// The Lextr takes into account chart orientation [chartSeriesOrientation],
  /// which may cause the x and y (input and output) values to transpose
  /// around [Diagonal.leftToRightUp] during the lextr.
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
  ///   1. The [ChartSeriesOrientation.column] performs 1 transform, which transforms a [PointOffset]
  ///      from values-range to pixels-range on both axes.
  ///     - Transform steps, shown here on min and max values:
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
  ///   2. The [ChartSeriesOrientation.row] performs 2 consecutive transforms
  ///      This first transform transposes a [PointOffset] around [Diagonal.leftToRightUp],
  ///      representing a (x -> y, y -> x) transform,
  ///      the second transforms a [PointOffset] from values-range to pixels-range on both axes.
  ///      Note: the first transform is equivalent to rotation clock-wise by 90 degrees (y -> x, x -> -y),
  ///      followed by flipping around horizontal axis (y -> -y).
  ///     - Transforms steps , shown here on min and max values:
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
  PointOffset lextrToPixelsMaybeTransposeInContextOf({
    required ChartSeriesOrientation  chartSeriesOrientation,
    required BoxContainerConstraints constraintsOnImmediateOwner,
    required Interval                inputDataRange,
    required Interval                outputDataRange,
    required double                  heightToLextr,
    required double                  widthToLextr,
    required bool                    isLextrOnlyToValueSignPortion, // default false
    required bool                    isLextrUseSizerInsteadOfConstraint, // default false
  }) {
    assert (isLextrOnlyToValueSignPortion == false);
    ChartSeriesOrientation orientation = chartSeriesOrientation;
    BoxContainerConstraints constraints = constraintsOnImmediateOwner;

    double inputPixels = 0.0;
    double outputPixels = 0.0;

    Interval fromValuesRange1 , fromValuesRange2;
    Interval toPixelsRange1   , toPixelsRange2  ;
    bool     doInvertDomain1  , doInvertDomain2 ;
    double   fromValue1       , fromValue2      ;

    // Width and height of the bar rectangle in pixels.
    // The bar rectangle represents this point on bar chart.
    double barPointRectWidth, barPointRectHeight;

    switch (orientation) {
      case ChartSeriesOrientation.column:
        // 1.1.1:
        fromValuesRange1 = inputDataRange;
        toPixelsRange1   = Interval(0.0, isLextrUseSizerInsteadOfConstraint ? widthToLextr : constraints.width);
        doInvertDomain1  = false;
        fromValue1       = inputValue;

        var inputValuePixels = _lextrFromValueToPixelsOnSameAxis(
          fromValue: fromValue1,
          fromValuesRange: fromValuesRange1,
          toPixelsRange: toPixelsRange1,
          doInvertDomain: doInvertDomain1,
          // todo-010 : KEEP for now : isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );
        inputPixels = inputValuePixels.fromValueOnAxisPixels;

        // 1.2.1:
        fromValuesRange2 = outputDataRange;
        toPixelsRange2   = Interval(0.0, heightToLextr); // NOT inverted domain - pixels are within some container!!
        doInvertDomain2  = true;
        fromValue2       = outputValue;

        var outputValuePixels    = _lextrFromValueToPixelsOnSameAxis(
          fromValue: fromValue2,
          fromValuesRange: fromValuesRange2,
          toPixelsRange: toPixelsRange2,
          doInvertDomain: doInvertDomain2,
          // todo-010 : KEEP for now : isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );
        outputPixels =  outputValuePixels.fromValueOnAxisPixels;

        // Width and height of
        barPointRectWidth  = toPixelsRange1.length;
        barPointRectHeight = outputValuePixels.fromValueLengthInPixels;

        break;
      case ChartSeriesOrientation.row:
        // Transpose all points in chart around [Diagonal.leftToRightUp].
        // This changes the chart from vertical bar chart to horizontal bar chart.
        // 1.2.2:
        fromValuesRange1 = outputDataRange;
        toPixelsRange1   = Interval(0.0, isLextrUseSizerInsteadOfConstraint ? heightToLextr : constraints.height);
        doInvertDomain1  = true; // inverted domain
        // for position of inputValue in inputDataRange(x), FIRST find corresponding position in outputDataRange(y)
        // this new position will be transformed to pixels on the output(y)
        fromValue1 = DomainLTransform1D(
          fromDomainStart: inputDataRange.min,
          fromDomainEnd: inputDataRange.max,
          toDomainStart: outputDataRange.min,
          toDomainEnd: outputDataRange.max,
        ).apply(inputValue);

        var outputValuePixels = _lextrFromValueToPixelsOnSameAxis(
          fromValue: fromValue1,
          fromValuesRange: fromValuesRange1,
          toPixelsRange: toPixelsRange1,
          doInvertDomain: doInvertDomain1,
          // todo-010 : KEEP for now : isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );
        outputPixels = outputValuePixels.fromValueOnAxisPixels;

        // 1.1.2:
        fromValuesRange2 = inputDataRange;
        toPixelsRange2   = Interval(0.0, widthToLextr);
        doInvertDomain2  = false;
        // for position of outputValue in outputDataRange, FIRST find corresponding position in inputDataRange
        // this new position will be transformed to pixels in the input (x)
        fromValue2 =  DomainLTransform1D(
          fromDomainStart: outputDataRange.min,
          fromDomainEnd: outputDataRange.max,
          toDomainStart: inputDataRange.min,
          toDomainEnd: inputDataRange.max,
        ).apply(outputValue);
        var fromValueInputPixels = _lextrFromValueToPixelsOnSameAxis(
          fromValue: fromValue2,
          fromValuesRange: fromValuesRange2,
          toPixelsRange: toPixelsRange2,
          doInvertDomain: doInvertDomain2,
          // todo-010 : KEEP for now : isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );
        inputPixels = fromValueInputPixels.fromValueOnAxisPixels;

        barPointRectWidth  = fromValueInputPixels.fromValueLengthInPixels;
        barPointRectHeight = toPixelsRange1.length;

        break;
    }

    PointOffset pointOffsetPixels = PointOffset(
      inputValue: inputPixels,
      outputValue: outputPixels,
    );

    // The size of small rectangle representing the point on bar chart, adjusted for orientation.
    pointOffsetPixels.barPointRectSize = Size(
      barPointRectWidth,
      barPointRectHeight,
    );

    // Finally, return the pixel position to which this PointOffset has been transformed.
    return pointOffsetPixels;
  }

  /// Lextr [fromValue] assumed to be in the [fromValuesRange], to pixels in range [toPixelsRange],
  /// possibly inverting the domains by setting [doInvertDomain].
  ///
  ///
  _ValuePixels _lextrFromValueToPixelsOnSameAxis({
    required double   fromValue,
    required Interval fromValuesRange,
    required Interval toPixelsRange,
    required bool     doInvertDomain,
    // todo-010 : KEEP for now : required bool     isLextrOnlyToValueSignPortion, // default false
    required bool     isLextrUseSizerInsteadOfConstraint, // default false
  }) {
    assert (toPixelsRange.min == 0.0);
    // todo-010 : KEEP for now : assert (isLextrOnlyToValueSignPortion == false);

    var portion = _FromAndToPortionForFromValue(
      fromValue: fromValue,
      fromValuesRange: fromValuesRange,
      toPixelsRange: toPixelsRange,
      // todo-010 : KEEP for now : isLextrOnlyToValueSignPortion: isLextrOnlyToValueSignPortion,
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
    double fromValueOnAxisPixels, fromValueLengthInPixels;
    /* todo-010 KEEP for now :
    if (isLextrUseSizerInsteadOfConstraint) {
      fromValueOnAxisPixels = transform.apply(fromValue);
    } else {
      fromValueOnAxisPixels = transform.applyOnlyScaleOnLength(fromValue);
    }
    */
    fromValueOnAxisPixels = transform.apply(fromValue);
    fromValueLengthInPixels = transform.applyOnlyScaleOnLength(fromValue).abs();

    return _ValuePixels(fromValueOnAxisPixels, fromValueLengthInPixels);
  }
}

class _ValuePixels {
  _ValuePixels(this.fromValueOnAxisPixels, this.fromValueLengthInPixels);
  final double fromValueOnAxisPixels;
  final double fromValueLengthInPixels;
}

/// Helper class mutates [fromValuesRange] and [toPixelsRange] for lextr-ing only using
/// the portions corresponding to sign of [fromValue];
class _FromAndToPortionForFromValue {
  _FromAndToPortionForFromValue({
    required this.fromValue,
    required this.fromValuesRange,
    required this.toPixelsRange,
    // todo-010 : KEEP for now : required this.isLextrOnlyToValueSignPortion,
  }) {
    /* todo-010 : KEEP for now :
    if (isLextrOnlyToValueSignPortion) {
      // todo-010 : DEAD END, because condition assumed false at all times. But KEEP THE isLextrOnlyToValueSignPortion VARIABLES FOR NOW
      fromValuesPortion = fromValuesRange.portionForSignOfValue(fromValue);
      toPixelsPortion = fromValuesRange.portionOfIntervalAsMyPosNegRatio(toPixelsRange, fromValue);
    } else {
      // 0.0 <= fromValue
      fromValuesPortion = fromValuesRange;
      toPixelsPortion = toPixelsRange;
    }
    */
    // 0.0 <= fromValue
    fromValuesPortion = fromValuesRange;
    toPixelsPortion = toPixelsRange;
  }

  final double fromValue;
  final Interval fromValuesRange;
  final Interval toPixelsRange;
  // todo-010 : KEEP for now : final bool isLextrOnlyToValueSignPortion;

  late final Interval fromValuesPortion;
  late final Interval toPixelsPortion;
}

/// Identifies a diagonal for transpose transfer.
///
/// [leftToRightUp] identifies the diagonal around which a coordinate system would
/// rotate to get from a vertical bar chart to a horizontal bar chart.
enum Diagonal {
  leftToRightDown,
  leftToRightUp,
}