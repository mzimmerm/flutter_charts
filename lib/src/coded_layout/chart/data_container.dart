import 'dart:ui' as ui show Size, Offset, Canvas;

// this level or equivalent
// import 'package:flutter_charts/src/chart/chart_type/line/container/data_container.dart';

import 'axis_container.dart';
import 'container.dart';
import '../../chart/container/container_common.dart';
import '../../chart/container/data_container.dart';
import '../../chart/view_model/view_model.dart';
import '../../morphic/container/container_layouter_base.dart'
    show BoxContainer, BoxLayouter, LayoutableBox;
import 'line_container.dart';
import 'presenter.dart';
import '../../chart/options.dart';
import '../../morphic/container/container_key.dart' show ContainerKey;
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart' show ConstraintsWeight;
import '../../morphic/container/morphic_dart_enums.dart';

import '../../switch_view_model/view_model_cl.dart';

// extension libraries
import 'chart_type/line/presenter.dart' as line_presenters;
import 'chart_type/bar/presenter.dart' as bar_presenters;


/// Manages the core chart area which displays and paints (in this order):
/// - The grid (this includes the X and Y axis).
/// - Data - as columns of bar chart, line chart, or other chart type
abstract class DataContainerCL extends ChartAreaContainer implements DataContainer {

  /// Constructs instance from [ChartViewModel].
  ///
  /// Note: It is assumed that the passed [chartViewModel]
  ///       is [SwitchChartViewModelCL], a derivation of [ChartViewModel].
  DataContainerCL({required ChartViewModel chartViewModel})
      : super(
    chartViewModel: chartViewModel,
  );

  /// Keeps data values grouped in columns.
  ///
  /// This column grouped data instance is managed here in the [DataContainerCL],
  /// as their data points are needed both during [OutputAxisContainerCL.layout]
  /// to calculate extrapolating, and also here in [DataContainerCL.layout] to create
  /// [PointPresentersColumns] instance.
  ///
  /// Moved here on [DataContainerCL] from [ChartModel]. While this is strictly speaking a model legacy coded_layout
  /// system, the only use is on this [DataContainerCL] so it is a good place to hold it.
  late PointsColumns pointsColumns;


  /// Container of gridlines parallel to X axis.
  ///
  /// The reason to separate [_horizontalGridLinesContainer] and [_verticalGridLinesContainer] is for them to hide/show independently.
  late GridLinesContainer _horizontalGridLinesContainer;
  late GridLinesContainer _verticalGridLinesContainer;

  /// Columns of pointPresenters.
  ///
  /// PointPresenters may be:
  /// - points and lines in line chart
  /// - bars (stacked or grouped) in bar chart
  ///
  late PointPresentersColumns pointPresentersColumns;

  /// Overridden builds children of self [DataContainerCL], the [_verticalGridLinesContainer] and [_horizontalGridLinesContainer]
  /// and adds them as self children.
  @override
  void buildAndReplaceChildren() {

    List<BoxContainer> dataContainerChildren = [];

    /// Root of chart, cast to CL version.
    ChartRootContainerCL chartRootContainer = chartViewModel.chartRootContainer as ChartRootContainerCL;

    // Vars that layout needs from the [chartRootContainer] passed to constructor
    ChartOptions chartOptions = chartViewModel.chartOptions;

    // ### 1. Vertical Grid (yGrid) layout:

    // Use this DataContainer layout dependency on [xTickXs] as guidelines for X labels
    // in [InputAxisContainer.inputLabelContainerCLs], for each create one [LineContainer] as child of [_verticalGridLinesContainer]

    // Initial values which will show as bad lines if not changed during layout.
    ui.Offset initLineFrom = const ui.Offset(0.0, 0.0);
    ui.Offset initLineTo = const ui.Offset(100.0, 100.0);

    // Construct the GridLinesContainer with children: [LineContainer]s
    _verticalGridLinesContainer = GridLinesContainer(
      chartViewModel: chartViewModel,
      children: chartRootContainer.xTickXs.map((double xTickX) {
        // Add vertical yGrid line in the middle of label (stacked bar chart) or on label left edge (line chart)
        // this legacy uses isStacked to define isLineChart : double lineX = chartViewModel.chartStacking.isStacked ? xTickX - chartRootContainer.xGridStep / 2 : xTickX;
        // double lineX = (this is LineChartDataContainer || this is LineChartDataContainerCL) ? xTickX : xTickX - chartRootContainer.xGridStep / 2;
        double lineX = chartViewModel.chartStacking.isStacked ? xTickX - chartRootContainer.xGridStep / 2 : xTickX;
        return LineContainerCL(
          chartViewModel: chartViewModel,
          lineFrom: initLineFrom,
          lineTo: initLineTo,
          linePaint: chartOptions.dataContainerOptions.gridLinesPaint(),
          manualLayedOutFromX: lineX,
          manualLayedOutFromY: 0.0,
          manualLayedOutToX: lineX,
          manualLayedOutToY: constraints.height,
        );
      }).toList(growable: false),
    );

    // For stacked, we need to add last right vertical yGrid line - one more child to  [_verticalGridLinesContainer]
    // this legacy uses isStacked to determine isLineChart : if (chartViewModel.chartStacking.isStacked && chartRootContainer.xTickXs.isNotEmpty) {
    // if (!(this is LineChartDataContainer || this is LineChartDataContainerCL) && chartRootContainer.xTickXs.isNotEmpty) {
    if (chartViewModel.chartStacking.isStacked && chartRootContainer.xTickXs.isNotEmpty) {
      double lineX = chartRootContainer.xTickXs.last + chartRootContainer.xGridStep / 2;

      _verticalGridLinesContainer.addChildren([
        LineContainerCL(
          chartViewModel: chartViewModel,
          lineFrom: initLineFrom,
          // ui.Offset(lineX, 0.0),
          lineTo: initLineTo,
          // ui.Offset(lineX, layoutSize.height),
          linePaint: chartOptions.dataContainerOptions.gridLinesPaint(),
          manualLayedOutFromX: lineX,
          manualLayedOutFromY: 0.0,
          manualLayedOutToX: lineX,
          manualLayedOutToY: constraints.height,
        ),
      ]);
    }
    // Add the constructed Y - parallel GridLinesContainer as child to self DataContainer
    dataContainerChildren.addAll([_verticalGridLinesContainer]);

    // ### 2. Horizontal Grid (xGrid) layout:

    // Use this DataContainer layout dependency on [yTickYs] as guidelines for Y labels
    // in [OutputAxisContainer.outputLabelContainerCLs], for each create one [LineContainer] as child of [_horizontalGridLinesContainer]

    // Construct the GridLinesContainer with children: [LineContainer]s
    _horizontalGridLinesContainer = GridLinesContainer(
      chartViewModel: chartViewModel,
      children:
      // yTickYs create vertical xLineContainers
      // Position the horizontal xGrid at mid-points of labels at yTickY.
      chartRootContainer.yTickYs.map((double yTickY) {
        return LineContainerCL(
          chartViewModel: chartViewModel,
          lineFrom: initLineFrom,
          lineTo: initLineTo,
          linePaint: chartOptions.dataContainerOptions.gridLinesPaint(),
          manualLayedOutFromX: 0.0,
          manualLayedOutFromY: yTickY,
          manualLayedOutToX: constraints.width,
          manualLayedOutToY: yTickY,
        );
      }).toList(growable: false),
    );

    // Add the constructed X - parallel GridLinesContainer as child to self DataContainer
    dataContainerChildren.addAll([_horizontalGridLinesContainer]);

    replaceChildrenWith(dataContainerChildren);
  }

  /// Overrides [BoxLayouter.layout] for data area.
  ///
  /// Uses all available space in the [constraints] set in parent [buildAndReplaceChildren],
  /// which it divides evenly between it's children.
  ///
  /// First lays out the Grid, then, scales the columns to the [OutputAxisContainerCL]'s extrapolate
  /// based on the available size.
  @override
  void layout() {

    // OLD Manual layout build. NEW invokes this as part of auto-layout.
    buildAndReplaceChildren();

    // DataContainer uses it's full constraints to lay out it's grid and presenters!
    layoutSize = ui.Size(constraints.size.width, constraints.size.height);

    // ### 1. Vertical Grid (yGrid) layout:

    // Position the vertical yGrid in the middle of labels (line chart) or on label left edge (stacked bar)
    _verticalGridLinesContainer.applyParentConstraints(this, constraints);
    _verticalGridLinesContainer.layout();

    // ### 2. Horizontal Grid (xGrid) layout:

    // Position the horizontal xGrid at mid-points of labels at yTickY.
    _horizontalGridLinesContainer.applyParentConstraints(this, constraints);
    _horizontalGridLinesContainer.layout();
  }

  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {

    // Move all container atomic elements - lines, labels, circles etc
    _horizontalGridLinesContainer.applyParentOffset(this, offset);

    // draw vertical grid
    _verticalGridLinesContainer.applyParentOffset(this, offset);

    // Create, layout, then offset, the 'data container' replacement - the [PointPresentersColumns].
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
    // 2. Layouts the 'data container' by [_affmapPointsColumns].
    // 3. Applies this parent offset on the 'data container' [PointsColumns].
    //    This offsets the 'data container' [PointsColumns] to the right of the Y axis,
    //    and to the top of the X axis.
    // 4. Creates the 'view model', represented here by [PointPresentersColumns],
    //    and set it on [pointPresentersColumns].
    // 5. LATER, in [paint], paints the  'view model', represented here by [PointPresentersColumns]

    // 1. From the [ChartViewModel] create the 'data container'
    //    (the [PointsColumns], which represent the list of columns on chart), and late bind to instance [pointsColumns]
    //    The coordinates in [PointsColumns] are relative - 0 based
    pointsColumns = PointsColumns(
      chartViewModel: chartViewModel,
      pointPresenterCreator: (chartViewModel as SwitchChartViewModelCL).pointPresenterCreator,
      isStacked: chartViewModel.chartStacking.isStacked,
      caller: this,
    );

    // 2. Layout the data container by extrapolating.
    // Scale the [pointsColumns] to the [OutputAxisContainer]'s extrapolate.
    // This is effectively a [layout] of the lines and bars pointPresenters, currently
    //   done in [VerticalBarPointPresenter] and [LineChartPointPresenter]
    _affmapPointsColumns();

    // 3. Apply offset to the lines and bars (the 'data container' [PointsColumns]).
    pointsColumns.applyParentOffset(this, offset);

    // 4. Create the 'view model', represented here by [PointPresentersColumns],
    //    and set it on [pointPresentersColumns].
    //    Note: The 'view model' [PointPresentersColumns] is created from the [PointsColumns],
    //          'data container'.
    pointPresentersColumns = PointPresentersColumns(
      pointsColumns: pointsColumns,
      chartViewModel: chartViewModel,
      pointPresenterCreator: (chartViewModel as SwitchChartViewModelCL).pointPresenterCreator,
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
    _horizontalGridLinesContainer.paint(canvas);

    // draw vertical grid
    if (chartViewModel.chartOptions.outputAxisContainerOptions.isInputGridLinesShown) {
      _verticalGridLinesContainer.paint(canvas);
    }
  }

  /// Abstract method common to implementing data containers,
  /// currently the [LineChartDataContainerCL] and the [BarChartDataContainerCL].
  void _drawPointPresentersColumns(ui.Canvas canvas);

  /// Paints grid lines, then paints [PointPresentersColumns]
  @override
  void paint(ui.Canvas canvas) {
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
  /// uses the  absolute extrapolated [chartViewModel.pointsColumns].
  void _affmapPointsColumns() {
    // ChartRootContainer, cast to CL version
    pointsColumns.affmapPointsColumns(chartViewModel, chartViewModel.chartRootContainer as ChartRootContainerCL);
  }

  /// Optionally paint series in reverse order (first to last,
  /// vs last to first which is default).
  ///
  /// See [DataContainerOptions.dataRowsPaintingOrder].
  List<PointPresenter> optionalPaintOrderReverse(List<PointPresenter> pointPresenters) {
    var options = chartViewModel.chartOptions;
    if (options.dataContainerOptions.dataRowsPaintingOrder == DataRowsPaintingOrder.firstToLast) {
      pointPresenters = pointPresenters.reversed.toList();
    }
    return pointPresenters;
  }

  // Methods needed to implement DataContainer, but are not used in this CL DataContainerCL,
  //   all throw [UnimplementedError].

  @override
  bool get isOuterMakingInnerContainers => throw UnimplementedError();
  @override
  set isOuterMakingInnerContainers(bool isValue) => throw UnimplementedError();

  @override
  ContainerForBothBarsAreasAndInputAxisLine makeInnerContainerForBothBarsAreas({
    required BarsContainer positiveBarsContainer,
    required BarsContainer negativeBarsContainer,
    required DataContainer outerDataContainer,
    ContainerKey? key,
  }) {
    throw UnimplementedError();
  }

  @override
  BarsContainer makeInnerBarsContainer ({
    required DataContainer outerDataContainer,
    required Sign barsAreaSign,
    required ConstraintsWeight constraintsWeight,
    ContainerKey? key,
  }) {
    throw UnimplementedError();
  }

  @override
  PointContainersBar makeDeepInnerPointContainersBar({
    required PointsBarModel pointsBarModel,
    required BarsContainer outerBarsContainer,
    required Sign barsAreaSign,
  }) {
    throw UnimplementedError('If invoked directly, or isOuterMakingInnerContainers=true, subclass must implement');
  }

  @override
  PointContainer makeDeepInnerPointContainer({
    required BasePointModel pointModel,
  }) {
    throw UnimplementedError('If invoked directly, or isOuterMakingInnerContainers=true, subclass must implement');
  }

  @override
  BasePointContainer makeDeepInnerPointContainerWithFiller() {
    throw UnimplementedError('If invoked directly, or isOuterMakingInnerContainers=true, subclass must implement');
  }
}

/// Provides the data area container for the bar chart.
///
/// The only role is to implement the abstract method of the baseclass,
/// [paint] and [_drawPointPresentersColumns].
class BarChartDataContainerCL extends DataContainerCL {
  BarChartDataContainerCL({
    required ChartViewModel chartViewModel,
  }) : super(
    chartViewModel: chartViewModel,
  );

  /// Draws the actual atomic visual elements representing data on the chart.
  ///
  /// The atomic visual elements are either  lines with points (on the line chart),
  /// or bars/columns, stacked or grouped (on the bar/column charts).
  @override
  void _drawPointPresentersColumns(ui.Canvas canvas) {
    PointPresentersColumns pointPresentersColumns = this.pointPresentersColumns;

    for (PointPresentersColumn pointPresentersColumn in pointPresentersColumns) {

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
    required ChartViewModel chartViewModel,
  }) : super(
    chartViewModel: chartViewModel,
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
        canvas.drawLine(
          pointPresenterCast.lineContainer.lineFrom,
          pointPresenterCast.lineContainer.lineTo,
          pointPresenterCast.lineContainer.linePaint,
        );
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
/// The grid lines are positioned in the middle of labels (Y labels, and X labels for Not-Stacked)
/// or on the left label edge (X labels for stacked).
///
/// Note: Methods [layout], [applyParentOffset], and [paint], use the default implementation.
///
class GridLinesContainer extends ChartAreaContainer {

  /// Construct from children [LineContainerCL]s.
  GridLinesContainer({
    required ChartViewModel chartViewModel,
    required List<LineContainerCL>? children,
  }) : super(
    children: children,
    chartViewModel: chartViewModel,
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

