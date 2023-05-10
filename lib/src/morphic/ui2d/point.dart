import 'dart:ui' show Offset, Size;


import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';

import '../../util/util_dart.dart' show Interval, ToPixelsAffineMap1D;
import '../container/constraints.dart';
import '../container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/util/extensions_flutter.dart' show SizeExtension;
import 'package:flutter_charts/src/util/vector/vector_2d.dart' show Vector;
import 'package:flutter_charts/src/util/vector/function_matrix_2d.dart'
    show DoubleToDoubleFunction, Functional, FunctionalMatrix2D;

// Docs only, not used in code.
import '../../chart/container/data_container.dart' as doc_data_container;

/// Extension of [Offset] which adds ability to affmap to a new [PointOffset] instance
/// created from it's instance data value in it's value range to the pixel position in the pixel ranges.
///
/// Note: This class position is renamed from [Offset.dx] and dy to [PointOffset.inputValue] and outputValue.
///
/// In addition to it's position inherited from [Offset], this class calculates and creates, during [layout],
/// it's member [barPointRectSize], the [Size] of the rectangle which presents the data value of this [PointOffset]
/// in the chart on a bar chart.
///
/// The affmap-ing is done in [affmapToPixelsMaybeTransposeInContextOf],
/// which returns a new [PointOffset] in pixels, created from this [PointOffset]'s
/// position and chart value ranges and pixel ranges.
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

  factory PointOffset.fromVector(Vector<double> vector) {
    vector.ensureLength(2, elseMessage: 'PointOffset can only be created from vector with 2 elements.');
    return PointOffset(inputValue: vector[0], outputValue: vector[1]);
  }

  /// Pixel [Size] of the rectangle which presents this [PointOffset] on either horizontal bar or vertical bar,
  /// constructed late in [affmapToPixelsMaybeTransposeInContextOf], according to the [ChartOrientation] passed to
  /// [affmapToPixelsMaybeTransposeInContextOf].
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

  // no need. PointOffset IS Offset. Offset get asOffset => Offset(inputValue, outputValue);
  Vector<double> toVector() => Vector<double>([inputValue, outputValue]);

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

  /// Creates and returns copy of this [PointOffset], affmap-ed to it's pixel scale; the copy's member
  /// [barPointRectSize] is filled with the [Size] that can and should be used as [layoutSize] of the bar
  /// representing this [PointOffset] on bar charts.
  ///
  /// The Affmap takes into account [chartOrientation], which may cause the x and y (input and output)
  /// values to transpose around the [Diagonal.leftToRightUp] during the affmap.
  ///
  /// While [PointOffset] can be used generically, the documentation here concentrates
  /// on it's use representing [PointModel] in one bar in the bar chart.
  ///
  /// The passed instances:
  ///
  ///   - [chartOrientation] describes the orientation.
  ///     - [ChartOrientation.column] transforms only once on each axis:
  ///       - affmap between value-range and pixel-range on the same axis.
  ///     - [ChartOrientation.row] transforms twice on each axis:
  ///       - first transposes value on each axis to value on cross-axis, using their respective value-ranges,
  ///       - second is affmap on each cross axis, from value-range to pixel-range
  ///   - [constraintsOnParentLayouter] should be the constraints of a [Row] or [Column]
  ///     [RollingBoxLayouter] in which the [PointModel] represented by this [PointOffset] is presented.
  ///   - [inputDataRange] is the data value-range on the input range (1st coordinate, x)
  ///   - [outputDataRange] is the data value-range on the output range (2nd coordinate, y)
  ///   - [sizerHeight] is the height used for pixel-range
  ///   - [sizerWidth] - equivalent to [sizerHeight]
  ///
  /// Note that the [constraintsOnParentLayouter] or [sizerHeight] and [sizerWidth] is used
  /// to calculate the size of [barPointRectSize] on the copy.
  ///
  /// Items below summarize the rules for affmap-ing [PointOffset] depending on it's [chartOrientation].
  ///
  /// Below:
  ///   - 'x' means the same as in-code 'inputValue', 'y' the same as 'outputValue'.
  ///   - 'min' means the same as in-code 'rangeStart', 'max' the same as 'rangeEnd'
  ///   - the transforms are depicting starting on the left.
  ///   - 'row' causes 2 transforms, 'column' 1 transform
  ///
  /// Description of transforms:
  ///
  ///   1. The [chartOrientation] value [ChartOrientation.column] performs 1 affmap transform, a [PointOffset]
  ///      from values-range to pixels-range on both axes.
  ///     - Transform steps, shown here on min and max values:
  ///       - 1st coordinate : x min -> x pixel min (placed in 1st coordinate) affmap
  ///       - 1st coordinate : x max -> x pixel max (placed in 1st coordinate) affmap
  ///       - 2nd coordinate : y min -> y pixel max (placed in 2nd coordinate) affmap
  ///       - 2nd coordinate : y max -> y pixel min (placed in 2nd coordinate) affmap
  ///
  ///     -  Example: AxisLineContainer FOR X AXIS LINE: we define a HORIZONTAL line, which draws HORIZONTAL line
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
  ///      This first transform is a transpose a [PointOffset] around [Diagonal.leftToRightUp],
  ///      representing a (x -> y, y -> x) transform,
  ///      the second transform is affmap of a [PointOffset] from values-range to pixels-range on both axes.
  ///      Note: the first transpose is equivalent to rotation clock-wise by 90 degrees (y -> x, x -> -y),
  ///            followed by flipping around horizontal axis (y -> -y).
  ///     - Transform steps , shown here on min and max values:
  ///       - 1st coordinate : x min -> y min -> y pixel max (placed in 2nd coordinate) transpose, then affmap
  ///       - 1st coordinate : x max -> y max -> y pixel min (placed in 2nd coordinate) transpose, then affmap
  ///       - 2nd coordinate : y min -> x min -> x pixel min (placed in 1st coordinate) transpose, then affmap
  ///       - 2nd coordinate : y max -> x max -> x pixel max (placed in 1st coordinate) transpose, then affmap
  ///
  ///     -  Example: AxisLineContainer FOR Y AXIS LINE : we define a HORIZONTAL line, which draws VERTICAL line
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
  PointOffset affmapToPixelsMaybeTransposeInContextOf({
    required ChartOrientation        chartOrientation,
    required BoxContainerConstraints constraintsOnParentLayouter,
    required Interval                inputDataRange,
    required Interval                outputDataRange,
    required double                  sizerHeight,
    required double                  sizerWidth,
  }) {
    // No-op rename input params to shorted version.
    BoxContainerConstraints constraints = constraintsOnParentLayouter;
    ChartOrientation orientation = chartOrientation;

    // Based on orientation, define horizontalPixelsRange, verticalPixelsRange
    //
    // Create 4 ToPixelsLTransform1D instances for data range transforms;
    //   their methods [apply] and [applyOnlyLinearScale] will become elements
    //   of the Functional transformation matrices.
    // The XX and YY versions are used in column orientation, which does not swap X and Y;
    // The XY and YX versions are used in row    orientation, which swaps X and Y before
    //
    // Create 4 functional matrices (2 in each switch section), with function elements that correspond
    //   to how the affineTransform should work
    //     for column, affineTransformer = Matrix.affineTransformer
    //                   (transf00.apply, transf11.apply, rest Functional.identity)
    //     for column, linearTransformer = Matrix.linearTransformer
    //                   (transf00.applyOnlyLinearScale, transf11.applyOnlyLinearScale, rest Functional.identity)
    //     for transf, affineTransformer = Matrix.transposeThenAffineTransformer(transposeAroundDiagonal: Diagonal.leftToRightUp-others exception)
    //                   (transf10.apply, transf01.apply, rest Functional identity)
    //     for row,    linearTransformer = Matrix.transposeThenLinearTransformer(transposeAroundDiagonal: Diagonal.leftToRightUp-others exception)
    //                   (transf10.applyOnlyLinearScale, transf01.applyOnlyLinearScale, rest Functional identity)

    // Transforms values between ranges using affmap `scale * x + shift`. May switch X and Y before transform
    FunctionalMatrix2D affineTransformer;
    // Transforms lengths between ranges using linear `scale * x`.  May switch X and Y before transform
    FunctionalMatrix2D linearTransformer;
    // Zero transform.
    DoubleToDoubleFunction zero = Functional.zero().fun;

    // Horizontal and vertical pixels ranges to which we transform come from Constraints or Sizer,
    //   depending on orientation.
    // Need them to survive switch, as, in the orientation cross-direction, the unscaled-divided-constraint
    //   bar length is used, see [barPointRectSize] at the end of this method.
    Interval horizontalPixelsRange, verticalPixelsRange;

    switch (orientation) {
      case ChartOrientation.column:
        horizontalPixelsRange = Interval(0.0, constraints.width);
        verticalPixelsRange   = Interval(0.0, sizerHeight); // NOT inverted range - pixels are within some container!!

        // Used for orientation.column
        //   m[0,0] (in->px)
        var transfXX = ToPixelsAffineMap1D(
          fromValuesRange: inputDataRange,
          toPixelsRange: horizontalPixelsRange,
          isFlipToRange: false,
        );

        //   m[1,1] (out->py)
        var transfYY = ToPixelsAffineMap1D(
          fromValuesRange: outputDataRange,
          toPixelsRange: verticalPixelsRange,
          isFlipToRange: true,
        );

        // affineTransformer: identity x -> x, y -> y,
        //   followed by affine coordinates transfer: x -> ax + b, y -> cx + d)
        affineTransformer = FunctionalMatrix2D([
          [transfXX.apply, zero],
          [zero,           transfYY.apply],
        ]);
        linearTransformer = FunctionalMatrix2D([
          [transfXX.applyOnlyLinearScale, zero],
          [zero,                          transfYY.applyOnlyLinearScale],
        ]);

        break;
      case ChartOrientation.row:
        horizontalPixelsRange = Interval(0.0, sizerWidth);
        verticalPixelsRange   = Interval(0.0, constraints.height);

        // todo-013 : the doInvert true/false seems INCORRECTLY reversed but RESULT OK. Why?

        // Used for orientation.row
        //   m[1,0] (in->py)
        var transfXY = ToPixelsAffineMap1D(
          fromValuesRange: inputDataRange,
          toPixelsRange: verticalPixelsRange,
          isFlipToRange: false,
        );
        //   m[0,1] (out->px)
        var transfYX = ToPixelsAffineMap1D(
          fromValuesRange: outputDataRange,
          toPixelsRange: horizontalPixelsRange,
          isFlipToRange: true,
        );

        // affineTransformer: transpose around Diagonal.LeftToRightUp (coordinates transfer: x -> y, y -> x),
        //   followed by coordinates affmap: x -> ax + b, y -> cx + d)
        affineTransformer = FunctionalMatrix2D([
          [zero,           transfYX.apply],
          [transfXY.apply, zero ],
        ]);
        linearTransformer = FunctionalMatrix2D([
          [zero,                          transfYX.applyOnlyLinearScale],
          [transfXY.applyOnlyLinearScale, zero ],
        ]);

        break;
    }

    // Transform this point with the affine transformer, and it's presented rectangle Size with the linear transformer.
    Vector<double> thisToVector = toVector();
    PointOffset pointOffsetPixels = PointOffset.fromVector(affineTransformer.applyOnVector(thisToVector));
    Size barPointRectSize = SizeExtension.fromVector(linearTransformer.applyOnVector(thisToVector).abs());
    // On the rect size, we do NOT scale both directions. In the direction where constraint
    //   is used (which is ALWAYS the orientation main axis), use scaled size, BUT in the cross direction,
    //   use the full size coming from the divided constraint
    pointOffsetPixels.barPointRectSize = barPointRectSize.fromMySideAlongPassedAxisOtherSideAlongCrossAxis(
      other: Size(horizontalPixelsRange.max, verticalPixelsRange.max),
      axis: orientation.mainLayoutAxis,);

    return pointOffsetPixels;
  }

  /// Present itself as code
  String asCodeConstructor() {
    return 'PointOffset('
        'inputValue: $inputValue,'
        'outputValue: $outputValue,'
        ')';
  }
}

/// Identifies a diagonal for transpose transfer.
///
/// [leftToRightUp] identifies the diagonal around which a coordinate system would
/// rotate to get from a vertical bar chart to a horizontal bar chart.
// todo-014 : move to an enum file - representing geometry
enum Diagonal {
  leftToRightDown,
  leftToRightUp,
}

/* KEEP : Old version of PointOffset affmap
  PointOffset affmapToPixelsMaybeTransposeInContextOfOLD({
    required ChartOrientation  chartOrientation,
    required BoxContainerConstraints constraintsOnParentLayouter,
    required Interval                inputDataRange,
    required Interval                outputDataRange,
    required double                  sizerHeight,
    required double                  sizerWidth,
  }) {
    ChartOrientation orientation = chartOrientation;
    BoxContainerConstraints constraints = constraintsOnParentLayouter;

    double horizontalPixels = 0.0;
    double verticalPixels = 0.0;


    // Width and height of the bar rectangle in pixels.
    // The bar rectangle represents this point on bar chart.
    double barPointRectWidth, barPointRectHeight;

    switch (orientation) {
      case ChartOrientation.column:
        // 1.1.1:
        // KEEP : var horizontalPixelsRange   = Interval(0.0, isAffmapUseSizerInsteadOfConstraint ? sizerWidth : constraints.width);
        var horizontalPixelsRange   = Interval(0.0, constraints.width);

        var horizontalValuePixels = _affmapFromValueToPixelsOnSameAxisOLD(
          fromValue: inputValue,
          fromValuesRange: inputDataRange,
          toPixelsRange: horizontalPixelsRange,
          doInvertRange: false,
        );
        horizontalPixels = horizontalValuePixels.pixelPositionForValue;

        // 1.2.1:
        var verticalPixelsRange   = Interval(0.0, sizerHeight); // NOT inverted range - pixels are within some container!!

        var verticalValuePixels    = _affmapFromValueToPixelsOnSameAxisOLD(
          fromValue: outputValue,
          fromValuesRange: outputDataRange,
          toPixelsRange: verticalPixelsRange,
          doInvertRange: true,
        );
        verticalPixels =  verticalValuePixels.pixelPositionForValue;

        // Width and height of the rectangle layoutSize
        barPointRectWidth  = horizontalPixelsRange.length;
        barPointRectHeight = verticalValuePixels.pixelLengthForValue;

        break;
      case ChartOrientation.row:
        // Transpose all points in chart around [Diagonal.leftToRightUp].
        // This changes the chart from vertical bar chart to horizontal bar chart.
        // Transform 1 : iotrp transform: (in, out) -> (iotrpIn=out, iotrpOut=in)

        // 1.2.2:
        // Transform 2 : iotrpOut -> pixels on vertical y axis (verticalPixels)
        // KEEP: var verticalPixelsRange   = Interval(0.0, isAffmapUseSizerInsteadOfConstraint ? sizerHeight : constraints.height);
        var verticalPixelsRange   = Interval(0.0, constraints.height);

        var verticalValuePixels = _affmapFromValueToPixelsOnSameAxisOLD(
          fromValue: inputValue,
          fromValuesRange: inputDataRange,
          toPixelsRange: verticalPixelsRange,
          doInvertRange: false,
        );
        verticalPixels = verticalValuePixels.pixelPositionForValue;

        // 1.1.2:
        // Transform 2 : iotrpIn -> pixels on horizontal x axis (horizontalPixels)
        var horizontalPixelsRange   = Interval(0.0, sizerWidth);

        var horizontalValuePixels = _affmapFromValueToPixelsOnSameAxisOLD(
          fromValue: outputValue,
          fromValuesRange: outputDataRange,
          toPixelsRange: horizontalPixelsRange,
          doInvertRange: true,
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

  /// Affmap [fromValue] assumed to be in the [fromValuesRange], to pixels in range [toPixelsRange],
  /// possibly inverting the ranges by setting [doInvertRange].
  ///
  ///
  _ValuePixels _affmapFromValueToPixelsOnSameAxisOLD({
    required double   fromValue,
    required Interval fromValuesRange,
    required Interval toPixelsRange,
    required bool     doInvertRange,
  }) {
    assert (toPixelsRange.min == 0.0);

    var transform = ToPixelsLTransform1D(
        fromValues: Interval(fromValuesRange.min, fromValuesRange.max),
        toPixels:   Interval(toPixelsRange.min, toPixelsRange.max),
        isFlipToRange: doInvertRange,
    );
    double pixelPositionForValue, pixelLengthForValue;
    pixelPositionForValue = transform.apply(fromValue);
    pixelLengthForValue = transform.applyOnlyLinearScale(fromValue).abs();

    return _ValuePixels(pixelPositionForValue, pixelLengthForValue);
  }

class _ValuePixels {
  _ValuePixels(this.pixelPositionForValue, this.pixelLengthForValue);
  final double pixelPositionForValue;
  final double pixelLengthForValue;
}

*/

