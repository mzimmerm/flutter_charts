import 'dart:ui' show Offset, Size;

import '../../util/util_dart.dart' show Interval, ToPixelsLTransform1D;
import '../container/constraints.dart';
import '../container/chart_support/chart_style.dart';

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
  /// For [ChartOrientation.column] width is constraints.width on column, height is outputValuePixels
  /// For [ChartOrientation.row]    width is inputValuePixels, height is constraints.height on row
  ///
  /// Used to get the rectangle representing the bar in chart [BarPointContainer].
  ///
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
  /// it if [chartOrientation] is [ChartOrientation.row].
  ///
  /// The Lextr takes into account chart orientation [chartOrientation],
  /// which may cause the x and y (input and output) values to transpose
  /// around [Diagonal.leftToRightUp] during the lextr.
  ///
  ///   - [chartOrientation] describes the orientation. [ChartOrientation.column] transforms
  ///     only once on each axis: between value-domain and pixel-domain on the same axis.
  ///     [ChartOrientation.column] transforms twice on each axis:
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
  ///   - [isLextrUseSizerInsteadOfConstraint] if true, processing uses [heightToLextr] and [widthToLextr]
  ///      instead of [constraintsOnImmediateOwner] to set height and width of the pixel-domains. Default false.
  ///
  /// Items below summarize the rules for lextr-ing [PointOffset] depending on it's [chartOrientation]
  /// being [ChartOrientation.column] or the [ChartOrientation.row].
  ///
  /// Below:
  ///   - 'x' means the same as in-code 'inputValue', 'y' the same as 'outputValue'.
  ///   - 'min' means the same as in-code 'domainStart', 'max' the same as 'domainEnd'
  ///   - the transforms are depicting starting on the left.
  ///   - 'row' causes 2 transforms, 'column' 1 transform
  ///
  /// Description of transforms:
  ///
  ///   1. The [ChartOrientation.column] performs 1 transform, which transforms a [PointOffset]
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
  ///         fromPointOffset: PointOffset(inputValue: inputLabelsGenerator.dataRange.min, outputValue: outputLabelsGenerator.dataRange.max),
  ///         toPointOffset:   PointOffset(inputValue: inputLabelsGenerator.dataRange.max, outputValue: outputLabelsGenerator.dataRange.max),
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
  ///   2. The [ChartOrientation.row] performs 2 consecutive transforms
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
  ///         fromPointOffset: PointOffset(inputValue: inputLabelsGenerator.dataRange.min, outputValue: outputLabelsGenerator.dataRange.min),
  ///         toPointOffset:   PointOffset(inputValue: inputLabelsGenerator.dataRange.max, outputValue: outputLabelsGenerator.dataRange.min),
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
    required ChartOrientation  chartOrientation,
    required BoxContainerConstraints constraintsOnImmediateOwner,
    required Interval                inputDataRange,
    required Interval                outputDataRange,
    required double                  heightToLextr,
    required double                  widthToLextr,
    required bool                    isLextrUseSizerInsteadOfConstraint, // default false
  }) {
    ChartOrientation orientation = chartOrientation;
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
      case ChartOrientation.column:
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
        );
        inputPixels = inputValuePixels.fromValueOnAxisPixels;

        // 1.2.1:
        fromValuesRange2 = outputDataRange;
        toPixelsRange2   = Interval(0.0, heightToLextr); // NOT inverted domain - pixels are within some container!!
        doInvertDomain2  = true;
        fromValue2       = outputValue;

        var fromValueOutputPixels    = _lextrFromValueToPixelsOnSameAxis(
          fromValue: fromValue2,
          fromValuesRange: fromValuesRange2,
          toPixelsRange: toPixelsRange2,
          doInvertDomain: doInvertDomain2,
        );
        outputPixels =  fromValueOutputPixels.fromValueOnAxisPixels;

        // Width and height of
        barPointRectWidth  = toPixelsRange1.length;
        barPointRectHeight = fromValueOutputPixels.fromValueLengthInPixels;

        break;
      case ChartOrientation.row:
      // todo-010 : to convert between column chart and row chart in 2D
      //                    is equivalent to diagonal transpose ALL POINTS IN 2D EXCEPT LABEL DIRECTION around Diagonal.LeftToRightUp
      //                    such transpose is equivalent to flipping (transposing) coordinates: x -> y, y -> x
      //                    LETS PREFIX THE NAMES OF TRANSPOSED VARIABLES WITH 'iotrp' for 'input/output transpose of positive values to positive values.
      //                    Notes:
      //                      - Transpose around Diagonal.LeftToRightDown is equivalent to : x -> -y, y -> -x, would be named iotrn
      //                      - Rotation around z axis by 90 degrees clockwise is equivalent to : x -> -y, y -> x, would be named iorotqc for 'io rotation by a quarter circle clockwise.
      //                Naming used in code:
      //                    point=this=(input, output) -> iotrpPoint
      //                    inputDataRange             -> iotrpOutputDataRange (this is just a rename, but make a copy)
      //                    outputDataRange            -> iotrpInputDataRange
      //
        // Transpose all points in chart around [Diagonal.leftToRightUp].
        // This changes the chart from vertical bar chart to horizontal bar chart.
        // Transform 1 : iotrp transform: (in, out) -> (iotrpIn=out, iotrpOut=in)
        Interval iotrpOutputDataRange = Interval.from(inputDataRange);
        Interval iotrpInputDataRange = Interval.from(outputDataRange);
        PointOffset iotrpPoint = PointOffset(inputValue: outputValue, outputValue: inputValue);

        // 1.2.2:
        // Transform 2 : iotrpOut -> pixels on vertical y axis (verticalPixels)
        var verticalPixelsRange   = Interval(0.0, isLextrUseSizerInsteadOfConstraint ? heightToLextr : constraints.height);
        var fromValueOutputPixels = _lextrFromValueToPixelsOnSameAxis(
          fromValue: iotrpPoint.outputValue,
          fromValuesRange: iotrpOutputDataRange,
          toPixelsRange: verticalPixelsRange,
          doInvertDomain: false,
        );
        outputPixels = fromValueOutputPixels.fromValueOnAxisPixels;

        // 1.1.2:
        // Transform 2 : iotrpIn -> pixels on horizontal x axis (horizontalPixels)
        var horizontalPixelsRange   = Interval(0.0, widthToLextr);

        var fromValueInputPixels = _lextrFromValueToPixelsOnSameAxis(
          fromValue: iotrpPoint.inputValue,
          fromValuesRange: iotrpInputDataRange,
          toPixelsRange: horizontalPixelsRange,
          doInvertDomain: true,
        );
        inputPixels = fromValueInputPixels.fromValueOnAxisPixels;

        barPointRectWidth  = fromValueInputPixels.fromValueLengthInPixels;
        barPointRectHeight = verticalPixelsRange.length;

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
  }) {
    assert (toPixelsRange.min == 0.0);

    var portion = _FromAndToPortionForFromValue(
      fromValue: fromValue,
      fromValuesRange: fromValuesRange,
      toPixelsRange: toPixelsRange,
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
  }) {
    // 0.0 <= fromValue
    fromValuesPortion = fromValuesRange;
    toPixelsPortion = toPixelsRange;
  }

  final double fromValue;
  final Interval fromValuesRange;
  final Interval toPixelsRange;

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