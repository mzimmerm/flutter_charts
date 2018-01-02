import 'dart:ui' as ui
    show Size, Offset, Rect, Paint, TextAlign, TextDirection, Canvas;

import 'package:flutter_charts/src/util/collection.dart' as custom_collection
    show CustomList;

import 'dart:math' as math show max, min;

import 'package:flutter/widgets.dart' as widgets
    show TextStyle, TextSpan, TextPainter;

import 'package:flutter_charts/src/chart/label_container.dart';

import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/chart/data.dart';

import 'presenter.dart'; // V

import '../util/range.dart';
import '../util/util.dart' as util;
import 'package:flutter_charts/src/chart/line_container.dart';

/// Containers calculate coordinates of chart points
/// used for painting grid, labels, chart points etc.
///
/// Creates a simple chart container and call all needed [layout] methods.
///
/// Terms used:
///   - `absolute positions` refer to positions
///      "in the coordinates of the chart area" - the full size given to the
///      ChartPainter by the application.
abstract class ChartContainer {
  /// ##### Abstract methods or subclasses-implemented getters

  /// Makes presenters, the visuals painted on each chart column that
  /// represent data, (points and lines for the line chart,
  /// rectangles for the bar chart, and so on).
  ///
  /// See [PresenterCreator] and [Presenter] for more details.
  /// todo 1 : There may be a question "why does a container need to
  /// know about Presenter, even indirectly"?
  PresenterCreator presenterCreator;

  /// ##### Subclasses - aware members.

  /// Keeps data values grouped in columns.
  ///
  /// This column grouped data instance is managed here in the [ChartContainer],
  /// (immediate owner of [YContainer] and [DataContainer])
  /// as their data points are needed both during [YContainer.layout]
  /// to calculate scaling, and also in [DataContainer.layout] to create
  /// [PresentersColumns] instance.
  PointsColumns pointsColumns;

  bool isStacked;

  ChartOptions options;
  ChartData data;
  ui.Size chartArea;

  LegendContainer legendContainer;
  YContainer yContainer;
  XContainer xContainer;
  DataContainer dataContainer;

  // todo -5 vvvvvvvvvvvvvvvvvvvvvvvv
  /// Notes:
  ///   - The *ContainerSizes members are defined external maximums.
  ///       Containers always fill the containers external maximums,
  ///       so *ContainerSize also equals the containers' layed out size.
  ///   - The *ContainerSizes members include padding and margin
  ///   - The *ContainerOffset is where *ContainerSize (including pad and
  ///   margin) start.
  ui.Size legendContainerSize;
  ui.Offset legendContainerOffset;

  ui.Size xContainerSize;
  ui.Offset xContainerOffset;

  ui.Size yContainerSize;
  ui.Offset yContainerOffset;

  ui.Size dataContainerSize;
  ui.Offset dataContainerOffset;

  // todo -5 ^^^^^^^^^^^^^^^^^^^^^^^^

  /// Scaler of data values to values on the Y axis.
  YScalerAndLabelFormatter yScaler;

  /// Simple Container for a simple flutter chart.
  ///
  /// The simple flutter chart layout consists of only 2 major areas:
  ///   - [YContainer] area manages and lays out the Y labels area, by calculating
  ///     sizes required for Y labels (in both X and Y direction).
  ///     The [YContainer]
  ///   - [XContainer] area manages and lays out the
  ///     - X labels area, and the
  ///     - grid area.
  ///     In the X direction, takes up all space left after the
  ///     YContainer layes out the  Y labels area, that is, full width
  ///     minus [YContainer.yLabelsContainerWidth].
  ///     In the Y direction, takes
  ///     up all available chart area, except a top horizontal strip,
  ///     required to paint half of the topmost label.
  ChartContainer({
    ui.Size chartArea,
    ChartData chartData,
    ChartOptions chartOptions,
  }) {
    this.chartArea = chartArea;
    this.data = chartData;
    this.options = chartOptions;
  }

  layout() {
    // ### 1. Prepare early, from dataRows, the stackable points managed
    //        in [pointsColumns], as [YContainer] needs to scale y values and
    //        create labels from the stacked points (if chart is stacked).
    setupPointsColumns();

    // ### 2. Layout the legends on top

    legendContainer = new LegendContainer(
      chartContainer: this,
      availableWidth: chartArea.width,
    );

    legendContainer.layout();

    // todo -5 vvv
    legendContainerSize = legendContainer._size;
    legendContainerOffset = new ui.Offset(0.0, 0.0);
    // todo -5 ^^^

    // ### 3. Ask [YContainer] to provide Y label container width.
    //        This provides the remaining width left for the [XContainer]
    //        (grid and X axis) to use. The yLabelsMaxHeightFromFirstLayout
    //        is not relevant in this first call.
    double yContainerHeight = chartArea.height - legendContainerSize.height;

    var yContainerFirst = new YContainer(
      parentContainer: this,
      layoutExpansion: new LayoutExpansion(
          width: chartArea.width,
          widthExpansionStyle: ExpansionStyle.GrowDoNotFill,
          height: yContainerHeight,
          heightExpansionStyle: ExpansionStyle.TryFill),
      yLabelsMaxHeightFromFirstLayout: 0.0,
    );

    yContainerFirst.layout();

    double yLabelsMaxHeightFromFirstLayout = yContainerFirst.yLabelContainers
        .map((var yLabelContainer) => yLabelContainer)
        .map((LabelContainer labelContainer) =>
            labelContainer.textPainter.size.height)
        .reduce(math.max);

    this.yContainer = yContainerFirst;

    // todo -5 vvvvvvvvvvvvvvvvvvvvvvvv
    yContainerSize =
        new ui.Size(yContainerFirst._yLabelsContainerWidth, yContainerHeight);
    yContainerOffset = new ui.Offset(0.0, legendContainerSize.height);
    // todo -5 ^^^^^^^^^^^^^^^^^^^^^^^^

    // ### 4. Knowing the width required by Y axis
    //        (from first [YContainer.layout] call), we can layout X labels
    //        and grid in X direction, by calling [XContainer.layout].
    //        We do not give it the available height, although height may be
    //        marginally relevant (if there was not enough height for x labels).
    double xContainerWidth = chartArea.width - yContainerSize.width;

    this.xContainer = new XContainer(
        chartContainer: this,
        // todo 0 add padding, from options
        availableWidth: xContainerWidth);

    xContainer.layout();

    // todo -5 vvvvvvvvvvvvvvvvvvvvvvvv
    xContainerSize = new ui.Size(xContainerWidth,
        xContainer._xLabelsMaxHeight + 2 * options.xLabelsPadTB);
    xContainerOffset = new ui.Offset(
        yContainerSize.width, chartArea.height - xContainerSize.height);
    // todo -5 ^^^^^^^^^^^^^^^^^^^^^^^^

    // ### 5. Second call to YContainer is needed, as available height for Y
    //        is only known after XContainer provided height of xLabels
    //        on the bottom .
    //        The [yLabelsMaxHeightFromFirstLayout] are used to scale
    //        data values to the y axis, and put labels on ticks.

    // On the second real layout, make sure YContainer expand down only to
    //   the top of the XContainer area.
    this.yContainer = new YContainer(
      parentContainer: this,
      layoutExpansion: new LayoutExpansion(
          width: chartArea.width,
          widthExpansionStyle: ExpansionStyle.GrowDoNotFill,
          height: yContainerHeight - xContainerSize.height,
          heightExpansionStyle: ExpansionStyle.TryFill),
      yLabelsMaxHeightFromFirstLayout: yLabelsMaxHeightFromFirstLayout,
    );

    // print("   ### YContainer #2: before layout: ${yContainer}");
    yContainer.layout();

    // Note: yContainerSize and yContainerOffset did not change

    // Calculate what is left for the grid
    // todo -5 vvvvvvvvvvvvvvvvvvvvvvvv
    dataContainerSize = new ui.Size(
        chartArea.width - yContainerSize.width,
        chartArea.height -
            (legendContainerSize.height + xContainerSize.height));
    dataContainerOffset =
        new ui.Offset(yContainerSize.width, legendContainerSize.height);
    // todo -5 ^^^^^^^^^^^^^^^^^^^^^^^^

    // ### 6. Layout the data area, which included the grid
    // by calculating the X and Y positions of grid.
    // This must be done here after X and Y are layed out.

    this.dataContainer = new DataContainer(
      parentContainer: this,
      layoutExpansion: new LayoutExpansion(
          width: chartArea.width - yContainerSize.width,
          widthExpansionStyle: ExpansionStyle.TryFill,
          height: chartArea.height -
              (legendContainerSize.height + xContainerSize.height),
          heightExpansionStyle: ExpansionStyle.TryFill),
    );

    // dataContainer layout() must be called before applyParentOffset()
    //   to ensure the correct order of
    //   scalePointsColumns (first) and setupPresentersColumns (second)
    this.dataContainer.layout();

    // At the end, move the individual chart areas to their offsets.
    legendContainer.legendLabelContainers.forEach((legendLabelContainer) {
      legendLabelContainer.applyParentOffset(legendContainerOffset);
    });

    xContainer.xLabelContainers.forEach((XLabelContainer xLabelContainer) {
      xLabelContainer.applyParentOffset(
          new ui.Offset(yContainerSize.width, xContainerOffset.dy));
    });

    /* todo -10
    yContainer.yLabelContainers.forEach((YLabelContainer yLabelContainer) {
      yLabelContainer.applyParentOffset(
          new ui.Offset(options.yLabelsPadLR, yContainerOffset.dy));
    });
    */
    // todo -10 this may be wrong, fix this.
    yContainer.applyParentOffset(yContainerOffset);

    this.dataContainer.applyParentOffset(dataContainerOffset);
  }

  /// Create member [pointsColumns] from [data.dataRows].
  void setupPointsColumns() {
    this.pointsColumns = new PointsColumns(
      container: this,
      presenterCreator: this.presenterCreator,
      isStacked: this.isStacked,
    );
  }

  /// X coordinates of x ticks (x tick - middle of column, also middle of label).
  /// Once [XContainer.layout] and [YContainer.layout] are complete,
  /// this list drives the layout of [DataContainer].
  ///
  /// See [XLabelContainer.xTickX] for details.
  List<double> get xTickXs => xContainer.xLabelContainers
      .map((var xLabelContainer) => xLabelContainer.xTickX)
      .toList();

  /// Y coordinates of y ticks (y tick - scaled value of data, also middle of label).
  /// Once [XContainer.layout] and [YContainer.layout] are complete,
  /// this list drives the layout of [DataContainer].
  ///
  /// See [YLabelContainer.yTickY] for details.
  List<double> get yTickYs {
    return yContainer.yLabelContainers
        .map((var yLabelContainer) => yLabelContainer.yTickY)
        .toList();
  }

  double get gridStepWidth => xContainer._gridStepWidth;
}

/// Container of the Y axis labels.
///
/// The primary direction of this container is "Y", which means
/// this container will use all vertical (Y) space available.
///
/// In the horizontal (X) direction, this container will use limited width -
/// as much width as needed to display Y labels, Y axis, and spacing.
///
/// See the constructor [YContainer] for description of parameters that define
/// the available vertical space.
///
/// See [YContainer.layout] for description
/// of how this [YContainer.layout] calculates [YContainer._yLabelsContainerWidth],
/// the width taken by this container for the Y axis labels, and what
/// it means for the remaining space.
///
class YContainer extends ChartAreaContainer {

  /// Represents Y labels.
  List<YLabelContainer> yLabelContainers = new List();

  double _yLabelsContainerWidth;
  LayoutExpansion _layoutExpansion;
  double _yLabelsMaxHeightFromFirstLayout;

  YContainer({
    ChartContainer parentContainer,
    LayoutExpansion layoutExpansion,
    double yLabelsMaxHeightFromFirstLayout,
  }) : super(
  layoutExpansion: layoutExpansion,
  parentContainer: parentContainer,
  )
  {
    _yLabelsMaxHeightFromFirstLayout = yLabelsMaxHeightFromFirstLayout;
  }

  /// Lays out the area containing the Y axis labels.
  ///
  /// Out of calls to all container's [layout] by the parent
  /// [ChartContainer.layout], the call to this object's [layout] is second,
  /// after [LegendContainer.layout].
  /// This [YContainer.layout] calculates [YContainer._yLabelsContainerWidth],
  /// the width taken by this container for the Y axis labels.
  ///
  /// The remaining horizontal width of [ChartContainer.chartArea] minus
  /// [YContainer._yLabelsContainerWidth] provides remaining available
  /// horizontal space for the [GridContainer] and [XContainer].
  void layout() {

    // [yAxisMin] and [yAxisMax] define end points of the Y axis.
    // todo -7: layoutExpansion - max of yLabel height, and the 2 paddings

    // todo -7 flip Min and Max and find a place which reverses
    double yAxisMin = _layoutExpansion.height -
        (_parentContainer.options.xBottomMinTicksHeight +
            2 * _parentContainer.options.xLabelsPadTB);

    // todo -7: max of this and some padding
    double yAxisMax = _yLabelsMaxHeightFromFirstLayout / 2;

    if (_parentContainer.options.useUserProvidedYLabels) {
      layoutManually(yAxisMin, yAxisMax);
    } else {
      layoutAutomatically(yAxisMin, yAxisMax);
    }
    _yLabelsContainerWidth = yLabelContainers
            .map((var yLabelContainer) => yLabelContainer)
            .map((LabelContainer labelContainer) =>
                labelContainer.textPainter.size.width)
            .reduce(math.max) +
        2 * _parentContainer.options.yLabelsPadLR;
  }

  /// Manually layout Y axis by evenly dividing available height to all Y labels.
  void layoutManually(double yAxisMin, double yAxisMax) {
    List<double> flatData = _parentContainer.pointsColumns
        .flattenPointsValues(); // todo -1 move to common layout, same for manual and auto

    List<String> yLabels = _parentContainer.data.yLabels;

    var dataRange =
        new Interval(flatData.reduce(math.min), flatData.reduce(math.max));
    double dataStepHeight =
        (dataRange.max - dataRange.min) / (yLabels.length - 1);

    Interval yAxisRange = new Interval(yAxisMin, yAxisMax);

    double gridStepHeight =
        (yAxisRange.max - yAxisRange.min) / (yLabels.length - 1);

    List<num> yLabelsDividedInYAxisRange = new List();
    //var seq = new Iterable.generate(yLabels.length, (i) => i); // 0 .. length-1
    //for (var yIndex in seq) {
    for (var yIndex = 0; yIndex < yLabels.length; yIndex++) {
      yLabelsDividedInYAxisRange.add(yAxisRange.min + gridStepHeight * yIndex);
    }

    List<num> yLabelsDividedInYDataRange = new List();
    for (var yIndex = 0; yIndex < yLabels.length; yIndex++) {
      yLabelsDividedInYDataRange.add(dataRange.min + dataStepHeight * yIndex);
    }

    var yScaler = new YScalerAndLabelFormatter(
        dataRange: dataRange,
        valueOnLabels: yLabelsDividedInYAxisRange,
        toScaleMin: yAxisMin,
        toScaleMax: yAxisMax,
        chartOptions: _parentContainer.options);

    yScaler.setLabelValuesForManualLayout(
        labelValues: yLabelsDividedInYDataRange,
        scaledLabelValues: yLabelsDividedInYAxisRange,
        formattedYLabels: yLabels);

    _commonLayout(yScaler);
  }

  /// Generates scaled and spaced Y labels from data, then auto layouts
  /// them on the Y axis according to data range [range] and display
  /// range [yAxisMin] to [yAxisMax].
  void layoutAutomatically(double yAxisMin, double yAxisMax) {
    List<double> flatData = _parentContainer.pointsColumns
        .flattenPointsValues(); // todo -1 move to common layout, same for manual and auto

    // print("flatData=$flatData");

    Range range = new Range(
        values: flatData, chartOptions: _parentContainer.options, maxLabels: 10);

    // revert toScaleMin/Max to accomodate y axis starting from top
    YScalerAndLabelFormatter yScaler = range.makeLabelsFromDataOnScale(
      toScaleMin: yAxisMin,
      toScaleMax: yAxisMax,
    );

    _commonLayout(yScaler);
  }

  void _commonLayout(YScalerAndLabelFormatter yScaler) {
    // Retain this scaler to be accessible to client code,
    // e.g. for coordinates of value points.
    _parentContainer.yScaler = yScaler;
    ChartOptions options = _parentContainer.options;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = new LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.labelTextAlign, // center text
      textScaleFactor: options.labelTextScaleFactor,
    );
    // Create Y Labels (yLabelContainers)
    // yLabelContainers are created from  yScaler.labelInfos positions.
    for (LabelInfo labelInfo in yScaler.labelInfos) {
      // yTickY is both scaled data value and vertical (Y) center of the label.
      double yTickY = labelInfo.scaledLabelValue;
      var yLabelContainer = new YLabelContainer(
        label: labelInfo.formattedYLabel,
        labelMaxWidth: double.INFINITY,
        labelStyle: labelStyle,
      );
      yLabelContainer.textPainter.layout();
      double labelTopY = yTickY - yLabelContainer.textPainter.height / 2;

      yLabelContainer.yTickY = yTickY - labelTopY;

      // Move the contained LabelContainer to correct position
// todo -10      yLabelContainer.applyParentOffset(new ui.Offset(0.0, labelTopY));
      yLabelContainer.applyParentOffset(
          new ui.Offset(_parentContainer.options.yLabelsPadLR, labelTopY),
      );

      yLabelContainers.add(yLabelContainer);
    }
  }

  // todo -10 vvvvvvv
  void applyParentOffset(ui.Offset offset) {
    // super not really needed - only child containers are offset.
    super.applyParentOffset(offset);

    yLabelContainers.forEach((YLabelContainer yLabelContainer) {
      yLabelContainer.applyParentOffset(offset);
    });
  }

  ui.Size get layoutSize {
    // todo -10 this is copied, fix
    // todo -7: assert that layed out size (looking into all members)
    //          is same as the pre-layout size returned here
    // return new ui.Size(_layoutExpansion.width, _layoutExpansion.height);
    return new ui.Size(_yLabelsContainerWidth, _layoutExpansion.height);
  }

  void paint(ui.Canvas canvas) {
    // todo -10
    for (var yLabelContainer in yLabelContainers) {
      yLabelContainer.paint(canvas);
    }
  }

  // ^^^^^^^^^^^^^^^

  String toString() {
    return ", _yLabelsContainerWidth = ${_yLabelsContainerWidth}";
  }
}

/// A Wrapper of [YContainer] members that can be used by clients
/// to layout y labels container.

/// Generally, the owner of this object decides what the offsets are:
///   - If owner is YContainer, all positions are relative to the top of
///     the container of y labels
///   - If owner is Area [ChartContainer], all positions are relative
///     to the top of the available [chartArea].
class YLabelContainer extends LabelContainer {
  ///  y offset of Y label middle point.
  ///
  ///  Also is the y offset of point that should
  /// show a "tick dash" for the label center on the y axis.
  ///
  /// First "tick dash" is on the first label, last on the last label,
  /// but y labels can be skipped.
  ///
  double yTickY;

  YLabelContainer({
    String label,
    double labelMaxWidth,
    LabelStyle labelStyle,
  })
      : super(
          label: label,
          labelMaxWidth: labelMaxWidth,
          labelStyle: labelStyle,
        );

  /// Apply offset in parent. This call positions the Y Label (this instance)
  /// to the absolute position in the chart's available size
  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);
    yTickY += offset.dy;
  }

}

/// Auto-container of chart in the independent (X) axis direction.
///
/// Number of independent (X) values (length of each data row)
/// is assumed to be the same as number of
/// xLabels, so that value can be used interchangeably.
///
/// Note:
///   - As a byproduct this lays out the X labels in their container.
///   - Containers may use Painters, for example for text (`TextSpan`),
///     for which we do not know any sizing needed for the Containers,
///     until we call `TextPainter(text: textSpan).layout()`.
///     provided by LabelContainer.textPainterForLabel(String string)
///   - todo add iterations that allow layout size to be negotiated.
///     The above requires a Area container or similar object, that can ask
///     this object to recalculate
///     - skip labels to fit
///     - rotate labels to fit
///     - decrease font size to fit
///   - clients will typically make use of this object after [layout]
///     has been called on it
///
/// Assumes:
///   - Number of labels is the same as number of independent (X) axis points
///     for all values

class XContainer {
  /// The containing container.
  ChartContainer _chartContainer;

  // ### input values

  List<String> _xLabels; // todo -6 remove. Replace by painters.labelContainer
  double _availableWidth;

  // ### calculated values

  /// Results of laying out the x axis labels, usabel by clients.
  List<XLabelContainer> xLabelContainers = new List();

  double _xLabelsMaxHeight;
  double _gridStepWidth;

  /// Constructor gives this container access to it's
  /// layouting Area [chartContainer], giving it [availableWidth],
  /// which is currently the full [chartContainer.chartArea] width.
  ///
  /// This container uses the full [availableWidth], and takes as
  /// much height as needed for X labels to be painted.
  ///
  XContainer({
    ChartContainer chartContainer,
    double availableWidth,
  }) {
    _chartContainer = chartContainer;
    _xLabels = _chartContainer.data.xLabels;
    _availableWidth = availableWidth;
  }

  /// Lays out the chart in horizontal (x) direction.

  /// Evenly divides the available width to all labels.
  /// First / Last vertical line is at the center of first / last label,
  ///
  /// Label width includes spacing on each side.
  ///
  /// In X direction, the X labels parent offset is 0.0  starts on the very
  /// left of the rectangle available for the chart.
  layout() {
    double yTicksWidth = _chartContainer.options.yLeftMinTicksWidth +
        _chartContainer.options.yRightMinTicksWidth;

    double labelMaxAllowedWidth =
        (_availableWidth - yTicksWidth) / _xLabels.length;

    _gridStepWidth = labelMaxAllowedWidth;

    ChartOptions options = _chartContainer.options;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = new LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.labelTextAlign, // center text
      textScaleFactor: options.labelTextScaleFactor,
    );

    for (var xIndex = 0; xIndex < _xLabels.length; xIndex++) {
      // double leftX = _gridStepWidth * xIndex;
      var xLabelContainer = new XLabelContainer(
        label: _xLabels[xIndex],
        labelMaxWidth: double.INFINITY,
        labelStyle: labelStyle,
      );

      // core of X layout calcs - lay out label and find middle
      var textPainter = xLabelContainer.textPainter;
      textPainter.layout();

      double halfLabelWidth = textPainter.width / 2;
      double halfStepWidth = _gridStepWidth / 2;
      double atIndexOffset = _gridStepWidth * xIndex;
      double xTickX = halfStepWidth +
          atIndexOffset +
          _chartContainer.options
              .yLeftMinTicksWidth; // Start stepping after painting left Y tick
      double labelLeftX = xTickX - halfLabelWidth; // same center - tickX, label

      xLabelContainer.xTickX = xTickX - labelLeftX;

      // Move xLabelContainer down by option value inside XContainer
      xLabelContainer
          .applyParentOffset(new ui.Offset(labelLeftX, options.xLabelsPadTB));

      xLabelContainers.add(xLabelContainer);
    }

    // xlabels area without padding
    _xLabelsMaxHeight = xLabelContainers
        .map((var xLabelContainer) => xLabelContainer.textPainter)
        .map((widgets.TextPainter painter) => painter.size.height)
        .reduce(math.max);
  }
}

/// A Wrapper of [XContainer] members that can be used by clients
/// to layout x labels container.
///
/// All positions are relative to the left of the container of x labels
class XLabelContainer extends LabelContainer {
  /// The X position of point that should
  /// show a "tick dash" for the label center on the x axis.
  ///
  /// Notes:
  ///   - This is same as the X-scaled position of the X value
  ///   (only relevant for measured X variable,
  ///   for ordinal X variable, the X value is simply made evenly
  ///   spaced across X available space).
  ///   - Also same as the position of middle of X label wrapped
  ///   in this [textPainter].
  ///
  /// The actual value changes after call to [applyParentOffset].
  ///
  /// Equal to the x offset of X label middle point.
  ///
  /// First "tick dash" is on the first label, last on the last label.
  double xTickX;

  XLabelContainer({
    String label,
    double labelMaxWidth,
    LabelStyle labelStyle,
  })
      : super(
          label: label,
          labelMaxWidth: labelMaxWidth,
          labelStyle: labelStyle,
        );

  /// Apply offset in parent. This call positions the X Label (this instance)
  /// to the absolute position in the chart's available size
  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);
    xTickX += offset.dx;
   //  _offset += offset;
  }

}

enum ExpansionStyle { TryFill, GrowDoNotFill }

/// Defines how a container [layout] should expand the container in a direction.
///
/// Direction can be "width" or "height".
///
/// Generally,
///   - If direction style is [TryFill], the container should use all
///     available length in the direction (that is, [width] or [height].
///     This is intended to fill a predefined
///     available length, such as show X axis labels
///   - If direction style is [GrowDoNotFill], container should use as much space
///     as needed in the direction, but stop well before the available length.
///     The "well before" is not really defined here.
///     This is intended to for example layout Y axis in X direction,
///     where we want to put the data container to the right of the Y labels.
///
///
class LayoutExpansion {
  double width;
  ExpansionStyle widthExpansionStyle;
  double height;
  ExpansionStyle heightExpansionStyle;

  LayoutExpansion(
      {this.width,
      this.widthExpansionStyle,
      this.height,
      this.heightExpansionStyle}) {
    if (this.width <= 0.0) {
      throw new StateError("Invalid width $width");
    }
    if (this.height <= 0.0) {
      throw new StateError("Invalid height $height");
    }
  }
}

/// Base class which manages, lays out, moves, and paints
/// graphical elements on the chart, for example individual
/// labels, but also a collection of labels.
///
/// This base class manages
///
/// Roles:
///   - Constructor: a paramater named [layoutExpansion] is required
///   - Container: through the [layout] method.
///   - Translator (in X and Y direction): through the [applyParentOffset]
///     method.
///   - Painter: through the [paint] method.
///
/// Note on Lifecycle of [Container] : objects should be such that
///       after construction, methods should be called in the order declared
///       here.
///
abstract class Container {
  /// External size enforced by the parent container.
  LayoutExpansion _layoutExpansion;

  /// Maintains current offset, a sum of all offsets
  /// passed in subsequent calls to [applyParentOffset] during object
  /// lifetime.
  ui.Offset _offset = ui.Offset.zero;

  Container({
    LayoutExpansion layoutExpansion,
  }) {
    _layoutExpansion = layoutExpansion;
  }

  void layout();

  void applyParentOffset(ui.Offset offset) {
    _offset += offset;
  }

  /// Size after [layout] has been called.
  ui.Size get layoutSize;

  /// Provides access to offset for extension's [paint] methods.
  ui.Offset get offset => _offset;

  /// Answers the requested expansion sizes.
  ///
  /// Before layout, clients may need to ask for expansion,
  /// as that gives a reliabel pre-layout size in directions
  /// where [ExpansionStyle == ExpansionStyle.TryFill]
  LayoutExpansion get layoutExpansion => _layoutExpansion;

  double get containerHeight {
    if (layoutExpansion.heightExpansionStyle != ExpansionStyle.TryFill) {
      throw new StateError(
          "Before layout, cannot ask for height if style is not ${ExpansionStyle.TryFill}. " +
              "If asking after layout, call [layoutSize]");
    }

    return layoutExpansion.height;
  }

  double get containerWidth {
    if (layoutExpansion.widthExpansionStyle != ExpansionStyle.TryFill) {
      throw new StateError(
          "Before layout, cannot ask for width if style is not ${ExpansionStyle.TryFill}. " +
              "If asking after layout, call [layoutSize]");
    }

    return layoutExpansion.width;
  }

  void paint(ui.Canvas canvas);
}


/// Base class which manages, lays out, moves, and paints
/// each top level block on the chart. The basic top level chart blocks are:
///   - [ChartContainer] - the whole chart
///   - [LegendContainer] - manages the legend
///   - [YContainer] - manages the Y labels layout, which defines:
///     - Y axis label sizes
///     - Y positions of Y axis labels, defined as yTickY.
///       yTicksY s are the Y points of scaled data values
///       and also Y points on which the Y labels are centered.
///   - [XContainer] - Equivalent to YContainer, but manages X direction
///     layout and labels.
///   - [DataContainer] - manages the area which displays:
///     - Data as bar chart, line chart, or other chart type.
///     - Grid (this includes the X and Y axis).
///
/// See [Container] for discussion of roles of this class.
/// This extension of  [Container] has the added ability
/// to access the container's parent, which is handled by
/// [parentContainer].
abstract class ChartAreaContainer extends Container {
  /// The chart top level.
  ///
  /// Departure from a top down approach, this allows to
  /// access the parent [ChartContainer], which has (currently)
  /// members needed by children.
  ChartContainer _parentContainer;

  ChartAreaContainer({
    ChartContainer parentContainer,
    LayoutExpansion layoutExpansion,
  }) : super(layoutExpansion: layoutExpansion) {
    _parentContainer = parentContainer;
  }

  ChartContainer get parentContainer => _parentContainer;
}


/// Manages the core chart area which displays, overlayed:
///   - Data - as columns of bar chart, line chart, or other chart type
///   - The grid (this includes the X and Y axis).
class DataContainer extends ChartAreaContainer {
  GridLinesContainer _xGridLinesContainer;
  GridLinesContainer _yGridLinesContainer;

  /// Columns of presenters.
  ///
  /// Presenters may be:
  ///   - points and lines in line chart
  ///   - bars (stacked or grouped) in bar chart
  ///
  /// todo 0 replace with getters; see if members can be made private,  manipulated via YLabelContainer.
  PresentersColumns presentersColumns;

  DataContainer({
    ChartContainer parentContainer,
    LayoutExpansion layoutExpansion,
  })
      : super(
          layoutExpansion: layoutExpansion,
          parentContainer: parentContainer,
        );

  void layout() {
    _layoutGrid();

    // Scale the [pointsColumns] to the [YContainer] 's scale.
    scalePointsColumns();
  }

  void _layoutGrid() {
    // Vars that layout needs from the [_chartContainer] passed to constructor
    ChartOptions options = parentContainer.options;
    bool isStacked = parentContainer.isStacked;
    double xGridStep = parentContainer.gridStepWidth;
    ChartContainer chartContainer = parentContainer;

    // ### 1. Vertical Grid (yGrid) layout:

    // For each already layed out X labels in [xLabelContainers],
    // create one [LineContainer] and add it to [yGridLinesContainer]

    this._yGridLinesContainer = new GridLinesContainer();

    chartContainer.xTickXs.forEach((xTickX) {
      // Add vertical yGrid line in the middle or on the left
      double x = isStacked ? xTickX - xGridStep / 2 : xTickX;

      LineContainer yLineContainer = new LineContainer(
        lineFrom: new ui.Offset(x, 0.0),
        lineTo: new ui.Offset(x, containerHeight),
        linePaint: gridLinesPaint(options),
      );

      // Add a new vertical grid line - yGrid line.
      this._yGridLinesContainer.addLine(yLineContainer);
    });

    // For stacked, we need to add last right vertical yGrid line
    if (isStacked && chartContainer.xTickXs.isNotEmpty) {
      double x = chartContainer.xTickXs.last + xGridStep / 2;
      LineContainer yLineContainer = new LineContainer(
          lineFrom: new ui.Offset(x, 0.0),
          lineTo: new ui.Offset(x, containerHeight),
          linePaint: gridLinesPaint(options));
      this._yGridLinesContainer.addLine(yLineContainer);
    }

    // ### 2. Horizontal Grid (xGrid) layout:

    // Iterate yLabels and for each add a horizontal grid line
    // When iterating Y labels, also create the horizontal lines - xGridLines
    this._xGridLinesContainer = new GridLinesContainer();

    // Position the horizontal xGrid at mid-points of labels at yTickY.
    chartContainer.yTickYs.forEach((yTickY) {
      LineContainer xLineContainer = new LineContainer(
          lineFrom: new ui.Offset(0.0, yTickY),
          lineTo: new ui.Offset(this._layoutExpansion.width, yTickY),
          linePaint: gridLinesPaint(options));

      // Add a new horizontal grid line - xGrid line.
      this._xGridLinesContainer._lineContainers.add(xLineContainer);
    });
  }

  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);

    // Move all container atomic elements - lines, labels, circles etc
    this._xGridLinesContainer.applyParentOffset(offset);

    // draw vertical grid
    this._yGridLinesContainer.applyParentOffset(offset);

    // Apply offset of lines and bars.
    parentContainer.pointsColumns.applyParentOffset(offset);

    // Any time offset of [_chartContainer.pointsColumns] has changed,
    //   we have to recreate the absolute positions
    //   of where to draw data points, data lines and data bars.
    setupPresentersColumns();
  }

  ui.Size get layoutSize {
    // todo -7: assert that layed out size (looking into all members)
    //          is same as the pre-layout size returned here
    return new ui.Size(_layoutExpansion.width, _layoutExpansion.height);
  }

  void paint(ui.Canvas canvas) {
    // draw horizontal grid
    this._xGridLinesContainer.paint(canvas);

    // draw vertical grid
    this._yGridLinesContainer.paint(canvas);

    // todo -77 move here painting of lines and bars.
    //         Look at VerticalBarChartPainter extends ChartPainter
    //         and rename drawPresentersColumns to paint
    //         But needs to take care of some things
  }

  // ##### Scaling and layout methods of [_chartContainer.pointsColumns]
  //       and [presentersColumns]

  /// Scales all data stored in leafs of columns and rows
  /// as [StackableValuePoint]. Depending on whether we are layouting
  /// a stacked or unstacked chart, scaling is done on stacked or unstacked
  /// values.
  ///
  /// Must be called before [setupPresentersColumns] as [setupPresentersColumns]
  /// uses the  absolute scaled [parentContainer.pointsColumns].
  void scalePointsColumns() {
    parentContainer.pointsColumns.scale();
  }

  /// Creates from [ChartData] (model for this container),
  /// columns of leaf values encapsulated as [StackableValuePoint]s,
  /// and from the values, the columns of leaf presenters,
  /// encapsulated as [Presenter]s.
  ///
  /// The resulting elements (points and presenters) are
  /// stored in member [presentersColumns].
  /// This is a core method that must run at the end of layout.
  /// Painters use the created leaf presenters directly to draw lines, points,
  /// and bars from the presenters' prepared ui elements:
  /// lines, points, bars, etc.

  void setupPresentersColumns() {
    this.presentersColumns = new PresentersColumns(
      pointsColumns: parentContainer.pointsColumns,
      container: parentContainer,
      presenterCreator: parentContainer.presenterCreator,
    );
  }
}

class GridLinesContainer extends Container {
  List<LineContainer> _lineContainers = new List();

  void addLine(LineContainer lineContainer) {
    _lineContainers.add(lineContainer);
  }

  // #####  Implementors of method in superclass [Container].

  void layout() {
    _lineContainers.forEach((lineContainer) => lineContainer.layout());
  }

  /// Overriden from super. Applies offset on all members.
  void applyParentOffset(ui.Offset offset) {
    _lineContainers
        .forEach((lineContainer) => lineContainer.applyParentOffset(offset));
  }

  void paint(ui.Canvas canvas) {
    _lineContainers.forEach((lineContainer) => lineContainer.paint(canvas));
  }

  /// Implementor of method in superclass [Container].
  ///
  /// Return the size of the outhermost rectangle which contains all lines
  ///   in the member _xLineContainers.
  // ui.Size get layoutSize => _xLineContainers.reduce((lineContainer.+));
  ui.Size get layoutSize => throw new StateError("todo -3 implement this.");
}

/// Lays out the legend area for the chart.
///
/// The legend area contains individual legend items. Each legend item
/// has a color square and text, which describes one data row (that is,
/// one data series).
///
/// Currently, each individual legend item is given the same size.
/// This is not very efficient but simple, so legend text should be short
class LegendContainer {
  /// The containing container.
  ChartContainer _chartContainer;

  double _availableWidth;

  /// Offset-free size contains the whole layed out area of legend.
  ui.Size _size;

  // ### calculated values

  /// Results of laying out the legend labels. Each member is one series label.
  List<LegendLabelContainer> legendLabelContainers = new List();

  /// Constructor gives this container access to it's
  /// layouting Area [chartContainer], giving it [availableWidth],
  /// which is currently the full width of the [chartArea].
  ///
  /// This container uses the full [availableWidth], and takes as
  /// much height as needed for legend labels to be painted.
  ///
  LegendContainer({
    ChartContainer chartContainer,
    double availableWidth,
  }) {
    _chartContainer = chartContainer;
    _availableWidth = availableWidth;
  }

  /// Lays out the legend area.
  ///
  /// Evenly divides available width to all legend items.
  layout() {
    ChartOptions options = _chartContainer.options;
    List<String> dataRowsLegends = _chartContainer.data.dataRowsLegends;
    LegendItemSizing itemSizing = new LegendItemSizing(
      options: options,
      availableWidth: _availableWidth,
      numLegendItems: dataRowsLegends.length,
    );

    // todo -3 Call the layoutUntilFitsParent here
    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = new LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.labelTextAlign, // center text
      textScaleFactor: options.labelTextScaleFactor,
    );

    // First paint all legends, to figure out max height of legends to center all
    // legends label around common center.
    // (todo -1 - is this ^^^ needed? can text of same font be diff. height)

    var maxItemSize = ui.Size.zero;
    for (var index = 0; index < dataRowsLegends.length; index++) {
      LabelContainer labelContainer = new LabelContainer(
        label: dataRowsLegends[index],
        labelMaxWidth: double.INFINITY,
        labelStyle: labelStyle,
      );
      labelContainer.textPainter.layout();
      widgets.TextPainter textPainter = labelContainer.textPainter;
      maxItemSize = new ui.Size(math.max(maxItemSize.width, textPainter.width),
          math.max(maxItemSize.height, textPainter.height));
    }

    // Now we know legend container size.width and height (width is unused)
    // From there, get the size of one legend item todo -3 : really??
    _size = new ui.Size(
        maxItemSize.width,
        math.max(maxItemSize.height, itemSizing.indicatorHeight) +
            2 * itemSizing.containerMarginTB);

    // Layout legend core: for each row, create and position
    //   - an indicator rectangle and it's paint
    //   - label painter
    for (var index = 0; index < dataRowsLegends.length; index++) {
      var legendLabelContainer = new LegendLabelContainer(
        label: dataRowsLegends[index],
        labelMaxWidth: double.INFINITY,
        labelStyle: labelStyle,
      );
      widgets.TextPainter textPainter = legendLabelContainer.textPainter;
      textPainter.layout();

      double indicatorX =
          itemSizing.legendItemWidth * index + itemSizing.containerMarginLR;

      // height-wise center both indicatorRect and label around common
      // middle in  _size.height / 2
      double indicatorTop = (_size.height - itemSizing.indicatorHeight) / 2;
      legendLabelContainer._indicatorRect = new ui.Offset(
              indicatorX, indicatorTop) &
          new ui.Size(itemSizing.indicatorWidth, itemSizing.indicatorHeight);

      double labelLeftX = indicatorX +
          itemSizing.indicatorWidth +
          itemSizing.indicatorToLegendPad;

      // todo -10 labelTopY Is all this needed?
      double labelTopY = (_size.height - textPainter.height) / 2;
      legendLabelContainer._offset = new ui.Offset(labelLeftX, labelTopY);

      legendLabelContainer._indicatorPaint = new ui.Paint();
      legendLabelContainer._indicatorPaint.color = _chartContainer.data
          .dataRowsColors[index % _chartContainer.data.dataRowsColors.length];

      legendLabelContainers.add(legendLabelContainer);
    }
  }

  /// todo -4 finish and document
/*
  List<LegendLabelContainer> overflownLabelContainers() {
    this.outputs.where((output) {output.labelContainer.})
  }
  */
}

/// A value class, manages the maximum boundaries of one legend item :
/// one color square + legend text.
class LegendItemSizing {
  ChartOptions _options;
  double _availableWidth;
  int _numLegendItems;

  /// Maximum boundaries of one legend item : one color square + legend text
  LegendItemSizing({
    ChartOptions options,
    double availableWidth,
    int numLegendItems,
  }) {
    _options = options;
    _availableWidth = availableWidth;
    _numLegendItems = numLegendItems;
  }

  double get indicatorToLegendPad => _options.legendColorIndicatorPaddingLR;

  double get indicatorWidth => _options.legendColorIndicatorWidth;

  double get indicatorHeight => indicatorWidth;

  double get containerMarginTB => _options.legendContainerMarginTB;

  double get containerMarginLR => _options.legendContainerMarginLR;

  // Allocated width of one color square + legend text (one legend item)
  double get legendItemWidth =>
      (_availableWidth - 2 * containerMarginLR) / _numLegendItems;

  // Allocated width of one legend text
  double get legendLabelWidth =>
      legendItemWidth - (indicatorWidth + 2 * containerMarginLR);
}

/// Represents one layed out item of the legend: [_indicatorRect] is
/// the rectangle for the color indicator, this [textPainter] is a layed out
/// [widgets.TextPainter] for the label text.
///
/// Painters can paint this object in a loop similar to
/// ```
/// void drawLegend(ui.Canvas canvas) {
///    for (common.LegendLabelContainer legend in container.legendLabelContainers) {
///      legend.labelContainer.paint(canvas, legend.labelOffset);
///      canvas.drawRect(legend.indicatorRect, legend.indicatorPaint); }}
/// ```
///
/// All positions are relative to the left of the [LegendContainer]'s container.
class LegendLabelContainer extends LabelContainer {
  ///  rectangle of the legend color square series indicator
  ui.Rect _indicatorRect;

  /// Paint used to paint the indicator
  ui.Paint _indicatorPaint;

  LegendLabelContainer({
    String label,
    double labelMaxWidth,
    LabelStyle labelStyle,
  })
      : super(
          label: label,
          labelMaxWidth: labelMaxWidth,
          labelStyle: labelStyle,
        );

  /// Overriden super's [paint] to also paint the rectangle indicator square.
  void paint(ui.Canvas canvas) {
    this.textPainter.paint(canvas, _offset);
    canvas.drawRect(_indicatorRect, _indicatorPaint);
  }
}

/// Lays out a list of labels horizontally,
/// makes labels evenly sized, and evenly spaced.
///
/// The motivation for this class is to layout labels when
/// the horizontal (X) space is restricted, and we want to manipulate
/// the label positions to automatically scale to fit.
///
/// Layout is forced to fit
/// by ensuring all labels fit within the X direction space
/// by decreasing the font size, tilting the labels, or skipping some labels,
/// or (last resource??) trimming the labels.
///
/// todo -2: No attempt is made to decrease Y direction size (height), but if
/// the passed [_maxHeight] is finite, a validity check is made
/// if the actual layed out height is within the passed height.
///
/// Instances are created from a label list; each label is
/// wrapped as a [LabelContainer] instance. All member [LabelContainer] instances
/// in [labelContainers] share the text properties (style, direction, align etc.)
/// of this parent instance
///
/// The initial text style of member [labelContainers] is from [ChartOptions].
/// The motivation is that a calling auto-fit program will change the text
/// style to fit a defined width.
///
/// Provides methods to
///   - Layout member labelContainers, for the purpose of
///   finding if they overflow their even size width.
///   - Change text style for all labels (by setting members and applying
///   them on the member [labelContainers].
///   - Layout the container by laying out the contained [labelContainers]
///   - Query size needed to paint each [labelContainers] and the whole container.
class HorizontalFixedWidthAutoScaledLabelsContainer {
  List<String> _labels;

  /// Wrappers for label strings
  List<LabelContainer> _labelContainers;

  /// Width of container. This is the fixed width this container
  /// must fill
  double _width;

  double _maxHeight = double.INFINITY;

  double _calculatedHeight;

  ChartOptions _options;

  /// Padding left of the leftmost label
  double _leftPad;

  /// Padding between each label
  double _betweenPad;

  /// Padding right of the rightmost label
  double _rightPad;

  bool _layoutClean = false;

  // TODO -4 STORING LABELSTYLE AS MEMBER IS TEMPORARY WHILE WE ARE PLUGGING FixedWidthHorizontalLabelsContainer TO X LABELS AND LEGEND LAYOUT, LAYOUTING ONCE
  LabelStyle _labelStyle;

  /// Calculated width allocated to each label.
  ///
  /// This width does not depend on text style - it is calculated
  /// by evenly dividing the available container width (total width, taking
  /// into account padding) by the number of labels.
  double get allocatedLabelWidth {
    double perLabelWidth =
        (_width - (_leftPad + (_labels.length - 1) * _betweenPad + _rightPad)) /
            _labels.length;
    if (perLabelWidth <= 0.0) {
      throw new StateError("Container does not leave space for labels.");
    }
    return perLabelWidth;
  }

  // todo -3
  /*
  double get layedoutHeight {

  };
  */

  /// Validate height of this container against constructor [_maxHeight].
  /// todo -3
  double get validateHeight {
    if (_maxHeight != double.INFINITY) {
      if (_maxHeight - _calculatedHeight > util.epsilon) {
        throw new StateError("Invalid size: $_maxHeight,  $_calculatedHeight");
      }
      return _calculatedHeight;
    }
    throw new StateError("Do not need to ask.");
  }

  bool isTooBig = true; // transient layout helper

  /// Constructs the container that must fit into a fixed boundary
  /// defined by the [width] parameter.
  ///
  /// Constraints
  ///   - [_width] must be set to a finite value
  ///     (not double.INFINITY). todo -2 add condition
  ///   -  [_maxHeight] is optional; it may be INFINITY (in most cases would be).
  ///      If not INFINITY, a validation is performed for height overflow todo -2 add condition
  ///
  /// Note: This class does not keep the LabelStyle,
  ///       just passes it to member [LabelContainer]s.
  HorizontalFixedWidthAutoScaledLabelsContainer({
    List<String> labels,
    double width,
    double maxHeight,
    ChartOptions options,
    double leftPad,
    double betweenPad,
    double rightPad,
  }) {
    _labels = labels;
    _width = width;
    _maxHeight = maxHeight; // optional
    _options = options;
    _leftPad = leftPad;
    _betweenPad = betweenPad;
    _rightPad = rightPad;

    // Instance is created from a label list; each label is
    //   wrapped as a [LabelContainer] instance.
    // The initial text style of member [labelContainers] is from [ChartOptions].
    // All member [LabelContainer] instances
    //   in [labelContainers] share the text properties (style, direction, align etc.)
    //   of this parent instance
    _options = options;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = new LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.labelTextAlign, // center text
      textScaleFactor: options.labelTextScaleFactor,
    );
    _labelStyle = labelStyle;

    _labelContainers = labels.map((label) {
      return new LabelContainer(
        label: label,
        labelMaxWidth: allocatedLabelWidth,
        labelStyle: labelStyle,
      );
    }).toList();
  }

  /// Provides methods to
  ///   - Layout individual [labelContainers], for the purpose of
  ///   finding if they overflow their even size width.
  ///
  /// anyLabelOverflows() - must be called after layoutIndividualLabels()
  ///

  ///   - Change text style for all labels (by setting members and applying
  ///   them on the member [labelContainers].
  ///   - Layout the container by laying out the contained [labelContainers].
  ///   This should layout to maxWidth, and throw exception on overflow.
  ///   - Query size needed to paint each [labelContainers] and the whole container.

  /// todo -3 add all method signatures first, implement next
  /// - layout the container with each label at evenly spaced positions
  void layoutQuaranteeFitFirstTiltNextDecreaseFontNextSkipNextTrim() {
    // TODO -4 FOR NOW, JUST LAYOUT, ONCE, NOT CHECKING FOR OVERFLOW
    _applyStyleThenLayoutAndCheckOverflow(labelStyle: _labelStyle);

    // todo -3
    // call layoutAndCheckOverflow on all labelContainers
    // if at least one overflows, tilt all labels by -70 degrees
    // etc.
  }

  /// Layout member [_labelContainers] forcing the max width and
  /// check for overflow.
  ///
  /// Returns `true` if at least one element of [_labelContainers] overflows,
  /// `false` otherwise.
  ///
  /// As a sideeffect, if false is returned, all  [_labelContainers] were
  /// layoued out, and can be painted.
  bool _layoutAndCheckOverflow() {
    // same as label_painted, on all
    return _labelContainers.any((labelContainer) {
      labelContainer.layoutAndCheckOverflow();
    });
  }

  /// Apply new text style and layout, then check if
  /// any member of [_labelContainers] overflows.
  /// returns `true` if at least one overflows.
  bool _applyStyleThenLayoutAndCheckOverflow({
    LabelStyle labelStyle,
  }) {
    // Here need to process all painters, as we want to apply style to all.
    _labelContainers.forEach((labelContainer) {
      labelContainer.applyStyleThenLayoutAndCheckOverflow(
          labelStyle: labelStyle);
    });
    // todo -4: PUT THIS BACK. FOR NOW, WE JUST LAYOUT ONCE, NOT CARING ABOUT OVERFLOW: return _labelContainers.any((labelContainer) {labelContainer.isOverflowing;});
    return false;
  }
}

/// Represents values and coordinates of one presented atom of data (x and y).
///
/// The managed values are:
///   - [xLabel], [y], and also the stacking support values [fromY], [toY];
/// The managed coordinates are absolute coordinates painted by [ChartPainter]:
///   - [scaledX], [scaledY], [scaledFrom], [scaledTo], and also
///   the stacking support coordinates [fromScaledY], [toScaledY].
/// are General x, y coordinates are the outer bound where
/// represented values will be shown.
///
/// For a bar chart (stacked or grouped), this may be the rectangle
/// representing one data value.
///
/// Notes:
///   - [scaledFrom] and [scaledTo] are offsets for painting in absolute chart
///     coordinates. Both are set lazily after [scale] is called.
///   - This object does not manage it's stacking (setting it's [stackFromY],
///     it is left for the container that manages this object along with
///     values before (below) and after (above).
class StackableValuePoint {
  // initial values
  String
      xLabel; // todo 0 check if this is unused; and why we need label in value?
  double y;
  int dataRowIndex; // series index
  StackableValuePoint predecessorPoint;
  bool isStacked = false;

  // stacking - sets the y coordinate of range representing this point's value
  double fromY;
  double toY;

  /// Scaled values. All set lazily after [scale]
  double scaledX;
  double scaledY;
  double fromScaledY;
  double toScaledY;

  /// Scaled Offsets for painting in absolute chart coordinates.
  /// More precisely, offsets of the bottom and top of the presenter of this
  /// point - for example, for VerticalBar, bottom and top of each bar
  /// representing this value point (data point)
  ui.Offset scaledFrom;
  ui.Offset scaledTo;

  StackableValuePoint({
    String xLabel,
    double y,
    int dataRowIndex,
    StackableValuePoint predecessorPoint,
  }) {
    this.xLabel = xLabel;
    this.y = y;
    this.dataRowIndex = dataRowIndex;
    this.predecessorPoint = predecessorPoint;
    this.isStacked = false;

    this.fromY = 0.0;
    this.toY = this.y;
  }

  StackableValuePoint stack() {
    this.isStacked = true;

    // todo -1 validate: check if both points y is same sign or zero
    this.fromY = predecessorPoint != null ? predecessorPoint.toY : 0.0;
    this.toY = this.fromY + this.y;

    return this;
  }

  /// Stacks this point on top of the passed [predecessorPoint].
  ///
  /// Points are constructed unstacked. Depending on chart type,
  /// a later processing can stack points using this method
  /// (if chart type is [ChartContainer.isStacked].
  StackableValuePoint stackOnAnother(StackableValuePoint predecessorPoint) {
    this.predecessorPoint = predecessorPoint;
    return this.stack();
  }

  /// Scales this point's data values [x] and [y], and all stacked y values
  /// and points - [scaledX], [scaledY], [fromScaledY],  [toScaledY],
  /// [scaledFrom], [scaledTo] - using the passed values scaler [yScaler].
  ///
  /// Note that the x values are not really scaled, as object doed not
  /// manage the unscaled [x] (it manages the corresponding label only).
  /// For this reason, the [scaledX] value must be provided explicitly.
  /// The provided [scaledX] value should be the
  /// "within [ChartPainter] absolute" x coordinate (generally the center
  /// of the correspoding x label).
  ///
  StackableValuePoint scale({
    YScalerAndLabelFormatter yScaler,
    double scaledX,
  }) {
    this.scaledX = scaledX;
    this.scaledY = yScaler.scaleY(value: this.y);
    this.fromScaledY = yScaler.scaleY(value: this.fromY);
    this.toScaledY = yScaler.scaleY(value: this.toY);
    this.scaledFrom = new ui.Offset(scaledX, this.fromScaledY);
    this.scaledTo = new ui.Offset(scaledX, this.toScaledY);

    return this;
  }

  void applyParentOffset(ui.Offset offset) {
    // only apply  offset on scaled values, those have chart coordinates that are painted.

    // not needed to offset : StackableValuePoint predecessorPoint;

    /// Scaled values represent screen coordinates, apply offset to all.
    scaledX += offset.dx;
    scaledY += offset.dy;
    fromScaledY += offset.dy;
    toScaledY += offset.dy;

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
      throw new Exception("Cannot clone if already stacked");
    }

    StackableValuePoint clone = new StackableValuePoint(
        xLabel: this.xLabel,
        y: this.y,
        dataRowIndex: this.dataRowIndex,
        predecessorPoint: this.predecessorPoint);

    // numbers and Strings, being immutable, can be just assigned.
    // rest of objects (ui.Offset) must be created from immutable leafs.
    clone.xLabel = xLabel;
    clone.y = y;
    clone.predecessorPoint = null;
    clone.dataRowIndex = dataRowIndex;
    clone.isStacked = false;
    clone.fromY = fromY;
    clone.toY = toY;
    clone.scaledX = scaledX;
    clone.scaledY = scaledY;
    clone.fromScaledY = fromScaledY;
    clone.toScaledY = toScaledY;
    if (scaledFrom != null)
      clone.scaledFrom = new ui.Offset(scaledFrom.dx, scaledFrom.dy);
    if (scaledTo != null)
      clone.scaledTo = new ui.Offset(scaledTo.dx, scaledTo.dy);

    return clone;
  }
}

/// A column of value points, with support for stacked type charts.
///
/// Represents one column of data across [ChartData.dataRows],
/// scaled to Y axis, inverted, and stacked
/// (if the type of chart requires stacking).
///
/// Supports to convert the raw data values from the data rows,
/// into values that are either
///   - unstacked (such as in the line chart),  in which case it manages
///   [points] that have values from [ChartData.dataRows].
///   - stacked (such as in the bar chart), in which case it manages
///   [points] that have values added up from [ChartData.dataRows].
///
/// Negative and positive points must be stacked separately,
/// to support correctly displayed stacked values above and below zero.
class PointsColumn {
  /// List of charted values in this column
  List<StackableValuePoint> points;

  /// List of stacked positive or zero value points - support for stacked type charts,
  /// where negative and positive points must be stacked separately,
  /// above and below zero.
  List<StackableValuePoint> stackedPositivePoints; // non-negative actually

  /// List of stacked negative value points - support for stacked type charts,
  /// where negative and positive points must be stacked separately,
  /// above and below zero.
  List<StackableValuePoint> stackedNegativePoints;

  PointsColumn nextRightPointsColumn;

  ///  Construct column from the passed [points].
  ///
  ///  Passed points are assumed to:
  ///    - Be configured with appropriate [predecessorPoint]
  ///    - Not stacked
  ///  Creates members [stackedNegativePoints], [stackedPositivePoints]
  ///  which exist only to be stacked, so the constructor stacks them
  ///  on creation.
  PointsColumn({
    List<StackableValuePoint> points,
  }) {
    // todo -1 add validation that points are not stacked
    this.points = points;

    this.stackedPositivePoints = this.selectThenCollectStacked(
        points: this.points, selector: (point) => point.y >= 0);
    this.stackedNegativePoints = this.selectThenCollectStacked(
        points: this.points, selector: (point) => point.y < 0);
  }

  // points are ordered in series order, first to last  (bottom to top),
  // and maintain their 0 based row (series) index
  /// todo 0 document
  List<StackableValuePoint> selectThenCollectStacked({
    List<StackableValuePoint> points,
    bool selector(StackableValuePoint point),
  }) {
    StackableValuePoint predecessorPoint;
    List<StackableValuePoint> selected = this.points.where((point) {
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
  Iterable allPoints() {
    return []
      ..addAll(points)
      ..addAll(stackedNegativePoints)
      ..addAll(stackedPositivePoints);
  }
}

/// A list of [PointsColumn] instances.
///
/// Passed to [Presenter] instances, which use this instance's data to
/// paint the values in areas above labels,
/// in the appropriate presentation (point and line chart, column chart, etc)
///
/// Manages value point structure as column based (currently supported)
/// or row based (not supported).
///
/// A (single instance per chart) is used to create [PresentersColumns]
/// instance, managed in [DataContainer].
class PointsColumns extends custom_collection.CustomList {
  //\/Data points managed row - first. Internal only, not used in chart.
  List<List<StackableValuePoint>> _valuePointArrInRows;

  /// Data points managed column - first. Internal only, not used in chart.
  List<List<StackableValuePoint>> _valuePointArrInColumns;

  /// Parent chart container.
  ChartContainer _container;

  /// True if chart type presents values stacked.
  bool _isStacked;

  /// Constructor creates a [PointsColumns] instance from values in
  /// the passed [container.data.dataRows].
  PointsColumns({
    ChartContainer container,
    PresenterCreator presenterCreator,
    bool isStacked,
  }) {
    _container = container;
    _valuePointArrInRows = new List();
    _isStacked = isStacked;

    ChartData chartData = container.data;

    /// Transposes the passed data in [container.data.dataRows]
    /// to [_valuePointArrInRows] to [_valuePointArrInColumns].
    ///
    /// Manages "predecessor in stack" points - each element is the per column point
    /// below the currently processed point. The currently processed point is
    /// (potentially) stacked on it's predecessor.
    List<StackableValuePoint> rowOfPredecessorPoints =
        new List(chartData.dataRows[0].length); // todo 0 deal with no data rows
    for (int col = 0; col < rowOfPredecessorPoints.length; col++)
      rowOfPredecessorPoints[col] = null;

    for (int row = 0; row < chartData.dataRows.length; row++) {
      List<num> dataRow = chartData.dataRows[row];
      List<StackableValuePoint> pointsRow = new List<StackableValuePoint>();
      _valuePointArrInRows.add(pointsRow);
      // int col = 0;
      // dataRow.forEach((var colValue) {
      StackableValuePoint predecessorPoint;
      for (int col = 0; col < dataRow.length; col++) {
        num colValue = dataRow[col];

        // Create all points unstacked. A later processing can stack them,
        // depending on chart type. See [StackableValuePoint.stackOnAnother]
        var thisPoint = new StackableValuePoint(
            xLabel: null,
            y: colValue,
            dataRowIndex: row,
            predecessorPoint: rowOfPredecessorPoints[col]);

        pointsRow.add(thisPoint);
        rowOfPredecessorPoints[col] = thisPoint;
      }
    }
    _valuePointArrInRows.toList();
    _valuePointArrInColumns = util.transpose(_valuePointArrInRows);

    /// convert "column oriented" _valuePointArrInColumns
    /// to a column, and add the columns to this instance
    PointsColumn leftColumn;

    _valuePointArrInColumns.forEach((List<StackableValuePoint> columnPoints) {
      var pointsColumn = new PointsColumn(points: columnPoints);
      this.add(pointsColumn);
      leftColumn?.nextRightPointsColumn = pointsColumn;
      leftColumn = pointsColumn;
    });
  }

  /// Scales this object's column values managed in [pointsColumns].
  ///
  /// This allows separation of creating this object with
  /// the original, unscaled data points, and apply scaling later
  /// on the stackable (stacked or unstacked) values.
  ///
  /// Notes:
  ///   - Iterates this object's [pointsColumns], then the contained
  ///   [PointsColumn.points], and scales each point by
  ///   applying its [StackableValuePoint.scale] method.
  ///   - No scaling of the internal representation stored in [_valuePointArrInRows]
  ///   or [_valuePointArrInColumns].
  void scale() {
    int col = 0;
    this.forEach((PointsColumn column) {
      column.allPoints().forEach((StackableValuePoint point) {
        double scaledX = _container.xTickXs[col];
        point.scale(scaledX: scaledX, yScaler: _container.yScaler);
      });
      col++;
    });
  }

  void applyParentOffset(ui.Offset offset) {
    this.forEach((PointsColumn column) {
      column.allPoints().forEach((StackableValuePoint point) {
        point.applyParentOffset(offset);
      });
    });
  }

  List<num> flattenPointsValues() {
    if (_isStacked) return flattenStackedPointsYValues();

    return flattenUnstackedPointsYValues();
  }

  /// Flattens values of all unstacked data points.
  ///
  /// Use in containers for unstacked charts (e.g. line chart)
  List<num> flattenUnstackedPointsYValues() {
    // todo 1 replace with expand like in: dataRows.expand((i) => i).toList()

    List<num> flat = [];
    this.forEach((PointsColumn column) {
      column.points.forEach((StackableValuePoint point) {
        flat.add(point.toY);
      });
    });
    return flat;
  }

  /// Flattens values of all stacked data points.
  ///
  /// Use in containers for stacked charts (e.g. VerticalBar chart)
  List<num> flattenStackedPointsYValues() {
    List<num> flat = [];
    this.forEach((PointsColumn column) {
      column.stackedNegativePoints.forEach((StackableValuePoint point) {
        flat.add(point.toY);
      });
      column.stackedPositivePoints.forEach((StackableValuePoint point) {
        flat.add(point.toY);
      });
    });
    return flat;
  }
}
