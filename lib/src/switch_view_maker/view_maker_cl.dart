// import 'package:logger/logger.dart' as logger;
// import 'dart:developer' as dart_developer;

// this level or equivalent
import '../coded_layout/chart/container.dart' as container; // OLD CONTAINER
import 'view_maker.dart'; // NEW SWITCH
import '../chart/view_maker.dart'; // NEW
import '../chart/model/data_model_new.dart' as model;
import '../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

abstract class SwitchChartViewMakerCL extends SwitchChartViewMaker {

  SwitchChartViewMakerCL({
    required model.NewModel chartData,
    required bool isStacked, // todo-00-last-last : this was = false
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartData: chartData,
    isStacked: isStacked,
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  );

/* // todo-00-last-last-done : this is from super
  late container.ChartRootContainer chartRootContainer;

  late util_labels.DataRangeLabelInfosGenerator yLabelsGenerator;

  late util_labels.DataRangeLabelInfosGenerator xLabelsGenerator;

  strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy;

  late final bool isUseOldDataContainer;

  bool _isFirst = true;


  void chartRootContainerCreateBuildLayoutPaint(ui.Canvas canvas, ui.Size size) {

    String isFirstStr = _debugPrintBegin();

    chartRootContainer = makeViewRoot(chartViewMaker: this); // also link from this ViewMaker to ChartRootContainer.

    if (_isFirst) {
      _isFirst = false;
    }

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
 */

  @override
  container.ChartRootContainerCL makeViewRoot({required ChartViewMaker chartViewMaker});

  // ##### Methods which create views (containers) for individual chart areas

  @override
  container.XContainerCL makeViewForDomainAxis() {
        return container.XContainerCL(chartViewMaker: this);
  }

  @override
  container.YContainerCL makeViewForRangeAxis() {
        return container.YContainerCL(chartViewMaker: this);
  }

  @override
  container.YContainerCL makeViewForYContainerFirst() {
    return container.YContainerCL(chartViewMaker: this);
  }

  /* todo-00-last-last-done : same as in super
  @override
  legend_container_new.LegendContainer makeViewForLegendContainer() {
    return  isUseOldDataContainer
        ? legend_container_new.LegendContainer(chartViewMaker: this)
        : legend_container_new.LegendContainer(chartViewMaker: this);
  }
  */

  @override
  container.DataContainerCL makeViewForDataContainer();

  /* todo-00-last-last-done : same as in super ??
  List<data_container_new.NewCrossSeriesPointsContainer> makeViewsForDataAreaBars_As_CrossSeriesPoints_List(
        view_maker.ChartViewMaker chartViewMaker,
        List<model.NewCrossSeriesPointsModel> crossSeriesPointsList,
  ) {
    List<data_container_new.NewCrossSeriesPointsContainer> chartColumns = [];
    // Iterate the dataModel down, creating NewCrossSeriesPointsContainer, then NewPointContainer and return

    for (model.NewCrossSeriesPointsModel crossSeriesPoints in chartData.crossSeriesPointsList) {
      // NewCrossSeriesPointsContainer crossSeriesPointsContainer =
      chartColumns.add(
        data_container_new.NewCrossSeriesPointsContainer(
          chartViewMaker: chartViewMaker,
          backingDataCrossSeriesPointsModel: crossSeriesPoints,
          children: [makeViewForDataAreaCrossSeriesPoints_Layouter(chartViewMaker, crossSeriesPoints)],
          // Give all view columns the same weight along main axis -
          //   results in same width of each [NewCrossSeriesPointsContainer] as owner will be Row (main axis is horizontal)
          constraintsWeight: const container_base.ConstraintsWeight(weight: 1),
        ),
      );
    }
    return chartColumns;
  }

  container_base.BoxContainer makeViewForDataAreaCrossSeriesPoints_Layouter(view_maker.ChartViewMaker chartViewMaker, model.NewCrossSeriesPointsModel crossSeriesPoints) {
    return container_base.Column(
          children: makeViewsForDataAreaCrossSeriesPoints_As_PointList(chartViewMaker, crossSeriesPoints).reversed.toList(growable: false),
        );
  }

  List<data_container_new.NewPointContainer> makeViewsForDataAreaCrossSeriesPoints_As_PointList(
        view_maker.ChartViewMaker chartViewMaker,
        model.NewCrossSeriesPointsModel crossSeriesPoints,
    ) {
      List<data_container_new.NewPointContainer> newPointContainerList = [];

    // Generates [NewPointContainer] view from each [NewPointModel]
    // and collect the views in a list which is returned.
      crossSeriesPoints.applyOnAllElements(
          (model.NewPointModel element, dynamic passedList) {
        var newPointContainerList = passedList[0];
        var chartRootContainer = passedList[1];
        newPointContainerList.add(makeViewForDataAreaPoint(chartRootContainer, element));
      },
      [newPointContainerList, chartViewMaker],
    );

    return newPointContainerList;
  }

  data_container_new.NewPointContainer makeViewForDataAreaPoint(
      view_maker.ChartViewMaker chartViewMaker,
      model.NewPointModel pointModel,
      ) {
    return data_container_new.NewHBarPointContainer(
      newPointModel: pointModel,
      chartViewMaker: chartViewMaker,
    );
  }

  late presenter.PointPresenterCreator pointPresenterCreator; // equivalent of NEW ChartViewMaker in OLD layout

  String _debugPrintBegin() {
    String isFirstStr = _isFirst ? '=== IS FIRST ===' : '=== IS SECOND ===';

    return isFirstStr;
  }

  void _debugPrintEnd(String isFirstStr) {
  }
  */
}

