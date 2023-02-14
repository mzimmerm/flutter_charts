import '../chart/container.dart' as container;
import '../chart/new_data_container.dart' as new_data_container;
import '../chart/model/new_data_model.dart' as model;

import '../chart/container_layouter_base.dart' as container_base;

import '../chart/options.dart' as options;
import '../chart/painter.dart' as painter;
import '../morphic/rendering/constraints.dart' as constraints;

import '../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

import 'dart:ui' as ui show Canvas, Size;

import 'dart:developer' as dart_developer;

/// Base class for classes that hold [chartData], [xContainerLabelLayoutStrategy], [isStacked],
/// members needed for late creation of the root of the chart container hierarchy, the [chartRootContainer].
///
/// [ChartViewMaker] is not a [BoxContainer], it provides a 'link' between [FlutterChartPainter] which [paint] method
/// is called by the Flutter framework, and the root of the chart container hierarchy, the [chartRootContainer].
///
/// Core methods of [ChartViewMaker] are
///   - [chartRootContainerCreateBuildLayoutPaint], which should be called in [FlutterChartPainter.paint];
///     this method creates, builds, lays out, and paints
///     the root of the chart container hierarchy, the [chartRootContainer].
///   - abstract [createRootContainer]; extensions of [ChartViewMaker] (for example, [LineChartViewMaker]) should create
///     and return an instance of the concrete [chartRootContainer] (for example [LineChartRootContainer]).
abstract class ChartViewMaker {

  ChartViewMaker({
    required this.chartData,
    this.isStacked = false,
    this.xContainerLabelLayoutStrategy,
  }) {
    print('Constructing ChartViewMaker');
  }

  /// ChartData to hold on before member [chartRootContainer] is created late.
  ///
  /// After [chartRootContainer] is created and set, This [NewModel] type member [chartData]
  /// should be placed on the member [chartRootContainer.chartViewMaker.chartData].

  /// Model for this chart. Created before chart, set in concrete [ChartViewMaker] in constructor.
  final model.NewModel chartData;

  final bool isStacked;

  /// Access the view [chartRootContainer] from this maker [ChartViewMaker].
  /// NOT final, recreated even on repaint, survived by this maker.
  late container.ChartRootContainer chartRootContainer;

  /// Options set from model options in [FlutterChartPainter] constructor from [FlutterChartPainter.chartViewMaker]'s
  /// [ChartViewMaker.chartData]'s [ChartOptions].
  late final options.ChartOptions chartOptions;

  /// Layout strategy, necessary to create the concrete view [ChartRootContainer].
  strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy;

  /// Keep track of first run. As this [ChartViewMaker] survives re-paint (but not first paint),
  /// this can be used to initialize 'late final' members on first paint.
  bool _isFirst = true;

  void chartRootContainerCreateBuildLayoutPaint(ui.Canvas canvas, ui.Size size) {
    // Create the concrete [ChartRootContainer] for this concrete [ChartViewMaker].
    // After this invocation, the created root container is populated with children
    // XContainer, YContainer, DataContainer and LegendContainer. Their children are partly populated,
    // depending on the concrete container. For example YContainer is populated with DataRangeLabelsGenerator.

    String isFirstStr = _debugPrintBegin();

    // Create the view [chartRootContainer] and set on member on this maker [ChartViewMaker].
    // This happens even on re-paint, so can be done multiple times after state changes in the + button.
    chartRootContainer = createRootContainer(chartViewMaker: this); // also link from this ViewMaker to ChartRootContainer.

    // Only set `chartData.chartViewMaker = this` ONCE. Reason: member chartData is created ONCE, same as this ANCHOR.
    // To have chartData late final, we have to keep track to only initialize chartData.chartViewMaker = this on first run.
    if (_isFirst) {
      _isFirst = false;
    }

    // e.g. set background: canvas.drawPaint(ui.Paint()..color = material.Colors.green);

    // Apply constraints on root. Layout size and constraint size of the [ChartRootContainer] are the same, and
    // are equal to the full 'size' passed here from the framework via [FlutterChartPainter.paint].
    // This passed 'size' is guaranteed to be the same area on which the painter will paint.

    chartRootContainer.applyParentConstraints(
      chartRootContainer,
      constraints.BoxContainerConstraints.insideBox(
        size: ui.Size(
          size.width,
          size.height,
        ),
      ),
    );

    chartRootContainer.layout();

    chartRootContainer.paint(canvas);

    _debugPrintEnd(isFirstStr);
  }

  /// Extensions of this [ChartViewMaker] (for example, [LineChartViewMaker]) should
  /// create and return an instance of the concrete [chartRootContainer]
  /// (for example [LineChartRootContainer]), populated with it's children, but not
  /// children's children. The children's children hierarchy is assumed to
  /// be created in [chartRootContainerCreateBuildLayoutPaint] during
  /// it's call to [ChartRootContainer.layout].
  ///
  /// In the default implementations, the [chartRootContainer]'s children created are
  /// [ChartRootContainer.legendContainer],  [ChartRootContainer.yContainer],
  ///  [ChartRootContainer.xContainer], and  [chartRootContainer.chartViewMaker.chartDataContainer].
  ///
  /// If an extension uses an implementation that does not adhere to the above
  /// description, the [ChartRootContainer.layout] should be overridden.
  ///
  /// Important notes:
  ///   - This controller (ViewMaker) can access both on ChartRootContainer and NewModel.
  //    - NewModel has ChartOptions
  container.ChartRootContainer createRootContainer({required ChartViewMaker chartViewMaker});

  // todo-00-last vvvvvvvvvvv : add abstract methods to create views (containers) for individual chart areas:
  container.XContainer generateViewXContainer({required container.ChartRootContainer chartRootContainerParent}) {
    // Responsibility: pass this.chartRootContainer
    throw UnimplementedError('generateViewYContainer');
  }
  container.YContainer generateViewYContainer({required container.ChartRootContainer chartRootContainerParent}) {
    // Responsibility: pass this.chartRootContainer
    throw UnimplementedError('generateViewYContainer');
  }
  new_data_container.NewDataContainer generateViewDataContainer({required container.ChartRootContainer chartRootContainerParent}) {
    // Responsibility: pass this.chartRootContainer
    throw UnimplementedError('generateViewYContainer');
  }
  container.LegendContainer generateViewLegendContainer({required container.ChartRootContainer chartRootContainerParent}) {
    // Responsibility: pass this.chartRootContainer
    throw UnimplementedError('generateViewYContainer');
  }


  // todo-00-last : moved here from model, but move to BarViewMaker!
  List<new_data_container.NewBarOfPointsContainer> generateViewChildren_Of_NewDataContainer_As_NewBarOfPointsContainer_List(
        container.ChartRootContainer chartRootContainer,
        List<model.NewBarOfPointsModel> barOfPointsList,
  ) {
    List<new_data_container.NewBarOfPointsContainer> chartColumns = [];
    // Iterate the dataModel down, creating NewBarOfPointsContainer, then NewPointContainer and return

    for (model.NewBarOfPointsModel barOfPoints in chartData.barOfPointsList) {
      // NewBarOfPointsContainer barOfPointsContainer =
      chartColumns.add(
        new_data_container.NewBarOfPointsContainer(
          chartRootContainer: chartRootContainer,
          backingDataBarOfPointsModel: barOfPoints,
          children: [container_base.Column(
            // todo-00-last : done during move from model to maker: children: barOfPoints.generateViewChildren_Of_NewBarOfPointsContainer_As_NewPointContainer_List(chartRootContainer).reversed.toList(growable: false),
            children: generateViewChildren_Of_NewBarOfPointsContainer_As_NewPointContainer_List(chartRootContainer, barOfPoints).reversed.toList(growable: false),
          )],
          // Give all view columns the same weight along main axis -
          //   results in same width of each [NewBarOfPointsContainer] as owner will be Row (main axis is horizontal)
          constraintsWeight: const container_base.ConstraintsWeight(weight: 1),
        ),
      );
    }
    return chartColumns;
  }

  /// Generates [NewPointContainer] view from each [NewPointModel]
  /// and collects the views in a list of [NewPointContainer]s which is returned.
  List<new_data_container.NewPointContainer> generateViewChildren_Of_NewBarOfPointsContainer_As_NewPointContainer_List(
        container.ChartRootContainer chartRootContainer,
        model.NewBarOfPointsModel barOfPoints,
    ) {
      List<new_data_container.NewPointContainer> newPointContainerList = [];

    // Generates [NewPointContainer] view from each [NewPointModel]
    // and collect the views in a list which is returned.
      barOfPoints.applyOnAllElements(
          (model.NewPointModel element, dynamic passedList) {
        var newPointContainerList = passedList[0];
        var chartRootContainer = passedList[1];
        // todo-00-last : done during move from model to maker: children:  newPointContainerList.add(element.generateViewChildLeaf_Of_NewBarOfPointsContainer_As_NewPointContainer(chartRootContainer, element));
        newPointContainerList.add(generateViewChildLeaf_Of_NewBarOfPointsContainer_As_NewPointContainer(chartRootContainer, element));
      },
      [newPointContainerList, chartRootContainer],
    );

    return newPointContainerList;
  }

  new_data_container.NewPointContainer generateViewChildLeaf_Of_NewBarOfPointsContainer_As_NewPointContainer(
      container.ChartRootContainer chartRootContainer,
      model.NewPointModel element,
      ) {
    return new_data_container.NewHBarPointContainer(
      newPointModel: element, // todo-00-last : was : this
      chartRootContainer: chartRootContainer,
    );
  }

  // todo-00-last : This is an opportunity for several extension fo ChartViewMaker, for example, CartesianChartViewMaker, which needs all the above.
  // todo-00-last ^^^^^^^^^^^ :  add abstract methods to create views (containers) for individual chart areas

  String _debugPrintBegin() {
    String isFirstStr = _isFirst ? '=== IS FIRST ===' : '=== IS SECOND ===';

    /*
    dart_developer.log(
        '    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint BEGIN BEGIN BEGIN, $isFirstStr',
        name: 'charts.debug.log');
    */

    return isFirstStr;
  }

  void _debugPrintEnd(String isFirstStr) {
    /*
    dart_developer.log(
        '    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint END END END, $isFirstStr',
        name: 'charts.debug.log');
    */
  }
}
