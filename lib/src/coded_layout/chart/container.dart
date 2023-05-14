import 'dart:ui' as ui show Size, Offset, Canvas;
import 'package:logger/logger.dart' as logger;

// this level or equivalent
import 'axis_container.dart';
import 'data_container.dart';
import '../../chart/container/container_common.dart';
import '../../chart/container/root_container.dart';
import '../../chart/container/legend_container.dart';
import '../../chart/container/data_container.dart';
import '../../chart/model/data_model.dart';
import '../../chart/view_model.dart';
import '../../morphic/container/container_layouter_base.dart'
    show BoxContainer, BoxLayouter, LayoutableBox;
import 'presenter.dart';
import '../../util/util_dart.dart';
import '../../chart/model/label_model.dart';
import '../../util/collection.dart' as custom_collection show CustomList;
import '../../morphic/container/constraints.dart' show BoxContainerConstraints;

/// See [ChartRootContainer].
abstract class ChartRootContainerCL extends ChartAreaContainer implements ChartRootContainer {

  /// Simple Legend+X+Y+Data Container for a flutter chart.
  ///
  /// The simple flutter chart layout consists of only 2 major areas:
  /// - [VerticalAxisContainerCL] area manages and lays out the Y labels area, by calculating
  ///   sizes required for Y labels (in both X and Y direction).
  ///   The [VerticalAxisContainerCL]
  /// - [HorizontalAxisContainerCL] area manages and lays out the
  ///   - X labels area, and the
  ///   - grid area.
  /// In the X direction, takes up all space left after the
  /// VerticalAxisContainer layes out the  Y labels area, that is, full width
  /// minus [VerticalAxisContainerCL.yLabelsContainerWidth].
  /// In the Y direction, takes
  /// up all available chart area, except a top horizontal strip,
  /// required to paint half of the topmost label.
  ChartRootContainerCL({
    required this.legendContainer,
    required this.horizontalAxisContainer,
    required this.verticalAxisContainer,
    required this.verticalAxisContainerFirst,
    required this.dataContainer,
    required ChartViewModel chartViewModel,
  })  : super(chartViewModel: chartViewModel) {
    logger.Logger().d('    Constructing ChartRootContainer');
    // Attach children passed in constructor, previously created in view model, to self
    addChildren([legendContainer, horizontalAxisContainer, verticalAxisContainer, dataContainer]);
  }

  /// Override [BoxContainerHierarchy.isRoot] to prevent checking this root container on parent,
  /// which is never set on instances of this [ChartRootContainerCL].
  @override
  bool get isRoot => true;

  /// Number of columns in the [DataContainerCL].

  /// Base Areas of chart. In some sections of legacy coded_layout code, may need cast to their CL versions.
  @override
  late LegendContainer legendContainer;
  @override
  late HorizontalAxisContainerCL horizontalAxisContainer;
  @override
  late VerticalAxisContainerCL verticalAxisContainer;
  @override
  late VerticalAxisContainerCL verticalAxisContainerFirst;
  @override
  late DataContainerCL dataContainer;

  // ##### Methods sharing information between child containers - HorizontalAxisContainer and VerticalAxisContainer Source to DataContainer Sink

  double get xGridStep => horizontalAxisContainer.xGridStep;

  /// X coordinates of x ticks (x tick - middle of column, also middle of label).
  /// Once [HorizontalAxisContainerCL.layout] and [VerticalAxisContainerCL.layout] are complete,
  /// this list drives the layout of [DataContainerCL].
  ///
  /// xTickX are calculated from labels [InputLabelContainer]s, and used late in the
  ///  layout and painting of the DataContainer in ChartContainer.
  ///
  /// See [AxisLabelContainer.parentOffsetTick] for details.
  List<double> get xTickXs =>
      horizontalAxisContainer.inputLabelContainerCLs.map((var inputLabelContainer) => inputLabelContainer.parentOffsetTick).toList();

  /// Y coordinates of y ticks (y tick - extrapolated value of data, also middle of label).
  /// Once [HorizontalAxisContainerCL.layout] and [VerticalAxisContainerCL.layout] are complete,
  /// this list drives the layout of [DataContainerCL].
  ///
  /// See [AxisLabelContainer.parentOffsetTick] for details.
  List<double> get yTickYs => verticalAxisContainer.outputLabelContainerCLs.map((var outputLabelContainer) => outputLabelContainer.parentOffsetTick).toList();


  // ##### Methods for layout and paint

  /// Overrides [BoxLayouter.layout] for the chart as a whole.
  ///
  /// Uses this container's [chartArea] as available size
  ///
  /// Note: The [chartArea] was set in the [ChartPainter.paint(Canvas, Size)]
  /// just before calling this method:
  ///
  /// ```dart
  ///   void paint(ui.Canvas canvas, ui.Size size) {
  ///     ...
  ///     container.chartArea = size;
  ///     container.layout();
  ///     ...
  /// ```
  ///
  /// Layout proceeds extrapolating the Y values to fit the available size,
  /// then lays out the legend, Y axis and labels, X axis and labels,
  /// and the data area, giving each the size it needs.
  ///
  /// The actual layout algorithm should be made pluggable.
  ///
  @override
  void layout() {
    buildAndReplaceChildren();

    // ####### 1. Layout the LegendContainer where series legend is shown
    var legendBoxConstraints = BoxContainerConstraints.insideBox(size: ui.Size(
      constraints.width,
      constraints.height,)
    );

    legendContainer.applyParentConstraints(this, legendBoxConstraints);
    legendContainer.layout();

    ui.Size legendContainerSize = legendContainer.layoutSize;
    ui.Offset legendContainerOffset = ui.Offset.zero;
    legendContainer.applyParentOffset(this, legendContainerOffset);

    // ####### 2. Layout [verticalAxisContainerFirst] to get Y container width
    //        that moves [HorizontalAxisContainer] and [DataContainer].
    double verticalAxisContainerFirstHeight = constraints.height - legendContainerSize.height;
    var verticalAxisContainerFirstBoxConstraints =  BoxContainerConstraints.insideBox(size: ui.Size(
      constraints.width,
      verticalAxisContainerFirstHeight,
    ));

    // Note: verticalAxisContainerFirst used to be created here as  VerticalAxisContainer( chartViewModel: chartViewModel, yLabelsMaxHeightFromFirstLayout: 0.0
    //       verticalAxisContainerFirst._parent, checked in applyParentConstraints => assertCallerIsParent
    //       is not yet set here, as verticalAxisContainerFirst never goes through addChildren which sets _parent on children.
    //       so _parent cannot be late final.
    verticalAxisContainerFirst.applyParentConstraints(this, verticalAxisContainerFirstBoxConstraints);
    verticalAxisContainerFirst.layout();

    verticalAxisContainer.yLabelsMaxHeightFromFirstLayout = verticalAxisContainerFirst.yLabelsMaxHeight;
    // ####### 3. HorizontalAxisContainer: Given width of VerticalAxisContainerFirst, constraint, then layout HorizontalAxisContainer

    ui.Size verticalAxisContainerFirstSize = verticalAxisContainerFirst.layoutSize;

    // horizontalAxisContainer layout width depends on verticalAxisContainerFirst layout result.  But this dependency can be expressed
    // as a constraint on horizontalAxisContainer, so no need to implement [findSourceContainersReturnLayoutResultsToBuildSelf]
    var horizontalAxisContainerBoxConstraints =  BoxContainerConstraints.insideBox(size: ui.Size(
      constraints.width - verticalAxisContainerFirstSize.width,
      constraints.height - legendContainerSize.height,
    ));

    horizontalAxisContainer.applyParentConstraints(this, horizontalAxisContainerBoxConstraints);
    horizontalAxisContainer.layout();

    // When we got here, horizontalAxisContainer layout is done, so set the late final layoutSize after re-layouts
    horizontalAxisContainer.layoutSize = horizontalAxisContainer.lateReLayoutSize;

    ui.Size horizontalAxisContainerSize = horizontalAxisContainer.layoutSize;
    ui.Offset horizontalAxisContainerOffset = ui.Offset(verticalAxisContainerFirstSize.width, constraints.height - horizontalAxisContainerSize.height);
    horizontalAxisContainer.applyParentOffset(this, horizontalAxisContainerOffset);

    // ####### 4. [VerticalAxisContainer]: The actual VerticalAxisContainer layout is needed, as height constraint for Y container
    //          is only known after HorizontalAxisContainer layedout inputUserLabels.  VerticalAxisContainer expands down to top of horizontalAxisContainer.
    //          The [yLabelsMaxHeightFromFirstLayout] is used to extrapolate data values to the y axis,
    //          and put labels on ticks.

    // verticalAxisContainer layout height depends on horizontalAxisContainer layout result.  But this dependency can be expressed
    // as a constraint on verticalAxisContainer, so no need to implement [findSourceContainersReturnLayoutResultsToBuildSelf]
    var yConstraintsHeight = constraints.height - legendContainerSize.height - horizontalAxisContainerSize.height;
    var verticalAxisContainerBoxConstraints = BoxContainerConstraints.insideBox(size: ui.Size(
      constraints.width,
      yConstraintsHeight,
    ));

    verticalAxisContainer.applyParentConstraints(this, verticalAxisContainerBoxConstraints);
    verticalAxisContainer.layout();

    var verticalAxisContainerSize = verticalAxisContainer.layoutSize;
    // The layout relies on VerticalAxisContainer width first time and second time to be the same, as width
    //    was used as remainder space for HorizontalAxisContainer.
    // But height, will NOT be the same, it will be shorter second time.
    assert (verticalAxisContainerFirstSize.width == verticalAxisContainerSize.width);
    ui.Offset verticalAxisContainerOffset = ui.Offset(0.0, legendContainerSize.height);
    verticalAxisContainer.applyParentOffset(this, verticalAxisContainerOffset);

    ui.Offset dataContainerOffset;

    // ### 6. Layout the data area, which included the grid
    // by calculating the X and Y positions of grid.
    // This must be done after X and Y are layed out - see xTickXs, yTickYs.
    // The [verticalAxisContainer] internals and [verticalAxisContainerSize] are both needed to offset and constraint the [dataContainer].
    BoxContainerConstraints dataContainerBoxConstraints;
    dataContainerBoxConstraints = BoxContainerConstraints.insideBox(
        size: ui.Size(
          constraints.width - verticalAxisContainerSize.width,
          yConstraintsHeight, // Note: = constraints.height - legendContainerSize.height - horizontalAxisContainerSize.height,
        ));
    dataContainerOffset = ui.Offset(verticalAxisContainerSize.width, legendContainerSize.height);

    dataContainer.applyParentConstraints(this, dataContainerBoxConstraints);
    dataContainer.layout();
    dataContainer.applyParentOffset(this, dataContainerOffset);
  }

  /// Implements abstract [paint] for the whole chart container hierarchy, the [ChartRootContainerCL].
  /// Paints the chart on the passed [canvas], limited to the [size] area,
  /// which must be set before invoking this [paint] method.
  ///
  /// Called from the chart's painter baseclass, the [ChartPainter], which
  /// [paint(Canvas, Size)] is guaranteed to be called by the Flutter framework
  /// (see class comment), hence [ChartPainter.paint] starts the chart painting.
  ///
  /// In detail, this method paints all elements of the chart - the legend in [_paintLegend],
  /// the grid in [drawGrid], the x/y labels in [_paintXLabels] and [_paintYLabels],
  /// and the data values, column by column, in [drawDataPointPresentersColumns].
  ///
  /// Before the actual canvas painting, at the beginning of this method,
  /// this class's [layout] is performed, which recursively lays out all member [BoxContainer]s.
  /// Once this top container is layed out, the [paint] is called on all
  /// member [BoxContainer]s ([VerticalAxisContainerCL],[HorizontalAxisContainerCL] etc),
  /// which recursively paints the leaf [BoxContainer]s lines, rectangles and circles
  /// in their calculated layout positions.
  @override
  void paint(ui.Canvas canvas) {

    // Draws the Y labels area of the chart.
    verticalAxisContainer.paint(canvas);
    // Draws the X labels area of the chart.
    horizontalAxisContainer.paint(canvas);
    // Draws the legend area of the chart.
    legendContainer.paint(canvas);
    // Draws the grid, then data area - bars (bar chart), lines and points (line chart).
    dataContainer.paint(canvas);

    // clip canvas to size - this does nothing
    // todo-1: THIS canvas.clipRect VVVV CAUSES THE PAINT() TO BE CALLED AGAIN. WHY??
    // canvas.clipRect(const ui.Offset.zero & size); // Offset & Size => Rect
  }

}

mixin PixelRangeProvider on ChartAreaContainer {

  /// Late calculated minimum and maximum pixels for the Y axis WITHIN the [AxisContainerCL].
  ///
  /// The [axisPixelsRange] has several important properties and roles:
  ///   1. It contains the pixels of this [AxisContainerCL]
  ///      available to the axis. Because this [AxisContainerCL] is generally bigger than the axis pixels,
  ///      this range generally does NOT generally start at zero and end below the pixels available
  ///      to the [AxisContainerCL], as follows:
  ///      - For the [VerticalAxisContainerCL], the [axisPixelsRange]  start after a half-label height is excluded on the top,
  ///        and a vertical tick height is excluded on the bottom.
  ///      - For the [HorizontalAxisContainerCL], the [axisPixelsRange] is currently UNUSED.
  ///
  ///  2. The difference between [axisPixelsRange] min and max is the height constraint
  ///     on [DataContainer]!
  ///
  ///   3. If is the interval to which the axis data values, stored in [labelsGenerator]'s
  ///      member [DataRangeLabelInfosGenerator.dataRange] should be extrapolated.
  ///
  /// Important note: Cannot be final, because, if on HorizontalAxisContainer, the [layout] code where
  ///                 this is set may be called multiple times.
  late Interval axisPixelsRange;
}

/// Represents one Y numeric value in the [ChartModel.dataRows],
/// with added information about the X coordinate (display coordinate).
///
/// Instances are stacked if [isStacked] is true.
///
/// The members can be grouped in three groups.
///
/// 1. The [xLabel], [valuesRowIndex] and [predecessorPoint] are initial variables along with [dataY].
///
/// 2. The [fromY] and [toY] and [dataY] are data-values representing this point's numeric value.
///   *This group's members do NOT change under [applyParentOffset] as they represent data, not coordinates;*
///   they must not change with container (display) size change.
///   - In addition, the [fromY] and [toY] are stacked, [dataY] is NOT stacked. Stacking is achieved by adding
///   the values of [dataY] from the bottom of the stacked values to this point,
///   by calling the [stackOnAnother] method.
///
/// 3. The [scaledFrom] and [scaledTo] type [ui.Offset] are extrapolated-coordinates -
///   represent members from group 2, extrapolated to the container coordinates (display coordinates).
///   *This group's members DO change under [applyParentOffset] as they represent coordinates.*
///
/// Stacking management:
/// - This object does not manage it's stacking,
///   stacking is delegated to the container that manages this object along with
///   values before (below) and after (above). The managing object is [PointsColumn].
class StackableValuePoint {

  /// The generative constructor of objects for this class.
  StackableValuePoint({
    required this.xLabel,
    required this.dataY,
    required this.valuesRowIndex,
    required this.chartViewModel,
    this.predecessorPoint,
  })  : isStacked = false,
        fromY = 0.0,
        toY = dataY;

  // ################## Members ###################
  // ### Group 0: Structural

  /// Root container added to access verticalAxisContainer.axisPixels min / max
  late final ChartViewModel chartViewModel;

  // ### 1. Group 1, initial values, but also includes [dataY] in group 2

  late final String xLabel;

  /// The transformed but NOT stacked Y data value.
  /// **ANY [dataYs] are 1. transformed, then 2. potentially stacked IN PLACE, then 3. potentially extrapolated IN A COPY!!**
  late final double dataY;

  /// The index of this point in the [PointsColumn] containing this point in it's
  /// [PointsColumn.stackableValuePoints] list.
  late final int valuesRowIndex; // series index

  /// The predecessor point in the [PointsColumn] containing this point in it's [PointsColumn.stackableValuePoints] list.
  StackableValuePoint? predecessorPoint;

  /// True if data are stacked.
  bool isStacked = false;

  // ### 2. Group 2, are data-values representing this point's numeric value.
  /// The stacked-data-value where this point's Y value starts.
  /// Created, along with [toY] as follows:
  /// ```dart
  ///    fromY = predecessorPoint != null ? predecessorPoint!.toY : 0.0;
  ///     toY = fromY + dataY;
  /// ```
  /// This value is NOT coordinate based, so [applyParentOffset] is never applied to it.
  double fromY;

  /// The stacked-data-value where this point's Y value ends.
  /// See [fromY] for details.
  double toY;

  // ### 3. Group 3, are the extrapolated-coordinates - copy-converted from members from group 2,
  //        by extrapolating group 2 members to the container coordinates (display coordinates)

  /// The [scaledFrom] and [scaledTo] are the pixel (extrapolated) coordinates
  /// of (possibly stacked) data values in the [ChartRootContainerCL] coordinates.
  /// They are positions used by [PointPresenter] to paint the 'widget'
  /// that represents the (possibly stacked) data value.
  ///
  /// Initially extrapolated to available pixels on the Y axis,
  /// then moved by positioning by [applyParentOffset].
  ///
  /// In other words, they hold offsets of the bottom and top of the [PointPresenter] of this
  /// data value point.
  ///
  /// For example, for VerticalBar, [scaledFrom] is the bottom left and
  /// [scaledTo] is the top right of each bar representing this value point (data point).
  ui.Offset scaledFrom = ui.Offset.zero;

  /// See [scaledFrom].
  ui.Offset scaledTo = ui.Offset.zero;

  StackableValuePoint stack() {
    isStacked = true;

    // todo-1 validate: check if both points y have the same sign or both zero
    fromY = predecessorPoint != null ? predecessorPoint!.toY : 0.0;
    toY = fromY + dataY;

    return this;
  }

  /// Stacks this point on top of the passed [predecessorPoint].
  ///
  /// Points are constructed unstacked. Depending on chart type,
  /// a later processing can stack points using this method
  /// (if chart type is [ChartRootContainerCL.isStacked].
  StackableValuePoint stackOnAnother(StackableValuePoint? predecessorPoint) {
    this.predecessorPoint = predecessorPoint;
    return stack();
  }

  /// Scales this point to the container coordinates (display coordinates).
  ///
  /// More explicitly, extrapolates the data-members of this point to the said coordinates.
  ///
  /// See class documentation for which members are data-members and which are extrapolated-members.
  ///
  /// Note that the x values are not really extrapolated, as object does not
  /// manage the not-extrapolated [x] (it manages the corresponding label only).
  /// For this reason, the [scaledX] value must be *already extrapolated*!
  /// The provided [scaledX] value should be the
  /// "within [ChartPainter] absolute" x coordinate (generally the center
  /// of the corresponding x label).
  ///
  StackableValuePoint affmapToPixels({
    required double scaledX,
    required DataRangeLabelInfosGenerator outputLabelsGenerator,
  }) {
    // Scales fromY of from the OLD [ChartData] BUT all the extrapolating ranges in outputLabelsGenerator
    // were calculated using the NEW [ChartModel]

    VerticalAxisContainerCL verticalAxisContainerCL = chartViewModel.chartRootContainer.verticalAxisContainer as VerticalAxisContainerCL;
    double axisPixelsYMin = verticalAxisContainerCL.axisPixelsRange.min;
    double axisPixelsYMax = verticalAxisContainerCL.axisPixelsRange.max;

    scaledFrom = ui.Offset(
      scaledX,
      outputLabelsGenerator.affmapValueToPixels(
        value: fromY,
        axisPixelsMin: axisPixelsYMin,
        axisPixelsMax: axisPixelsYMax,
      ),
    );
    scaledTo = ui.Offset(
      scaledX,
      outputLabelsGenerator.affmapValueToPixels(
        value: toY,
        axisPixelsMin: axisPixelsYMin,
        axisPixelsMax: axisPixelsYMax,
      ),
    );

    return this;
  }

  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    // only apply  offset on extrapolated values, those have chart coordinates that are painted.

    // not needed to offset : StackableValuePoint predecessorPoint;

    /// Scaled values represent screen coordinates, apply offset to all.
    scaledFrom += offset;
    scaledTo += offset;
  }

  /// Copy - clone of this object unstacked. Does not allow to clone if
  /// already stacked.
  ///
  /// Returns a new [StackableValuePoint] which is a full deep copy of this
  /// object. This includes cloning of [double] type members and [ui.Offset]
  /// type members.
  StackableValuePoint unstackedClone() {
    if (isStacked) {
      throw Exception('Cannot unstackedClone if already stacked');
    }

    StackableValuePoint unstackedClone = StackableValuePoint(
      chartViewModel: chartViewModel,
      xLabel: xLabel,
      dataY: dataY,
      valuesRowIndex: valuesRowIndex,
      predecessorPoint: predecessorPoint,
    );

    // nullify the predecessor Anything that we change here must not be final
    unstackedClone.predecessorPoint = null;
    unstackedClone.fromY = fromY;
    unstackedClone.toY = toY;
    unstackedClone.scaledFrom = ui.Offset(scaledFrom.dx, scaledFrom.dy);
    unstackedClone.scaledTo = ui.Offset(scaledTo.dx, scaledTo.dy);

    return unstackedClone;
  }
}

/// Represents a column of [StackableValuePoint]s, with support for both stacked and Not-Stacked charts.
///
/// Corresponds to one column of data from [ChartModel.dataRows], ready for presentation by [PointPresenter]s.
///
/// The
/// - unstacked (such as in the line chart),  in which case it manages
///   [stackableValuePoints] that have values from [ChartModel.dataRows].
/// - stacked (such as in the bar chart), in which case it manages
///   [stackableValuePoints] that have values added up from [ChartModel.dataRows].
///
/// Negative and positive points must be stacked separately,
/// to support correctly displayed stacked values above and below zero.
class PointsColumn {
  /// List of charted values in this column
  late List<StackableValuePoint> stackableValuePoints;

  /// List of stacked positive or zero value points - support for stacked type charts,
  /// where negative and positive points must be stacked separately,
  /// above and below zero.
  late List<StackableValuePoint> stackedPositivePoints; // not-negative actually

  /// List of stacked negative value points - support for stacked type charts,
  /// where negative and positive points must be stacked separately,
  /// above and below zero.
  late List<StackableValuePoint> stackedNegativePoints;

  PointsColumn? nextRightPointsColumn;

  /// Construct column from the passed [points].
  ///
  /// Passed points are assumed to:
  /// - Be configured with appropriate [predecessorPoint]
  /// - Not stacked
  /// Creates members [stackedNegativePoints], [stackedPositivePoints]
  /// which exist only to be stacked, so the constructor stacks them
  /// on creation.
  PointsColumn({
    required List<StackableValuePoint> points,
  }) {
    // todo-1 add validation that points are not stacked
    stackableValuePoints = points;

    stackedPositivePoints =
        _selectThenCollectStacked(points: stackableValuePoints, selector: (point) => point.dataY >= 0);
    stackedNegativePoints =
        _selectThenCollectStacked(points: stackableValuePoints, selector: (point) => point.dataY < 0);
  }

  //// points are ordered in series order, first to last  (bottom to top),
  //// and maintain their 0 based row (series) index
  List<StackableValuePoint> _selectThenCollectStacked({
    required List<StackableValuePoint> points,
    required bool Function(StackableValuePoint point) selector,
  }) {
    StackableValuePoint? predecessorPoint;
    List<StackableValuePoint> selected = stackableValuePoints.where((point) {
      return selector(point);
    }) // point.y >= 0;
        .map((point) {
      var thisPoint = point.unstackedClone().stackOnAnother(predecessorPoint);
      predecessorPoint = thisPoint;
      return thisPoint;
    }).toList();
    return selected;
  }

  /// Column Utility for iterating over all points in order
  Iterable<StackableValuePoint> allPoints() {
    return [
      ...stackableValuePoints,
      ...stackedNegativePoints,
      ...stackedPositivePoints,
    ];
  }
}

/// A list of [PointsColumn] instances, created from user data rows [ChartModel.dataRows].
///
/// Represents the chart data created from the [ChartModel.dataRows], but is an internal format suitable for
/// presenting by the chart [PointPresenter] instances.
///
/// Passed to the [PointPresenter] instances, which use this instance's data to
/// paint the values in areas above the labels in the appropriate presentation (point and line chart, column chart, etc).
///
/// Manages value point structure as column based (currently supported) or row based (not supported).
///
/// A (single instance per chart) is used to create a [PointPresentersColumns] instance, managed in the [DataContainerCL].
// todo-04-note : PointsColumns IS A MODEL, NOT PRESENTER :
//                 Convert to BoxContainer, add 1) _createChildrenOfPointsColumns 2) buildAndReplaceChildren 3) layout
//                 Each PointsColumn is a child in children.
class PointsColumns extends custom_collection.CustomList<PointsColumn> {
  /// Parent chart container.
  final ChartViewModel chartViewModel;

  /// True if chart type presents values stacked.
  final bool _isStacked;

  final LayoutableBox _caller;

  /// Constructor creates a [PointsColumns] instance from [ChartModel.dataRows] values in
  /// the passed [chartViewModel.outerChartModel].
  PointsColumns({
    required this.chartViewModel,
    required PointPresenterCreator pointPresenterCreator,
    required bool isStacked,
    required LayoutableBox caller,
  })  : _isStacked = isStacked,
        _caller = caller,
        super(growable: true) {
    _createStackableValuePointsFromChartModel(chartViewModel.chartModelInLegacy);
  }

  /// Constructs internals of this object, the [PointsColumns].
  ///
  /// Transposes data passed as rows in [chartModel] member [ChartModel.dataRows]
  /// to [_valuePointArrInRows] and to [_valuePointArrInColumns].
  ///
  /// Creates links on "this column" to "successor in stack on the right",
  /// managed in [PointsColumn.nextRightPointsColumn].
  ///
  /// Each element is the per column point below the currently processed point.
  /// The currently processed point is (potentially) stacked on it's predecessor.
  void _createStackableValuePointsFromChartModel(ChartModel chartModel) {
    List<StackableValuePoint?> rowOfPredecessorPoints =
        List.filled(chartModel.dataRows[0].length, null);
    for (int col = 0; col < chartModel.dataRows[0].length; col++) {
      rowOfPredecessorPoints[col] = null; // new StackableValuePoint.initial(); // was:null
    }

    // Data points managed row.  Internal only, should be refactored away.
    List<List<StackableValuePoint>> valuePointArrInRows = List.empty(growable: true);

    for (int row = 0; row < chartModel.dataRows.length; row++) {
      List<num> valuesRow = chartModel.dataRows[row];
      List<StackableValuePoint> pointsRow = List<StackableValuePoint>.empty(growable: true);
      valuePointArrInRows.add(pointsRow);
      for (int col = 0; col < valuesRow.length; col++) {
        // yTransform data before placing data point on StackableValuePoint.
        num colValue = chartViewModel.chartOptions.dataContainerOptions.yTransform(valuesRow[col]);

        // Create all points unstacked. A later processing can stack them,
        // depending on chart type. See [StackableValuePoint.stackOnAnother]
        var thisPoint = StackableValuePoint(
            chartViewModel: chartViewModel,
            xLabel: 'initial',
            dataY: colValue.toDouble(),
            valuesRowIndex: row,
            predecessorPoint: rowOfPredecessorPoints[col]);

        pointsRow.add(thisPoint); // Grow the row with thisPoint
        rowOfPredecessorPoints[col] = thisPoint;
      }
    }
    valuePointArrInRows.toList();

    // Data points managed column. Internal only, should be refactored away.
    List<List<StackableValuePoint>> valuePointArrInColumns = transposeRowsToColumns(valuePointArrInRows);

    // convert "column oriented" _valuePointArrInColumns
    // to a column, and add the columns to this instance
    PointsColumn? leftColumn;

    for (List<StackableValuePoint> columnPoints in valuePointArrInColumns) {
      var pointsColumn = PointsColumn(points: columnPoints);
      add(pointsColumn);
      leftColumn?.nextRightPointsColumn = pointsColumn;
      leftColumn = pointsColumn;
    }
  }

  /// Scales this object's column values managed in [pointsColumns].
  ///
  /// This allows separation of creating this object with
  /// the original, not-extrapolated data points, and apply extrapolating later
  /// on the stackable (stacked or unstacked) values.
  ///
  /// Notes:
  /// - Iterates this object's internal list of [PointsColumn], then the contained
  ///   [PointsColumn.stackableValuePoints], and extrapolates each point by
  ///   applying its [StackableValuePoint.affmapToPixels] method.
  /// - No extrapolating of the internal representation stored in [_valuePointArrInRows]
  ///   or [_valuePointArrInColumns].
  void affmapPointsColumns(ChartViewModel chartViewModel, ChartRootContainerCL chartRootContainer) {
    int col = 0;
    for (PointsColumn column in this) {
      column.allPoints().forEach((StackableValuePoint point) {
        double scaledX = chartRootContainer.xTickXs[col];
        point.affmapToPixels(
          scaledX: scaledX,
          outputLabelsGenerator: chartViewModel.outputLabelsGenerator,
        );
      });
      col++;
    }
  }

  /// Makes this [PointsColumns] object a [BoxContainer] - like class,
  ///
  /// Offsets the coordinates of this [PointsColumns] kept in [ChartViewModel.chartModel] by the [offset],
  /// assumed invoked from parent [DataContainerCL].
  ///
  /// When called in DataContainer.applyParentOffset with the offset of DataContainer
  ///             dataContainerOffset = ui.Offset(verticalAxisContainerSize.width, legendContainerSize.height);
  ///
  /// it moves all points by the offset of [DataContainerCL] in [ChartRootContainerCL].
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    for (PointsColumn column in this) {
      column.allPoints().forEach((StackableValuePoint point) {
        point.applyParentOffset(_caller, offset);
      });
    }
  }

  List<double> flattenPointsValues() {
    if (_isStacked) return flattenStackedPointsDataYs();

    return flattenUnstackedPointsDataYs();
  }

  /// Flattens values of all unstacked data points.
  ///
  /// Use in containers for unstacked charts (e.g. line chart)
  List<double> flattenUnstackedPointsDataYs() {
    List<double> flat = [];
    for (PointsColumn column in this) {
      for (StackableValuePoint point in column.stackableValuePoints) {
        flat.add(point.toY);
      }
    }
    return flat;
  }

  /// Flattens values of all stacked data points.
  ///
  /// Use in containers for stacked charts (e.g. VerticalBar chart)
  List<double> flattenStackedPointsDataYs() {
    List<double> flat = [];
    for (PointsColumn column in this) {
      for (StackableValuePoint point in column.stackedNegativePoints) {
        flat.add(point.toY);
      }
      for (StackableValuePoint point in column.stackedPositivePoints) {
        flat.add(point.toY);
      }
    }
    return flat;
  }
}
