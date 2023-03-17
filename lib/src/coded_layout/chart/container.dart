import 'dart:ui' as ui show Size, Offset, Rect, Canvas;
import 'dart:math' as math show max;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'package:flutter/widgets.dart' as widgets show TextStyle;
import 'package:logger/logger.dart' as logger;

// this level or equivalent
import 'label_container.dart';
import '../../chart/container/container_common.dart';
import '../../chart/container/root_container.dart';
import '../../chart/container/legend_container.dart';
import '../../chart/container/data_container.dart';
import '../../chart/container/axis_container.dart';
import '../../chart/model/data_model.dart';
import '../../morphic/container/label_container.dart';
import '../../chart/view_maker.dart';
import '../../chart/painter.dart';
import '../../morphic/container/container_layouter_base.dart'
    show BoxContainer, BoxLayouter,
    LayoutableBox;
//import 'container_alignment.dart';
//import 'container_edge_padding.dart';
import 'line_container.dart';
import 'presenter.dart';
import '../../chart/options.dart';
import '../../util/util_dart.dart';
import '../../util/util_labels.dart';
import '../../util/collection.dart' as custom_collection show CustomList;
//import '../container/container_key.dart';
import '../../morphic/container/constraints.dart' show BoxContainerConstraints;
//import '../chart/layouter_one_dimensional.dart';
import '../../chart/iterative_layout_strategy.dart' as strategy;

import '../../switch_view_maker/view_maker_cl.dart';

// extension libraries
import 'line/presenter.dart' as line_presenters;
import 'bar/presenter.dart' as bar_presenters;


/// Abstract class representing the root [BoxContainer] of the whole chart.
///
/// Concrete [ChartRootContainerCL] instance is created new on every [FlutterChartPainter.paint] invocation
/// in the [ChartViewMaker.chartRootContainerCreateBuildLayoutPaint]. Note that [ChartViewMaker]
/// instance is created only once per chart, NOT recreated on every [FlutterChartPainter.paint] invocation.
///
/// Child containers calculate coordinates of chart points
/// used for painting grid, labels, chart points etc.
///
/// The lifecycle of [ChartRootContainerCL] follows the lifecycle of any [BoxContainer], the sequence of
/// method invocations should be as follows:
///   - todo-doc-01 : document here and in [BoxContainer]
abstract class ChartRootContainerCL extends ChartAreaContainer implements ChartRootContainer {

  /// Simple Legend+X+Y+Data Container for a flutter chart.
  ///
  /// The simple flutter chart layout consists of only 2 major areas:
  /// - [YContainerCL] area manages and lays out the Y labels area, by calculating
  ///   sizes required for Y labels (in both X and Y direction).
  ///   The [YContainerCL]
  /// - [XContainerCL] area manages and lays out the
  ///   - X labels area, and the
  ///   - grid area.
  /// In the X direction, takes up all space left after the
  /// YContainer layes out the  Y labels area, that is, full width
  /// minus [YContainerCL.yLabelsContainerWidth].
  /// In the Y direction, takes
  /// up all available chart area, except a top horizontal strip,
  /// required to paint half of the topmost label.
  ChartRootContainerCL({
    required this.legendContainer,
    required this.xContainer,
    required this.yContainer,
    required this.yContainerFirst,
    required this.dataContainer,
    required ChartViewMaker chartViewMaker,
    required ChartModel chartModel,
    required this.isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  })  : super(chartViewMaker: chartViewMaker) {
    logger.Logger().d('    Constructing ChartRootContainer');
    // Attach children passed in constructor, previously created in Maker, to self
    addChildren([legendContainer, xContainer, yContainer, dataContainer]);
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
  late XContainerCL xContainer;
  @override
  late YContainerCL yContainer;
  @override
  late YContainerCL yContainerFirst;
  @override
  late DataContainerCL dataContainer;


  /// ##### Subclasses - aware members.

  late bool isStacked;

  // ##### Methods sharing information between child containers - XContainer and YContainer Source to DataContainer Sink

  double get xGridStep => xContainer.xGridStep;

  /// X coordinates of x ticks (x tick - middle of column, also middle of label).
  /// Once [XContainerCL.layout] and [YContainerCL.layout] are complete,
  /// this list drives the layout of [DataContainerCL].
  ///
  /// xTickX are calculated from labels [XLabelContainer]s, and used late in the
  ///  layout and painting of the DataContainer in ChartContainer.
  ///
  /// See [AxisLabelContainer.parentOffsetTick] for details.
  List<double> get xTickXs =>
      xContainer._xLabelContainers.map((var xLabelContainer) => xLabelContainer.parentOffsetTick).toList();

  /// Y coordinates of y ticks (y tick - extrapolated value of data, also middle of label).
  /// Once [XContainerCL.layout] and [YContainerCL.layout] are complete,
  /// this list drives the layout of [DataContainerCL].
  ///
  /// See [AxisLabelContainer.parentOffsetTick] for details.
  List<double> get yTickYs => yContainer._yLabelContainers.map((var yLabelContainer) => yLabelContainer.parentOffsetTick).toList();


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

    // ####### 2. Layout [yContainerFirst] to get Y container width
    //        that moves [XContainer] and [DataContainer].
    double yContainerFirstHeight = constraints.height - legendContainerSize.height;
    var yContainerFirstBoxConstraints =  BoxContainerConstraints.insideBox(size: ui.Size(
      constraints.width,
      yContainerFirstHeight,
    ));

    // Note: yContainerFirst used to be created here as  YContainer( chartViewMaker: chartViewMaker, yLabelsMaxHeightFromFirstLayout: 0.0
    //       yContainerFirst._parent, checked in applyParentConstraints => assertCallerIsParent
    //       is not yet set here, as yContainerFirst never goes through addChildren which sets _parent on children.
    //       so _parent cannot be late final.
    yContainerFirst.applyParentConstraints(this, yContainerFirstBoxConstraints);
    yContainerFirst.layout();

    // todo-00-switch-done-remove : if (chartViewMaker.isUseOldDataContainer) {
      yContainer._yLabelsMaxHeightFromFirstLayout = yContainerFirst.yLabelsMaxHeight;
    // todo-00-switch-done-remove : }
    // ####### 3. XContainer: Given width of YContainerFirst, constraint, then layout XContainer

    ui.Size yContainerFirstSize = yContainerFirst.layoutSize;

    // xContainer layout width depends on yContainerFirst layout result.  But this dependency can be expressed
    // as a constraint on xContainer, so no need to implement [findSourceContainersReturnLayoutResultsToBuildSelf]
    var xContainerBoxConstraints =  BoxContainerConstraints.insideBox(size: ui.Size(
      constraints.width - yContainerFirstSize.width,
      constraints.height - legendContainerSize.height,
    ));

    xContainer.applyParentConstraints(this, xContainerBoxConstraints);
    xContainer.layout();

    // When we got here, xContainer layout is done, so set the late final layoutSize after re-layouts
    xContainer.layoutSize = xContainer.lateReLayoutSize;

    ui.Size xContainerSize = xContainer.layoutSize;
    ui.Offset xContainerOffset = ui.Offset(yContainerFirstSize.width, constraints.height - xContainerSize.height);
    xContainer.applyParentOffset(this, xContainerOffset);

    // ####### 4. [YContainer]: The actual YContainer layout is needed, as height constraint for Y container
    //          is only known after XContainer layedout xUserLabels.  YContainer expands down to top of xContainer.
    //          The [yLabelsMaxHeightFromFirstLayout] is used to extrapolate data values to the y axis,
    //          and put labels on ticks.

    // yContainer layout height depends on xContainer layout result.  But this dependency can be expressed
    // as a constraint on yContainer, so no need to implement [findSourceContainersReturnLayoutResultsToBuildSelf]
    var yConstraintsHeight = constraints.height - legendContainerSize.height - xContainerSize.height;
    var yContainerBoxConstraints = BoxContainerConstraints.insideBox(size: ui.Size(
      constraints.width,
      yConstraintsHeight,
    ));

    yContainer.applyParentConstraints(this, yContainerBoxConstraints);
    yContainer.layout();

    var yContainerSize = yContainer.layoutSize;
    // The layout relies on YContainer width first time and second time to be the same, as width
    //    was used as remainder space for XContainer.
    // But height, will NOT be the same, it will be shorter second time.
    assert (yContainerFirstSize.width == yContainerSize.width);
    ui.Offset yContainerOffset = ui.Offset(0.0, legendContainerSize.height);
    yContainer.applyParentOffset(this, yContainerOffset);

    ui.Offset dataContainerOffset;

    // ### 6. Layout the data area, which included the grid
    // by calculating the X and Y positions of grid.
    // This must be done after X and Y are layed out - see xTickXs, yTickYs.
    // The [yContainer] internals and [yContainerSize] are both needed to offset and constraint the [dataContainer].
    BoxContainerConstraints dataContainerBoxConstraints;
    // todo-00-switch-done-remove : if (chartViewMaker.isUseOldDataContainer) {
      dataContainerBoxConstraints = BoxContainerConstraints.insideBox(
          size: ui.Size(
            constraints.width - yContainerSize.width,
            yConstraintsHeight, // Note: = constraints.height - legendContainerSize.height - xContainerSize.height,
          ));
      dataContainerOffset = ui.Offset(yContainerSize.width, legendContainerSize.height);
    // todo-00-switch-done-remove : } else {
    // todo-00-switch-done-remove :   dataContainerBoxConstraints = BoxContainerConstraints.insideBox(
    // todo-00-switch-done-remove :       size: ui.Size(
    // todo-00-switch-done-remove :         constraints.width - yContainerSize.width,
    // todo-00-switch-done-remove :         // todo-010 : height does not matter, why??? Can be e.g. 0.0, then the Column layout overflows but still produces result
    // todo-00-switch-done-remove :         //                Reason: bug in PositionedLineSegments layoutLengths(), see todo-010 in _positionTightOrLooseLineSegmentFor
    // todo-00-switch-done-remove :         yContainer.layoutSize.height, // todo-old-00-done-keep : cannot ask for axisPixelsRange : yContainer.axisPixelsRange.max - yContainer.axisPixelsRange.min,
    // todo-00-switch-done-remove :       ));
    // todo-00-switch-done-remove :   dataContainerOffset = ui.Offset(yContainerSize.width, legendContainerSize.height); // todo-old-00-done-keep : cannot ask for axisPixelsRange : ui.Offset(yContainerSize.width, legendContainerSize.height + yContainer.axisPixelsRange.min);
    // todo-00-switch-done-remove : }

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
  /// member [BoxContainer]s ([YContainerCL],[XContainerCL] etc),
  /// which recursively paints the leaf [BoxContainer]s lines, rectangles and circles
  /// in their calculated layout positions.
  @override
  void paint(ui.Canvas canvas) {

    // Draws the Y labels area of the chart.
    yContainer.paint(canvas);
    // Draws the X labels area of the chart.
    xContainer.paint(canvas);
    // Draws the legend area of the chart.
    legendContainer.paint(canvas);
    // Draws the grid, then data area - bars (bar chart), lines and points (line chart).
    dataContainer.paint(canvas);

    // clip canvas to size - this does nothing
    // todo-1: THIS canvas.clipRect VVVV CAUSES THE PAINT() TO BE CALLED AGAIN. WHY??
    // canvas.clipRect(const ui.Offset.zero & size); // Offset & Size => Rect
  }

}

/// Common base class for containers of axes with their labels - [XContainerCL] and [YContainerCL].
abstract class AxisContainerCL extends ChartAreaContainer with PixelRangeProvider {
  AxisContainerCL({
    required ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker,
  );
}

mixin PixelRangeProvider on ChartAreaContainer {

  /// Late calculated minimum and maximum pixels for the Y axis WITHIN the [AxisContainerCL].
  ///
  /// The [axisPixelsRange] has several important properties and roles:
  ///   1. It contains the pixels of this [AxisContainerCL]
  ///      available to the axis. Because this [AxisContainerCL] is generally bigger than the axis pixels,
  ///      this range generally does NOT generally start at zero and end below the pixels available
  ///      to the [AxisContainerCL], as follows:
  ///      - For the [YContainerCL], the [axisPixelsRange]  start after a half-label height is excluded on the top,
  ///        and a vertical tick height is excluded on the bottom.
  ///      - For the [XContainerCL], the [axisPixelsRange] is currently UNUSED.
  ///
  ///  2. The difference between [axisPixelsRange] min and max is the height constraint
  ///     on [DataContainer]!
  ///
  ///   3. If is the interval to which the axis data values, stored in [labelsGenerator]'s
  ///      member [DataRangeLabelInfosGenerator.dataRange] should be extrapolated.
  ///
  /// Important note: Cannot be final, because, if on XContainer, the [layout] code where
  ///                 this is set may be called multiple times.
  late Interval axisPixelsRange;
}

/// Container of the Y axis labels.
///
/// This [ChartAreaContainer] operates as follows:
/// - Vertically available space is all used (filled).
/// - Horizontally available space is used only as much as needed.
/// The used amount is given by maximum Y label width, plus extra spacing.
/// - See [layout] and [layoutSize] for resulting size calculations.
/// - See the [XContainerCL] constructor for the assumption on [BoxContainerConstraints].
class YContainerCL extends AxisContainerCL implements YContainer {

  /// Constructs the container that holds Y labels.
  ///
  /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
  /// all available vertical space, and only use necessary horizontal space.
  YContainerCL({
    required ChartViewMaker chartViewMaker,
    double yLabelsMaxHeightFromFirstLayout = 0.0,
  }) : super(
    chartViewMaker: chartViewMaker,
  ) {
    _yLabelsMaxHeightFromFirstLayout = yLabelsMaxHeightFromFirstLayout;
  }

  /// Containers of Y labels.
  late List<YLabelContainerCL> _yLabelContainers;

  /// Maximum label height found by the first layout (pre-layout),
  /// is ONLY used to 'shorten' YContainer constraints on top.
  double _yLabelsMaxHeightFromFirstLayout = 0.0;

  /// Overridden method creates this [YContainerCL]'s hierarchy-children Y labels
  /// (instances of [YLabelContainer]) which are maintained in this [YContainerCL._yLabelContainers].
  ///
  /// The reason the hierarchy-children Y labels are created late in this
  /// method [buildAndReplaceChildren] is that we MAY NOT know until the parent
  /// [chartViewMaker] is being layed out, how much Y-space there is, therefore,
  /// how many Y labels would fit. BUT CURRENTLY, WE DO NOT MAKE USE OF THIS LATENESS ON [YContainerCL],
  /// only on [XContainerCL] re-layout.
  ///
  /// The created Y labels should be layed out by invoking [layout]
  /// immediately after this method [buildAndReplaceChildren]
  /// is invoked.
  @override
  void buildAndReplaceChildren() {

    // Init the list of y label containers
    _yLabelContainers = [];

    // Code above MUST run for the side-effects of setting [axisPixels] and extrapolating the [labelInfos].
    // Now can check if labels are shown, set empty children and return.
    if (!chartViewMaker.chartOptions.yContainerOptions.isYContainerShown) {
      _yLabelContainers = List.empty(growable: false); // must be set for yLabelsMaxHeight to function
      replaceChildrenWith(_yLabelContainers);
      return;
    }

    ChartOptions options = chartViewMaker.chartOptions;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: options.labelCommonOptions.labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.labelCommonOptions.labelTextAlign, // center text
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );

    for (AxisLabelInfo labelInfo in chartViewMaker.yLabelsGenerator.labelInfoList) {
      var yLabelContainer = YLabelContainerCL(
        chartViewMaker: chartViewMaker,
        label: labelInfo.formattedLabel,
        labelTiltMatrix: vector_math.Matrix2.identity(), // No tilted labels in YContainer
        labelStyle: labelStyle,
        labelInfo: labelInfo,
        ownerChartAreaContainer: this,
      );

      _yLabelContainers.add(yLabelContainer);
    }

    replaceChildrenWith(_yLabelContainers);
  }

  /// Lays out this [YContainerCL] - the area containing the Y axis labels -
  /// which children were build during [buildAndReplaceChildren].
  ///
  /// As this [YContainerCL] is [BuilderOfChildrenDuringParentLayout],
  /// this method should be called just after [buildAndReplaceChildren]
  /// which builds hierarchy-children of this container.
  ///
  /// In the hierarchy-parent [ChartRootContainerCL.layout],
  /// the call to this object's [layout] is second, after [LegendContainer.layout].
  /// This [YContainerCL.layout] calculates [YContainerCL]'s labels width,
  /// the width taken by this container for the Y axis labels.
  ///
  /// The remaining horizontal width of [ChartRootContainerCL.chartArea] minus
  /// [YContainerCL]'s labels width provides remaining available
  /// horizontal space for the [GridLinesContainer] and [XContainerCL].
  @override
  void layout() {
    buildAndReplaceChildren();

    // [_axisYMin] and [_axisYMax] define end points of the Y axis, in the YContainer coordinates.
    // The [_axisYMin] does not start at 0, but leaves space for half label height
    double axisPixelsMin = _yLabelsMaxHeightFromFirstLayout / 2;
    // The [_axisYMax] does not end at the constraint size, but leaves space for a vertical tick
    double axisPixelsMax =
        constraints.size.height - (chartViewMaker.chartOptions.dataContainerOptions.dataBottomTickHeight);

    axisPixelsRange = Interval(axisPixelsMin, axisPixelsMax);

    // The code above must be performed for axisPixelsRange to initialize
    if (!chartViewMaker.chartOptions.yContainerOptions.isYContainerShown) {
      // Special no-labels branch must initialize the layoutSize
      layoutSize = const ui.Size(0.0, 0.0); // must be initialized
      return;
    }

    // labelInfos.extrapolateLabels(axisPixelsYMin: yContainerAxisPixelsYMin, axisPixelsYMax: yContainerAxisPixelsYMax);

    // Iterate, apply parent constraints, then layout all labels in [_yLabelContainers],
    //   which were previously created in [_createYLabelContainers]
    for (var yLabelContainer in _yLabelContainers) {
      // Constraint will allow to set labelMaxWidth which has been taken out of constructor.
      yLabelContainer.applyParentConstraints(this, BoxContainerConstraints.infinity());
      yLabelContainer.layout();

      double yTickY = yLabelContainer.parentOffsetTick;
      double labelTopY = yTickY - yLabelContainer.layoutSize.height / 2;

      // Move the contained LabelContainer to correct position
      yLabelContainer.applyParentOffset(this,
        ui.Offset(chartViewMaker.chartOptions.yContainerOptions.yLabelsPadLR, labelTopY),
      );
    }

    // Set the [layoutSize]
    double yLabelsContainerWidth =
        _yLabelContainers.map((yLabelContainer) => yLabelContainer.layoutSize.width).reduce(math.max) +
            2 * chartViewMaker.chartOptions.yContainerOptions.yLabelsPadLR;

    layoutSize = ui.Size(yLabelsContainerWidth, constraints.size.height);
  }

  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    if (!chartViewMaker.chartOptions.yContainerOptions.isYContainerShown) {
      return;
    }
    for (AxisLabelContainerCL yLabelContainer in _yLabelContainers) {
      yLabelContainer.applyParentOffset(this, offset);
    }
  }

  @override
  void paint(ui.Canvas canvas) {
    if (!chartViewMaker.chartOptions.yContainerOptions.isYContainerShown) {
      return;
    }
    for (AxisLabelContainerCL yLabelContainer in _yLabelContainers) {
      yLabelContainer.paint(canvas);
    }
  }

  double get yLabelsMaxHeight {
    // todo-04 replace-this-pattern-with-fold - look for '? 0.0'
    return _yLabelContainers.isEmpty
        ? 0.0
        : _yLabelContainers.map((yLabelContainer) => yLabelContainer.layoutSize.height).reduce(math.max);
  }
}

/// Container of the X axis labels.
///
/// This [ChartAreaContainer] operates as follows:
/// - Horizontally available space is all used (filled).
/// - Vertically available space is used only as much as needed.
/// The used amount is given by maximum X label height, plus extra spacing.
/// - See [layout] and [layoutSize] for resulting size calculations.
/// - See the [XContainerCL] constructor for the assumption on [BoxContainerConstraints].
class XContainerCL extends AdjustableLabelsChartAreaContainer with PixelRangeProvider implements XContainer {

  /// Constructs the container that holds X labels.
  ///
  /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  XContainerCL({
    required ChartViewMaker chartViewMaker,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartViewMaker: chartViewMaker,
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  );

  /// X labels. Can NOT be final or late, as the list changes on [reLayout]
  List<AxisLabelContainerCL> _xLabelContainers = List.empty(growable: true);

  double _xGridStep = 0.0;

  double get xGridStep => _xGridStep;

  /// Size allocated for each shown label (>= [_xGridStep]
  double _shownLabelsStepWidth = 0.0;

  /// Member to manage temporary layout size during relayout.
  ///
  /// Because [layoutSize] is late final, we cannot keep setting it during relayout.
  /// Instead, we set this member, and when relayouting is done, we use it to late-set [layoutSize] once.
  ui.Size lateReLayoutSize = const ui.Size(0.0, 0.0);

  @override
  /// Overridden method creates this [XContainerCL]'s hierarchy-children X labels
  /// (instances of [XLabelContainer]) which are maintained in this [_xLabelContainers].
  ///
  /// The reason the hierarchy-children Y labels are created late in this
  /// method [buildAndReplaceChildren], invoked as first message send in [layout],
  /// is that we do not know until the [chartViewMaker] on this [ChartAreaContainer]
  /// is being layed out, how much Y-space there is, therefore, how many X labels would fit.
  /// During re-layout, this [buildAndReplaceChildren] is invoked again, and may build
  /// less children labels in this [_xLabelContainers]
  ///
  /// The created X labels should be layed out by invoking [layout]
  /// immediately after this method [buildAndReplaceChildren]
  /// is invoked.
  void buildAndReplaceChildren() {

    // First clear any children that could be created on nested re-layout
    _xLabelContainers = List.empty(growable: true);

    ChartOptions options = chartViewMaker.chartOptions;
    List<AxisLabelInfo> xUserLabels = chartViewMaker.xLabelsGenerator.labelInfoList;
    LabelStyle labelStyle = _styleForLabels(options);

    // Core layout loop, creates a AxisLabelContainer from each xLabel,
    //   and lays out the XLabelContainers along X in _gridStepWidth increments.

    for (int xIndex = 0; xIndex < xUserLabels.length; xIndex++) {
      var xLabelContainer = XLabelContainerCL(
        chartViewMaker: chartViewMaker,
        label: xUserLabels[xIndex].formattedLabel,
        labelTiltMatrix: labelLayoutStrategy.labelTiltMatrix, // Possibly tilted labels in XContainer
        labelStyle: labelStyle,
        // In [XLabelContainer], [labelInfo] is NOT used, as we do not create LabelInfo for XAxis
        labelInfo: chartViewMaker.xLabelsGenerator.labelInfoList[xIndex],
        ownerChartAreaContainer: this,
      );
      _xLabelContainers.add(xLabelContainer);
    }
    replaceChildrenWith(_xLabelContainers);
  }

  @override
  /// Lays out the chart in horizontal (x) direction.
  ///
  /// Evenly divides the available width to all labels (spacing included).
  /// First / Last vertical line is at the center of first / last label.
  ///
  /// The layout is independent of whether the labels are tilted or not,
  ///   in the sense that all tilting logic is in
  ///   [LabelContainer], and queried by [LabelContainer.layoutSize].
  void layout() {
    buildAndReplaceChildren();

    ChartOptions options = chartViewMaker.chartOptions;

    // Purely artificial on XContainer for now, we are taking labels from data, or user, NOT generating range.
    axisPixelsRange = const Interval(0.0, 200.0);

    List<AxisLabelInfo> xUserLabels = chartViewMaker.xLabelsGenerator.labelInfoList;
    double       yTicksWidth =
                   options.dataContainerOptions.dataLeftTickWidth + options.dataContainerOptions.dataRightTickWidth;
    double       availableWidth = constraints.size.width - yTicksWidth;
    double       labelMaxAllowedWidth = availableWidth / xUserLabels.length;
    int numShownLabels    = (xUserLabels.length ~/ labelLayoutStrategy.showEveryNthLabel);
    _xGridStep            = labelMaxAllowedWidth;
    _shownLabelsStepWidth = availableWidth / numShownLabels;

    // Layout all X labels in _xLabelContainers created and added in [buildAndAddChildrenLateDuringParentLayout]
    int xIndex = 0;
    for (AxisLabelContainerCL xLabelContainer in _xLabelContainers) {
      xLabelContainer.applyParentConstraints(this, BoxContainerConstraints.infinity());
      xLabelContainer.layout();

      // We only know if parent ordered skip after layout (because some size is too large)
      xLabelContainer.applyParentOrderedSkip(this, !_isLabelOnIndexShown(xIndex));

      // Core of X layout calcs - get the layed out label size,
      //   then find xTickX - the X middle of the label bounding rectangle in hierarchy-parent [XContainer]
      ui.Rect labelBound = ui.Offset.zero & xLabelContainer.layoutSize;
      double halfStepWidth = _xGridStep / 2;
      double atIndexOffset = _xGridStep * xIndex;
      double xTickX = halfStepWidth + atIndexOffset + options.dataContainerOptions.dataLeftTickWidth;
      double labelTopY = options.xContainerOptions.xLabelsPadTB; // down by XContainer padding

      xLabelContainer.parentOffsetTick = xTickX;

      // tickX and label centers are same. labelLeftTop = label paint start.
      var labelLeftTop = ui.Offset(
        xTickX - labelBound.width / 2,
        labelTopY,
      );

      // labelLeftTop + offset for envelope
      xLabelContainer.applyParentOffset(this, labelLeftTop + xLabelContainer.tiltedLabelEnvelopeTopLeft);

      xIndex++;
    }

    // Set the layout size calculated by this layout. This may be called multiple times during relayout.
    lateReLayoutSize = ui.Size(
      constraints.size.width,
      xLabelsMaxHeight + 2 * options.xContainerOptions.xLabelsPadTB,
    );

    if (!chartViewMaker.chartOptions.xContainerOptions.isXContainerShown) {
      // If not showing this container, no layout needed, just set size to 0.
      lateReLayoutSize = const ui.Size(0.0, 0.0);
      return;
    }

    // This achieves auto-layout of labels to fit along X axis.
    // Iterative call to this layout method, until fit or max depth is reached,
    //   whichever comes first.
    labelLayoutStrategy.reLayout(BoxContainerConstraints.unused());
  }

  /// Get the height of xlabels area without padding.
  double get xLabelsMaxHeight {
    return _xLabelContainers.isEmpty
        ? 0.0
        : _xLabelContainers.map((xLabelContainer) => xLabelContainer.layoutSize.height).reduce(math.max);
  }

  LabelStyle _styleForLabels(ChartOptions options) {
    // Use widgets.TextStyle obtained from ChartOptions and "extend it" as a copy, so a 
    //   (potentially modified) TextStyle from Options is used in all places in flutter_charts.

    widgets.TextStyle labelTextStyle = options.labelCommonOptions.labelTextStyle.copyWith(
      fontSize: labelLayoutStrategy.labelFontSize,
    );

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.labelCommonOptions.labelTextAlign, // center text
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );
    return labelStyle;
  }

  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    if (!chartViewMaker.chartOptions.xContainerOptions.isXContainerShown) {
      return;
    }
    // super.applyParentOffset(caller, offset); // super did double-offset as xLabelContainer are on 2 places

    for (AxisLabelContainerCL xLabelContainer in _xLabelContainers) {
      xLabelContainer.applyParentOffset(this, offset);
    }
  }

  /// Paints this [XContainerCL] on the passed [canvas].
  ///
  /// Delegates painting to all contained [LabelContainerOriginalKeep]s.
  /// Any contained [LabelContainerOriginalKeep] must have been offset to the appropriate position.
  ///
  /// A special situation is when the [LabelContainerOriginalKeep]s are tilted, say counterclockwise.
  /// Because labels are always painted horizontally in the screen coordinate system, we much tilt them
  /// by painting them on a rotated position.
  /// This is achieved as follows: At the moment of calling this [paint],
  /// the top-left corner of the container (where the label will start painting), must be moved
  /// by rotation from the it's intended position clockwise. The [canvas]
  /// will be saved, then rotated, then labels painted horizontally into the offset,
  /// then the canvas rotated back for further painting.
  /// The canvas rotation back counterclockwise 'carries' with it the horizontally painted labels,
  /// which end up in the intended position but rotated counterclockwise.
  @override
  void paint(ui.Canvas canvas) {
    if (!chartViewMaker.chartOptions.xContainerOptions.isXContainerShown) {
      return;
    }
    if (labelLayoutStrategy.isRotateLabelsReLayout) {
      // Tilted X labels. Must use canvas and offset coordinate rotation.
      canvas.save();
      canvas.rotate(labelLayoutStrategy.labelTiltRadians);

      _paintLabelContainers(canvas);

      canvas.restore();
    } else {
      // Horizontal X labels, potentially skipped or shrinked
      _paintLabelContainers(canvas);
    }
  }

  void _paintLabelContainers(canvas) {
    for (AxisLabelContainerCL  xLabelContainer in _xLabelContainers) {
      if (!xLabelContainer.orderedSkip) xLabelContainer.paint(canvas);
    }
  }

  bool _isLabelOnIndexShown(int xIndex) {
    if (xIndex % labelLayoutStrategy.showEveryNthLabel == 0) return true;
    return false;
  }

  // Checks the contained labels, represented as [AxisLabelContainer],
  // for overlap.
  //
  /// Only should be called after [layout]
  ///
  /// Identifying overlap is crucial in labels auto-layout.
  ///
  /// Notes:
  /// - [_xGridStep] is a limit for each label container width in the X direction.
  ///
  /// - Labels are layed out evenly, so if any label container's [layoutSize]
  /// in the X direction overflows the [_xGridStep],
  /// labels containers DO overlap. In such situation, the caller should
  /// take action to make labels smaller, tilt, or skip.
  ///
  @override
  bool labelsOverlap() {
    if (_xLabelContainers.any((axisLabelContainer) =>
        !axisLabelContainer.orderedSkip && axisLabelContainer.layoutSize.width > _shownLabelsStepWidth)) {
      return true;
    }

    return false;
  }
}

/// Manages the core chart area which displays and paints (in this order):
/// - The grid (this includes the X and Y axis).
/// - Data - as columns of bar chart, line chart, or other chart type
abstract class DataContainerCL extends ChartAreaContainer implements DataContainer {

  /// Constructs instance from [ChartViewMaker].
  ///
  /// Note: It is assumed that the passed [chartViewMaker]
  ///       is [SwitchChartViewMakerCL], a derivation of [ChartViewMaker].
  DataContainerCL({required ChartViewMaker chartViewMaker})
      : super(
    chartViewMaker: chartViewMaker,
  );

  /// Keeps data values grouped in columns.
  ///
  /// This column grouped data instance is managed here in the [DataContainerCL],
  /// as their data points are needed both during [YContainerCL.layout]
  /// to calculate extrapolating, and also here in [DataContainerCL.layout] to create
  /// [PointPresentersColumns] instance.
  ///
  /// Moved here on [DataContainerCL] from [ChartModel]. While this is strictly speaking a model legacy coded_layout
  /// system, the only use is on this [DataContainerCL] so it is a good place to hold it.
  late PointsColumns pointsColumns;


  /// Container of gridlines parallel to X axis.
  ///
  /// The reason to separate [_xGridLinesContainer] and [_yGridLinesContainer] is for them to hide/show independently.
  late GridLinesContainer _xGridLinesContainer;
  late GridLinesContainer _yGridLinesContainer;

  /// Columns of pointPresenters.
  ///
  /// PointPresenters may be:
  /// - points and lines in line chart
  /// - bars (stacked or grouped) in bar chart
  ///
  late PointPresentersColumns pointPresentersColumns;

  /// Overridden builds children of self [DataContainerCL], the [_yGridLinesContainer] and [_xGridLinesContainer]
  /// and adds them as self children.
  @override
  void buildAndReplaceChildren() {

    List<BoxContainer> dataContainerChildren = [];

    /// Root of chart, cast to CL version.
    ChartRootContainerCL chartRootContainer = chartViewMaker.chartRootContainer as ChartRootContainerCL;

    // Vars that layout needs from the [chartRootContainer] passed to constructor
    ChartOptions chartOptions = chartViewMaker.chartOptions;
    bool isStacked = chartViewMaker.isStacked;

    // ### 1. Vertical Grid (yGrid) layout:

    // Use this DataContainer layout dependency on [xTickXs] as guidelines for X labels
    // in [XContainer._xLabelContainers], for each create one [LineContainer] as child of [_yGridLinesContainer]

    // Initial values which will show as bad lines if not changed during layout.
    ui.Offset initLineFrom = const ui.Offset(0.0, 0.0);
    ui.Offset initLineTo = const ui.Offset(100.0, 100.0);

    // Construct the GridLinesContainer with children: [LineContainer]s
    _yGridLinesContainer = GridLinesContainer(
      chartViewMaker: chartViewMaker,
      children: chartRootContainer.xTickXs.map((double xTickX) {
        // Add vertical yGrid line in the middle of label (stacked bar chart) or on label left edge (line chart)
        double lineX = isStacked ? xTickX - chartRootContainer.xGridStep / 2 : xTickX;
        return LineContainer(
          chartViewMaker: chartViewMaker,
          lineFrom: initLineFrom,
          lineTo: initLineTo,
          linePaint: gridLinesPaint(chartOptions),
          manualLayedOutFromX: lineX,
          manualLayedOutFromY: 0.0,
          manualLayedOutToX: lineX,
          manualLayedOutToY: constraints.height,
        );
      }).toList(growable: false),
    );

    // For stacked, we need to add last right vertical yGrid line - one more child to  [_yGridLinesContainer]
    if (isStacked && chartRootContainer.xTickXs.isNotEmpty) {
      double lineX = chartRootContainer.xTickXs.last + chartRootContainer.xGridStep / 2;

      _yGridLinesContainer.addChildren([
        LineContainer(
          chartViewMaker: chartViewMaker,
          lineFrom: initLineFrom,
          // ui.Offset(lineX, 0.0),
          lineTo: initLineTo,
          // ui.Offset(lineX, layoutSize.height),
          linePaint: gridLinesPaint(chartOptions),
          manualLayedOutFromX: lineX,
          manualLayedOutFromY: 0.0,
          manualLayedOutToX: lineX,
          manualLayedOutToY: constraints.height,
        ),
      ]);
    }
    // Add the constructed Y - parallel GridLinesContainer as child to self DataContainer
    dataContainerChildren.addAll([_yGridLinesContainer]);

    // ### 2. Horizontal Grid (xGrid) layout:

    // Use this DataContainer layout dependency on [yTickYs] as guidelines for Y labels
    // in [YContainer._yLabelContainers], for each create one [LineContainer] as child of [_xGridLinesContainer]

    // Construct the GridLinesContainer with children: [LineContainer]s
    _xGridLinesContainer = GridLinesContainer(
      chartViewMaker: chartViewMaker,
      children:
          // yTickYs create vertical xLineContainers
          // Position the horizontal xGrid at mid-points of labels at yTickY.
      chartRootContainer.yTickYs.map((double yTickY) {
        return LineContainer(
          chartViewMaker: chartViewMaker,
          lineFrom: initLineFrom,
          lineTo: initLineTo,
          linePaint: gridLinesPaint(chartOptions),
          manualLayedOutFromX: 0.0,
          manualLayedOutFromY: yTickY,
          manualLayedOutToX: constraints.width,
          manualLayedOutToY: yTickY,
        );
      }).toList(growable: false),
    );

    // Add the constructed X - parallel GridLinesContainer as child to self DataContainer
    dataContainerChildren.addAll([_xGridLinesContainer]);

    replaceChildrenWith(dataContainerChildren);
  }

  /// Overrides [BoxLayouter.layout] for data area.
  ///
  /// Uses all available space in the [constraints] set in parent [buildAndReplaceChildren],
  /// which it divides evenly between it's children.
  ///
  /// First lays out the Grid, then, scales the columns to the [YContainerCL]'s extrapolate
  /// based on the available size.
  @override
  void layout() {

    // todo-00-switch-done-remove : if (!chartViewMaker.isUseOldDataContainer) {
    // todo-00-switch-done-remove :   super.layout();
    // todo-00-switch-done-remove :   return;
    // todo-00-switch-done-remove : }

    // OLD Manual layout build. NEW invokes this as part of auto-layout.
    buildAndReplaceChildren();

    // DataContainer uses it's full constraints to lay out it's grid and presenters!
    layoutSize = ui.Size(constraints.size.width, constraints.size.height);

    // ### 1. Vertical Grid (yGrid) layout:

    // Position the vertical yGrid in the middle of labels (line chart) or on label left edge (stacked bar)
    _yGridLinesContainer.applyParentConstraints(this, constraints);
    _yGridLinesContainer.layout();

    // ### 2. Horizontal Grid (xGrid) layout:

    // Position the horizontal xGrid at mid-points of labels at yTickY.
    _xGridLinesContainer.applyParentConstraints(this, constraints);
    _xGridLinesContainer.layout();
  }

  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    // todo-00-switch-done-remove : if (!chartViewMaker.isUseOldDataContainer) {
    // todo-00-switch-done-remove :   super.applyParentOffset(caller, offset);
    // todo-00-switch-done-remove :   return;
    // todo-00-switch-done-remove : }

    // Move all container atomic elements - lines, labels, circles etc
    _xGridLinesContainer.applyParentOffset(this, offset);

    // draw vertical grid
    _yGridLinesContainer.applyParentOffset(this, offset);

    // Create, layout, then offset, the 'data container' replacement - the PointPresentersColumns.
    // The [PointsColumns] and [PointPresentersColumns] are the OLD NOT EXACTLY EQUIVALENT manual way of creating
    // model [PointsColumns] which is created, and layed out by extrapolating,
    // and container [PointPresentersColumns] which is painted.
    // So in the old way, the model is layed out, the container is created from the layed out model, then painted.
    _createLayoutOffset_PointsColumns_Model_Then_Create_PointsPresentersColumns(offset);
  }

  void _createLayoutOffset_PointsColumns_Model_Then_Create_PointsPresentersColumns(ui.Offset offset) {
    // Create, layout, then offset, the 'data container':
    
    // This section is doing the following:
    // 1. Creates the 'data container', represented here by [PointsColumns]
    // 2. Layouts the 'data container' by extrapolating.
    //    Extrapolating is using the [_SourceYContainerAndYContainerToSinkDataContainer]
    //    which holds the previously layed out [XContainer] and [YContainer].
    // 3. Applies the parent offset on the 'data container' [PointsColumns].
    //    This offsets the 'data container' [PointsColumns] to the right of the Y axis,
    //    and to the top of the X axis.
    // 4. Creates the 'view maker', represented here by [PointPresentersColumns],
    //    and set it on [pointPresentersColumns].
    // 5. LATER, in [paint], paints the  'view maker', represented here by [PointPresentersColumns]
    
    // 1. From the [ChartData] model, create the 'data container' (the [PointsColumns])
    //    which represent the list of columns on chart.
    //    Set the  [PointsColumns] instance on [chartViewMaker.chartModel.pointsColumns].
    //    The coordinates in [PointsColumns] are relative - 0 based
    pointsColumns = PointsColumns(
      chartViewMaker: chartViewMaker,
      pointPresenterCreator: (chartViewMaker as SwitchChartViewMakerCL).pointPresenterCreator,
      isStacked: chartViewMaker.isStacked,
      caller: this,
    );
    
    // 2. Layout the data container by extrapolating.
    // Scale the [pointsColumns] to the [YContainer]'s extrapolate.
    // This is effectively a [layout] of the lines and bars pointPresenters, currently
    //   done in [VerticalBarPointPresenter] and [LineChartPointPresenter]
    _lextrPointsColumns(chartViewMaker.chartModel);
    
    // 3. Apply offset to the lines and bars (the 'data container' [PointsColumns]).
    pointsColumns.applyParentOffset(this, offset);

    // 4. Create the 'view maker', represented here by [PointPresentersColumns],
    //    and set it on [pointPresentersColumns].
    //    Note: The 'view maker' [PointPresentersColumns] is created from the [PointsColumns],
    //          'data container'.
    pointPresentersColumns = PointPresentersColumns(
      pointsColumns: pointsColumns,
      chartViewMaker: chartViewMaker,
      pointPresenterCreator: (chartViewMaker as SwitchChartViewMakerCL).pointPresenterCreator,
    );
  }

  /// Paints the Grid lines of the chart area.
  ///
  /// Note that the super [paint] remains not implemented in this class.
  /// Superclasses (for example the line chart data container) should
  /// call this method at the beginning of it's [paint] implementation,
  /// followed by painting the [PointPresenter]s in [_drawPointPresentersColumns].
  ///
  void _paintGridLines(ui.Canvas canvas) {
    // draw horizontal grid
    _xGridLinesContainer.paint(canvas);

    // draw vertical grid
    if (chartViewMaker.chartOptions.yContainerOptions.isYGridlinesShown) {
      _yGridLinesContainer.paint(canvas);
    }
  }

  /// Abstract method common to implementing data containers,
  /// currently the [LineChartDataContainerCL] and the [VerticalBarChartDataContainerCL].
  void _drawPointPresentersColumns(ui.Canvas canvas);

  /// Paints grid lines, then paints [PointPresentersColumns]
  @override
  void paint(ui.Canvas canvas) {
    // todo-00-switch-done-remove : if (!chartViewMaker.isUseOldDataContainer) {
    // todo-00-switch-done-remove :   super.paint(canvas);
    // todo-00-switch-done-remove :   return;
    // todo-00-switch-done-remove : }

    _paintGridLines(canvas);
    _drawPointPresentersColumns(canvas);
  }

  // ##### Extrapolating and layout methods of [_chartContainer.pointsColumns]
  //       and [pointPresentersColumns]

  /// Scales all data stored in leafs of columns and rows
  /// as [StackableValuePoint]. Depending on whether we are layouting
  /// a stacked or unstacked chart, extrapolating is done on stacked or unstacked
  /// values.
  ///
  /// Must be called before [setupPointPresentersColumns] as [setupPointPresentersColumns]
  /// uses the  absolute extrapolated [chartViewMaker.pointsColumns].
  void _lextrPointsColumns(ChartModel chartModel) {
    // ChartRootContainer, cast to CL version
    pointsColumns.lextrPointsColumns(chartViewMaker, chartViewMaker.chartRootContainer as ChartRootContainerCL);
  }

  /// Optionally paint series in reverse order (first to last,
  /// vs last to first which is default).
  ///
  /// See [DataContainerOptions.valuesRowsPaintingOrder].
  List<PointPresenter> optionalPaintOrderReverse(List<PointPresenter> pointPresenters) {
    var options = chartViewMaker.chartOptions;
    if (options.dataContainerOptions.valuesRowsPaintingOrder == DataRowsPaintingOrder.firstToLast) {
      pointPresenters = pointPresenters.reversed.toList();
    }
    return pointPresenters;
  }
}

/// Provides the data area container for the bar chart.
///
/// The only role is to implement the abstract method of the baseclass,
/// [paint] and [_drawPointPresentersColumns].
class VerticalBarChartDataContainerCL extends DataContainerCL {
  VerticalBarChartDataContainerCL({
    required ChartViewMaker chartViewMaker,
  }) : super(
          chartViewMaker: chartViewMaker,
        );

  /// Draws the actual atomic visual elements representing data on the chart.
  ///
  /// The atomic visual elements are either  lines with points (on the line chart),
  /// or bars/columns, stacked or grouped (on the bar/column charts).
  @override
  void _drawPointPresentersColumns(ui.Canvas canvas) {
    PointPresentersColumns pointPresentersColumns = this.pointPresentersColumns;

    for (PointPresentersColumn pointPresentersColumn in pointPresentersColumns) {
      // todo-2 do not repeat loop, collapse to one construct

      var positivePointPresenterList = pointPresentersColumn.positivePointPresenters;
      positivePointPresenterList = optionalPaintOrderReverse(positivePointPresenterList);
      for (PointPresenter pointPresenter in positivePointPresenterList) {
        bar_presenters.VerticalBarPointPresenter presenterCast = pointPresenter as bar_presenters.VerticalBarPointPresenter;
        canvas.drawRect(
          presenterCast.presentedRect,
          presenterCast.valuesRowPaint,
        );
      }

      var negativePointPresenterList = pointPresentersColumn.negativePointPresenters;
      negativePointPresenterList = optionalPaintOrderReverse(negativePointPresenterList);
      for (PointPresenter pointPresenter in negativePointPresenterList) {
        bar_presenters.VerticalBarPointPresenter presenterCast = pointPresenter as bar_presenters.VerticalBarPointPresenter;
        canvas.drawRect(
          presenterCast.presentedRect,
          presenterCast.valuesRowPaint,
        );
      }
    }
  }
}

/// Provides the data area container for the line chart.
///
/// The only role is to implement the abstract method of the baseclass,
/// [paint] and [drawDataPointPresentersColumns].
class LineChartDataContainerCL extends DataContainerCL {
  LineChartDataContainerCL({
    required ChartViewMaker chartViewMaker,
  }) : super(
          chartViewMaker: chartViewMaker,
        );

  /// Draws the actual atomic visual elements representing data on the chart.
  ///
  /// The atomic visual elements are either  lines with points (on the line chart),
  /// or bars/columns, stacked or grouped (on the bar/column charts).
  @override
  void _drawPointPresentersColumns(ui.Canvas canvas) {
    var pointPresentersColumns = this.pointPresentersColumns;
    for (PointPresentersColumn pointPresentersColumn in pointPresentersColumns) {
      var pointPresenterList = pointPresentersColumn.pointPresenters;
      pointPresenterList = optionalPaintOrderReverse(pointPresenterList);
      for (PointPresenter pointPresenter in pointPresenterList) {
        line_presenters.LineAndHotspotPointPresenter pointPresenterCast = pointPresenter as line_presenters.LineAndHotspotPointPresenter;
        // todo 0-future-minor Use call to Container.paint
        canvas.drawLine(
          pointPresenterCast.lineContainer.lineFrom,
          pointPresenterCast.lineContainer.lineTo,
          pointPresenterCast.lineContainer.linePaint,
        );
        // todo 0-future-medium Add hotspot as Container, use Container.paint
        canvas.drawCircle(
          pointPresenterCast.offsetPoint,
          pointPresenterCast.outerRadius,
          pointPresenterCast.outerPaint,
        );
        canvas.drawCircle(
          pointPresenterCast.offsetPoint,
          pointPresenterCast.innerRadius,
          pointPresenterCast.innerPaint,
        );
      }
    }
  }
}

/// Represents a set of gridlines (either horizontal or vertical, but not both),
/// which draw the dotted grid lines in chart.
///
/// The grid lines are positioned in the middle of labels (Y labels, and X labels for non-stacked)
/// or on the left label edge (X labels for stacked).
///
/// Note: Methods [layout], [applyParentOffset], and [paint], use the default implementation.
///
class GridLinesContainer extends ChartAreaContainer {

  /// Construct from children [LineContainer]s.
  GridLinesContainer({
    required ChartViewMaker chartViewMaker,
    required List<LineContainer>? children,
  }) : super(
          children: children,
          chartViewMaker: chartViewMaker,
        );

  /// Override from base class sets the layout size.
  ///
  /// This [GridLinesContainer] can be leaf if there are no labels or labels are not shown.
  /// Leaf containers which do not override [BoxLayouter.layout] must override this method,
  /// setting [layoutSize].
  @override
  void layout_Post_Leaf_SetSize_FromInternals() {
    if (!isLeaf) {
      throw StateError('Only a leaf can be sent this message.');
    }
    layoutSize = constraints.size;
  }

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }
}


/// Represents one Y numeric value in the [DeprecatedChartData.valuesRows],
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
    required this.chartViewMaker,
    this.predecessorPoint,
  })  : isStacked = false,
        fromY = 0.0,
        toY = dataY;

  // ################## Members ###################
  // ### Group 0: Structural

  /// Root container added to access yContainer.axisPixels min / max
  late final ChartViewMaker chartViewMaker;

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
  StackableValuePoint lextrToPixels({
    required double scaledX,
    required DataRangeLabelInfosGenerator yLabelsGenerator,
  }) {
    // Scales fromY of from the OLD [ChartData] BUT all the extrapolating domains in yLabelsGenerator
    // were calculated using the NEW [ChartModel]

    YContainerCL yContainerCL = chartViewMaker.chartRootContainer.yContainer as YContainerCL;
    double axisPixelsYMin = yContainerCL.axisPixelsRange.min;
    double axisPixelsYMax = yContainerCL.axisPixelsRange.max;

    scaledFrom = ui.Offset(
      scaledX,
      yLabelsGenerator.lextrValueToPixels(
        value: fromY,
        axisPixelsMin: axisPixelsYMin,
        axisPixelsMax: axisPixelsYMax,
      ),
    );
    scaledTo = ui.Offset(
      scaledX,
      yLabelsGenerator.lextrValueToPixels(
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
      chartViewMaker: chartViewMaker,
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

/// Represents a column of [StackableValuePoint]s, with support for both stacked and non-stacked charts.
///
/// Corresponds to one column of data from [DeprecatedChartData.valuesRows], ready for presentation by [PointPresenter]s.
///
/// The
/// - unstacked (such as in the line chart),  in which case it manages
///   [stackableValuePoints] that have values from [DeprecatedChartData.valuesRows].
/// - stacked (such as in the bar chart), in which case it manages
///   [stackableValuePoints] that have values added up from [DeprecatedChartData.valuesRows].
///
/// Negative and positive points must be stacked separately,
/// to support correctly displayed stacked values above and below zero.
class PointsColumn {
  /// List of charted values in this column
  late List<StackableValuePoint> stackableValuePoints;

  /// List of stacked positive or zero value points - support for stacked type charts,
  /// where negative and positive points must be stacked separately,
  /// above and below zero.
  late List<StackableValuePoint> stackedPositivePoints; // non-negative actually

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

/// A list of [PointsColumn] instances, created from user data rows [DeprecatedChartData.valuesRows].
///
/// Represents the chart data created from the [DeprecatedChartData.valuesRows], but is an internal format suitable for
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
  final ChartViewMaker chartViewMaker;

  /// True if chart type presents values stacked.
  final bool _isStacked;

  final LayoutableBox _caller;

  /// Constructor creates a [PointsColumns] instance from [DeprecatedChartData.valuesRows] values in
  /// the passed [chartViewMaker.chartModel].
  PointsColumns({
    required this.chartViewMaker,
    required PointPresenterCreator pointPresenterCreator,
    required bool isStacked,
    required LayoutableBox caller,
  })  : _isStacked = isStacked,
        _caller = caller,
        super(growable: true) {
    _createStackableValuePointsFromChartData(chartViewMaker.chartModel);
  }

  /// Constructs internals of this object, the [PointsColumns].
  ///
  /// Transposes data passed as rows in [chartModel.valuesRows]
  /// to [_valuePointArrInRows] and to [_valuePointArrInColumns].
  ///
  /// Creates links on "this column" to "successor in stack on the right",
  /// managed in [PointsColumn.nextRightPointsColumn].
  ///
  /// Each element is the per column point below the currently processed point.
  /// The currently processed point is (potentially) stacked on it's predecessor.
  void _createStackableValuePointsFromChartData(ChartModel chartModel) {
    List<StackableValuePoint?> rowOfPredecessorPoints =
        List.filled(chartModel.valuesRows[0].length, null);
    for (int col = 0; col < chartModel.valuesRows[0].length; col++) {
      rowOfPredecessorPoints[col] = null; // new StackableValuePoint.initial(); // was:null
    }

    // Data points managed row.  Internal only, should be refactored away.
    List<List<StackableValuePoint>> valuePointArrInRows = List.empty(growable: true);

    for (int row = 0; row < chartModel.valuesRows.length; row++) {
      List<num> valuesRow = chartModel.valuesRows[row];
      List<StackableValuePoint> pointsRow = List<StackableValuePoint>.empty(growable: true);
      valuePointArrInRows.add(pointsRow);
      for (int col = 0; col < valuesRow.length; col++) {
        // yTransform data before placing data point on StackableValuePoint.
        num colValue = chartViewMaker.chartOptions.dataContainerOptions.yTransform(valuesRow[col]);

        // Create all points unstacked. A later processing can stack them,
        // depending on chart type. See [StackableValuePoint.stackOnAnother]
        var thisPoint = StackableValuePoint(
            chartViewMaker: chartViewMaker,
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
  ///   applying its [StackableValuePoint.lextrToPixels] method.
  /// - No extrapolating of the internal representation stored in [_valuePointArrInRows]
  ///   or [_valuePointArrInColumns].
  void lextrPointsColumns(ChartViewMaker chartViewMaker, ChartRootContainerCL chartRootContainer) {
    int col = 0;
    for (PointsColumn column in this) {
      column.allPoints().forEach((StackableValuePoint point) {
        double scaledX = chartRootContainer.xTickXs[col];
        point.lextrToPixels(
          scaledX: scaledX,
          yLabelsGenerator: chartViewMaker.yLabelsGenerator,
        );
      });
      col++;
    }
  }

  /// Makes this [PointsColumns] object a [BoxContainer] - like class,
  ///
  /// Offsets the coordinates of this [PointsColumns] kept in [ChartViewMaker.chartModel] by the [offset],
  /// presumable calle from parent [DataContainerCL].
  ///
  /// When called in DataContainer.applyParentOffset with the offset of DataContainer
  ///             dataContainerOffset = ui.Offset(yContainerSize.width, legendContainerSize.height);
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
    // todo 1 replace with expand like in: valuesRows.expand((i) => i).toList()
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
