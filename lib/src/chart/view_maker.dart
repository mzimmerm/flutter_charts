import 'dart:ui' as ui show Canvas, Size;
// import 'dart:developer' as dart_developer;

// this level or equivalent
import 'container.dart' as container;
import 'container_new/data_container_new.dart' as data_container_new;
import 'container_new/legend_container_new.dart' as legend_container_new;
import 'container_new/axis_container_new.dart' as axis_container_new;
import 'view_maker.dart' as view_maker;
import 'container_layouter_base.dart' as container_base;
import 'model/data_model_new.dart' as model;
import 'presenter.dart' as presenter; // OLD

import 'options.dart' as options;
import '../morphic/rendering/constraints.dart' as constraints;

import 'iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

/// Abstract base class for view makers.
///
/// A view maker is a class that makes (creates, produces, generates) a chart view hierarchy,
/// starting with a concrete [container.ChartRootContainer], with the help of [model.NewModel].
///
/// This base view maker has access to [model.NewModel]
///
/// This base view maker holds as members:
///   - the model in [chartData]
///   - the label layout strategy in [xContainerLabelLayoutStrategy]
///   - the definition whether the chart is stacked in [isStacked].
///
/// All the members above are needed to construct the view container hierarchy root, the [chartRootContainer],
/// which is also a late member after it is constructed.
///
/// [ChartViewMaker] is not a [BoxContainer], it provides a 'link' between [FlutterChartPainter]
/// which [paint] method is called by the Flutter framework, and the root of the chart container hierarchy,
/// the [chartRootContainer].
///
/// Core methods of [ChartViewMaker] are
///   - [chartRootContainerCreateBuildLayoutPaint], which should be called in [FlutterChartPainter.paint];
///     this method creates, builds, lays out, and paints
///     the root of the chart container hierarchy, the [chartRootContainer].
///   - abstract [makeViewRoot]; extensions of [ChartViewMaker] (for example, [LineChartViewMaker]) should create
///     and return an instance of the concrete [chartRootContainer] (for example [LineChartRootContainer]).
///   - [container.ChartBehavior.extendAxisToOrigin] is on this Maker,
///     as it controls how views behave (although does not control view making).
abstract class ChartViewMaker extends Object with container.ChartBehavior {

  ChartViewMaker({
    required this.chartData,
    this.isStacked = false,
    this.xContainerLabelLayoutStrategy,
  }) {
    print('Constructing ChartViewMaker');
    isUseOldDataContainer = const bool.fromEnvironment('USE_OLD_DATA_CONTAINER', defaultValue: true);
  }

  /// ChartData to hold on before member [chartRootContainer] is created late.
  ///
  /// After [chartRootContainer] is created and set, This [NewModel] type member [chartData]
  /// should be placed on the member [chartRootContainer.chartData].

  /// Model for this chart. Created before chart, set in concrete [ChartViewMaker] in constructor.
  final model.NewModel chartData;

  /// Options set from model options in [FlutterChartPainter] constructor from [FlutterChartPainter.chartViewMaker]'s
  /// [ChartViewMaker.chartData]'s [ChartOptions].
  late final options.ChartOptions chartOptions;

  final bool isStacked;

  /// Access the view [chartRootContainer] from this maker [ChartViewMaker].
  /// NOT final, recreated even on repaint, survived by this maker.
  ///
  /// It's children, [legendContainer], etc are also not final.
  late container.ChartRootContainer chartRootContainer;

  // todo-010 : THE ONLY REASON THESE MEMBERS MUST BE KEPT IS THEIR USE ON _SourceYContainerAndYContainerToSinkDataContainer.
  //            REMOVE THAT NEED, AND THESE MEMBERS.
  /// Holder of inner container this maker is making for it's [chartRootContainer].
  ///
  /// Only exists so there is a single place the creation of [_legendContainer].
  ///
  /// Lifecycle: Its useful lifecycle is the time between this top-class maker [makeViewRoot] is invoked,
  /// where [_legendContainer] is created, and when the concrete [makeViewRoot] is invoked,
  /// which creates the concrete [chartRootContainer], and [_legendContainer] is passed to it.
  late legend_container_new.LegendContainer legendContainer;
  /// See [legendContainer]
  late container.XContainer      xContainer;
  /// See [legendContainer]
  late container.YContainer      yContainer;
  /// See [legendContainer]
  late container.DataContainer   dataContainer;
  

  /// Layout strategy, necessary to create the concrete view [ChartRootContainer].
  strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy;

  /// Controls whether to use the old manual layout containers, or the new,
  /// auto-layout containersSet from a commend line
  /// switch --dart-define=USE_OLD_DATA_CONTAINER=false/true.
  /// Find usages to see where old/new code differs.
  late final bool isUseOldDataContainer;

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
    chartRootContainer = makeViewRoot(chartViewMaker: this); // also link from this ViewMaker to ChartRootContainer.

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

  /// Should create a concrete instance of [ChartRootContainer], bind it to member [chartRootContainer],
  /// and return it.
  ///
  /// Generally, the created [ChartRootContainer]'s immediate children should also be created and added to it,
  /// but deeper children may or may not be created.
  ///
  /// In the default implementations, the [chartRootContainer]'s children created are
  /// [ChartRootContainer.legendContainer],  [ChartRootContainer.yContainer],
  ///  [ChartRootContainer.xContainer], and  [chartRootContainer.chartDataContainer].
  ///
  /// If an extension uses an implementation that does not adhere to the above
  /// description, the [ChartRootContainer.layout] should be overridden.
  ///
  /// Important notes:
  ///   - This controller (ViewMaker) can access both on ChartRootContainer and NewModel.
  container.ChartRootContainer makeViewRoot({required ChartViewMaker chartViewMaker});

  // ##### Methods which create views (containers) for individual chart areas

  /// Assumed made from [model.NewModel] member [model.NewModel.xUserLabels] or [container.YContainer.labelInfos].
  container.XContainer makeViewForDomainAxis() {
    return isUseOldDataContainer
        ? container.XContainer(chartViewMaker: this)
        : axis_container_new.NewXContainer(chartViewMaker: this);
  }

  /// Assumed made from [model.NewModel] member [model.NewModel.yUserLabels] or labels in [container.YContainer.labelInfos].
  container.YContainer makeViewForRangeAxis() {
    return isUseOldDataContainer
        ? container.YContainer(chartViewMaker: this)
        : axis_container_new.NewYContainer(chartViewMaker: this);
  }

  /// Assumed made from [model.NewModel] member [model.NewModel.dataRowsLegends].
  legend_container_new.LegendContainer makeViewForLegendContainer() {
    return  isUseOldDataContainer
        ? legend_container_new.LegendContainer(chartViewMaker: this)
        : legend_container_new.LegendContainer(chartViewMaker: this);
  }

  /// Abstract method constructs and returns the concrete [DataContainer] instance,
  /// for the chart type (line, bar) determined by this concrete [ChartRootContainer].
  /// Assumed made from [model.NewModel.barOfPointsList], presents all data in the data area.
  container.DataContainer makeViewForDataContainer();

  /// Makes a view showing all bars of data points.
  ///
  /// Assumed made from [model.NewModel.barOfPointsList].
  ///
  /// Should be invoked inside [makeViewForDataArea], each child in the returned list
  /// should be made from one element of [model.NewModel.barOfPointsList],
  /// which is instance of [model.NewBarOfPointsModel].
  ///
  /// Original name: generateViewChildren_Of_NewDataContainer_As_NewBarOfPointsContainer_List
  List<data_container_new.NewBarOfPointsContainer> makeViewsForDataAreaBars_As_BarOfPoints_List(
        view_maker.ChartViewMaker chartViewMaker,
        List<model.NewBarOfPointsModel> barOfPointsList,
  ) {
    List<data_container_new.NewBarOfPointsContainer> chartColumns = [];
    // Iterate the dataModel down, creating NewBarOfPointsContainer, then NewPointContainer and return

    for (model.NewBarOfPointsModel barOfPoints in chartData.barOfPointsList) {
      // NewBarOfPointsContainer barOfPointsContainer =
      chartColumns.add(
        data_container_new.NewBarOfPointsContainer(
          chartViewMaker: chartViewMaker,
          backingDataBarOfPointsModel: barOfPoints,
          children: [makeViewForDataAreaBarOfPoints_Layouter(chartViewMaker, barOfPoints)],
          // Give all view columns the same weight along main axis -
          //   results in same width of each [NewBarOfPointsContainer] as owner will be Row (main axis is horizontal)
          constraintsWeight: const container_base.ConstraintsWeight(weight: 1),
        ),
      );
    }
    return chartColumns;
  }

  container_base.BoxContainer makeViewForDataAreaBarOfPoints_Layouter(view_maker.ChartViewMaker chartViewMaker, model.NewBarOfPointsModel barOfPoints) {
    return container_base.Column(
          children: makeViewsForDataAreaBarOfPoints_As_PointList(chartViewMaker, barOfPoints).reversed.toList(growable: false),
        );
  }

  /// Generates [NewPointContainer] view from each [NewPointModel]
  /// and collects the views in a list of [NewPointContainer]s which is returned.
  ///
  /// Original name: generateViewChildren_Of_NewBarOfPointsContainer_As_NewPointContainer_List
  List<data_container_new.NewPointContainer> makeViewsForDataAreaBarOfPoints_As_PointList(
        view_maker.ChartViewMaker chartViewMaker,
        model.NewBarOfPointsModel barOfPoints,
    ) {
      List<data_container_new.NewPointContainer> newPointContainerList = [];

    // Generates [NewPointContainer] view from each [NewPointModel]
    // and collect the views in a list which is returned.
      barOfPoints.applyOnAllElements(
          (model.NewPointModel element, dynamic passedList) {
        var newPointContainerList = passedList[0];
        var chartRootContainer = passedList[1];
        newPointContainerList.add(makeViewForDataAreaPoint(chartRootContainer, element));
      },
      [newPointContainerList, chartViewMaker],
    );

    return newPointContainerList;
  }

  /// Generate view for this single leaf [NewPointModel] - a single [NewHBarPointContainer].
  ///
  /// Note: On the leaf, we return single element by agreement, higher ups return lists.
  /// Original name: generateViewChildLeaf_Of_NewBarOfPointsContainer_As_NewPointContainer
  data_container_new.NewPointContainer makeViewForDataAreaPoint(
      view_maker.ChartViewMaker chartViewMaker,
      model.NewPointModel pointModel,
      ) {
    return data_container_new.NewHBarPointContainer(
      newPointModel: pointModel,
      chartViewMaker: chartViewMaker,
    );
  }

  // todo-010 : This is an opportunity for several extension fo ChartViewMaker, for example, CartesianChartViewMaker, which needs all the above.
  // ^^^^^^^^^^^ Abstract methods to create views (containers) for individual chart areas

  /// Makes pointPresenters, the visuals painted on each chart column that
  /// represent data, (points and lines for the line chart,
  /// rectangles for the bar chart, and so on).
  ///
  /// See [PointPresenterCreator] and [PointPresenter] for more details.
  late presenter.PointPresenterCreator pointPresenterCreator; // equivalent of NEW ChartViewMaker in OLD layout

  String _debugPrintBegin() {
    String isFirstStr = _isFirst ? '=== IS FIRST ===' : '=== IS SECOND ===';

    /* KEEP
    dart_developer.log(
        '    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint BEGIN BEGIN BEGIN, $isFirstStr',
        name: 'charts.debug.log');
    */

    return isFirstStr;
  }

  void _debugPrintEnd(String isFirstStr) {
    /* KEEP
    dart_developer.log(
        '    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint END END END, $isFirstStr',
        name: 'charts.debug.log');
    */
  }
}
