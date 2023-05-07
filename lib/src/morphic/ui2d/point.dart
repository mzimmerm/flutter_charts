import 'dart:ui' show Offset, Size;

import '../../util/util_dart.dart' show Interval, ToPixelsLTransform1D;
import '../container/constraints.dart';
import '../container/chart_support/chart_style.dart';
import '../../chart/container/data_container.dart' as doc_data_container;

/// Extension of [Offset] which adds ability to lextr to a new [PointOffset] instance
/// created from it's instance data value in it's value domain to the pixel position in the pixel domains.
///
/// Note: This class position is renamed from [Offset.dx] and dy to [PointOffset.inputValue] and outputValue.
///
/// In addition to it's position inherited from [Offset], this class calculates and creates, during [layout],
/// it's member [barPointRectSize], the [Size] of the rectangle which presents the data value of this [PointOffset]
/// in the chart on a bar chart.
///
/// The lextr-ing is done in [lextrToPixelsMaybeTransposeInContextOf],
/// which returns a new [PointOffset] in pixels, created from this [PointOffset]'s
/// position and chart value domains and pixel domains.
///
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

  /// Pixel [Size] of the rectangle which presents this [PointOffset] on either horizontal bar or vertical bar,
  /// constructed late in [lextrToPixelsMaybeTransposeInContextOf], according to the [ChartOrientation] passed to
  /// [lextrToPixelsMaybeTransposeInContextOf].
  ///
  /// The [Size] width and height is calculated as follows:
  ///   - For [ChartOrientation.column] the width is constraints.width on column, height is outputValuePixels.
  ///   - For [ChartOrientation.row]    the width is inputValuePixels,            height is constraints.height on row.
  ///
  /// It becomes the [layoutSize] of the rectangle which presents this [PointOffset]; The [PointOffset]
  /// is created from [PointModel] member the [doc_data_container.PointContainer.pointModel].
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

  PointOffset lextrToPixelsMaybeTransposeInContextOfNEW({
    required ChartOrientation  chartOrientation,
    required BoxContainerConstraints constraintsOnImmediateOwner,
    required Interval                inputDataRange,
    required Interval                outputDataRange,
    required double                  heightToLextr,
    required double                  widthToLextr,
  }) {
    //ChartOrientation orientation = chartOrientation;
    //BoxContainerConstraints constraints = constraintsOnImmediateOwner;

    // todo-00 : finish this
    // On PointOffset
    //   - add method toVector, and fromVector
    // On Size extension
    //   - add method toVector, fromVector
    // Based on orientation:
    //   - set horizontalPixelsRange, verticalPixelsRange, based on same logic as in method
    //   - create 4 ToPixelsLTransform1D instances for data range combination:
    //     - column
    //       column00 (in->px)
    //         fromValuesRange: inputDataRange,
    //         toPixelsRange: horizontalPixelsRange,
    //         doInvertDomain: false,
    //       column11 (out->py)
    //         fromValuesRange: outputDataRange,
    //         toPixelsRange: verticalPixelsRange,
    //         doInvertDomain: true,
    //
    //     - row
    //       row10 (in->py)
    //         fromValuesRange: inputDataRange,
    //         toPixelsRange: verticalPixelsRange,
    //         doInvertDomain: false,
    //       row01 (out->px)
    //         fromValuesRange: outputDataRange,
    //         toPixelsRange: horizontalPixelsRange,
    //         doInvertDomain: true,
    //   - Note: the doInvert on row seems not right but works. Why?
    //
    //
    //   - Create 4 functional matrices (2 in each switch section), with function elements that correspond to how the affineTransform should work
    //     for column, affineTransformer = Matrix.affineTransformer
    //                   (column00.apply, column11.apply, rest Functional.identity)
    //     for column, linearTransformer = Matrix.linearTransformer
    //                   (column00.applyOnlyLinearScale, column11.applyOnlyLinearScale, rest Functional.identity)
    //     for row,    affineTransformer = Matrix.transposeThenAffineTransformer(transposeAroundDiagonal: Diagonal.leftToRightUp-others exception)
    //                   (row10.apply, row01.apply, rest Functional identity)
    //     for row,    linearTransformer = Matrix.transposeThenLinearTransformer(transposeAroundDiagonal: Diagonal.leftToRightUp-others exception)
    //                   (row10.applyOnlyLinearScale, row01.applyOnlyLinearScale, rest Functional identity)
    //
    //   - Call:
    //     pointOffsetPixels = PointOffset.fromVector(affineTransformer.applyOn(this.toVector));
    //     pointOffsetPixels.barPointRectSize = Size.fromVector(linearTransformer.applyOn(this.toVector));
    //   - Return pointOffsetPixels. THAT IS ALL
    //
    //
    // - rename : lextrToPixelsMaybeTransposeInContextOf => afftransfMaybeTransposeToPixelsInContextOf
    // - Convert names LinearTransform etc to AffineTransform
    // - Try to make AffineTransform constructors constant, as it seems they are repeated for every point.
    return this;
  }
/* */
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
  ///   - [heightToLextr] is the height used for pixel-domain,
  ///     used IF  [isLextrUseSizerInsteadOfConstraint] is true. Flip use with [constraintsOnImmediateOwner]
  ///   - [widthToLextr] - equivalent to [heightToLextr]
  ///   - [inputDataRange] is the data value-range on the input domain (1st coordinate, x)
  ///   - [outputDataRange] is the data value-range on the output domain (2nd coordinate, y)
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
  }) {
    ChartOrientation orientation = chartOrientation;
    BoxContainerConstraints constraints = constraintsOnImmediateOwner;

    double horizontalPixels = 0.0;
    double verticalPixels = 0.0;


    // Width and height of the bar rectangle in pixels.
    // The bar rectangle represents this point on bar chart.
    double barPointRectWidth, barPointRectHeight;

    switch (orientation) {
      case ChartOrientation.column:
        // 1.1.1:
        // KEEP : var horizontalPixelsRange   = Interval(0.0, isLextrUseSizerInsteadOfConstraint ? widthToLextr : constraints.width);
        var horizontalPixelsRange   = Interval(0.0, constraints.width);

        var horizontalValuePixels = _lextrFromValueToPixelsOnSameAxis(
          fromValue: inputValue,
          fromValuesRange: inputDataRange,
          toPixelsRange: horizontalPixelsRange,
          doInvertDomain: false,
        );
        horizontalPixels = horizontalValuePixels.pixelPositionForValue;

        // 1.2.1:
        var verticalPixelsRange   = Interval(0.0, heightToLextr); // NOT inverted domain - pixels are within some container!!

        var verticalValuePixels    = _lextrFromValueToPixelsOnSameAxis(
          fromValue: outputValue,
          fromValuesRange: outputDataRange,
          toPixelsRange: verticalPixelsRange,
          doInvertDomain: true,
        );
        verticalPixels =  verticalValuePixels.pixelPositionForValue;

        // Width and height of the rectangle layoutSize
        barPointRectWidth  = horizontalPixelsRange.length;
        barPointRectHeight = verticalValuePixels.pixelLengthForValue;

        break;
      case ChartOrientation.row:
      // todo-00-next : to convert between column chart and row chart in 2D
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

        // 1.2.2:
        // Transform 2 : iotrpOut -> pixels on vertical y axis (verticalPixels)
        // KEEP: var verticalPixelsRange   = Interval(0.0, isLextrUseSizerInsteadOfConstraint ? heightToLextr : constraints.height);
        var verticalPixelsRange   = Interval(0.0, constraints.height);

        var verticalValuePixels = _lextrFromValueToPixelsOnSameAxis(
          fromValue: inputValue,
          fromValuesRange: inputDataRange,
          toPixelsRange: verticalPixelsRange,
          doInvertDomain: false,
        );
        verticalPixels = verticalValuePixels.pixelPositionForValue;

        // 1.1.2:
        // Transform 2 : iotrpIn -> pixels on horizontal x axis (horizontalPixels)
        var horizontalPixelsRange   = Interval(0.0, widthToLextr);

        var horizontalValuePixels = _lextrFromValueToPixelsOnSameAxis(
          fromValue: outputValue,
          fromValuesRange: outputDataRange,
          toPixelsRange: horizontalPixelsRange,
          doInvertDomain: true,
        );
        horizontalPixels = horizontalValuePixels.pixelPositionForValue;

        // Width and height of the rectangle layoutSize
        barPointRectWidth  = horizontalValuePixels.pixelLengthForValue;
        barPointRectHeight = verticalPixelsRange.length;

        break;
    }

    PointOffset pointOffsetPixels = PointOffset(
      inputValue: horizontalPixels,
      outputValue: verticalPixels,
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

    var transform = ToPixelsLTransform1D(
        fromValues: Interval(fromValuesRange.min, fromValuesRange.max),
        toPixels:   Interval(toPixelsRange.min, toPixelsRange.max),
        doInvertToDomain: doInvertDomain,
    );
    double pixelPositionForValue, pixelLengthForValue;
    pixelPositionForValue = transform.apply(fromValue);
    pixelLengthForValue = transform.applyOnlyLinearScale(fromValue).abs();

    return _ValuePixels(pixelPositionForValue, pixelLengthForValue);
  }
/* */

  /// Present itself as code
  String asCodeConstructor() {
    return 'PointOffset('
        'inputValue: $inputValue,'
        'outputValue: $outputValue,'
        ')';
  }
}

class _ValuePixels {
  _ValuePixels(this.pixelPositionForValue, this.pixelLengthForValue);
  final double pixelPositionForValue;
  final double pixelLengthForValue;
}

/* todo-00-done : unused now
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
*/

/// Identifies a diagonal for transpose transfer.
///
/// [leftToRightUp] identifies the diagonal around which a coordinate system would
/// rotate to get from a vertical bar chart to a horizontal bar chart.
// todo-010 : move to an enum file - representing geometry
enum Diagonal {
  leftToRightDown,
  leftToRightUp,
}