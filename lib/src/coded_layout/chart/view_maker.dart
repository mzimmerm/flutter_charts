/* todo-00-last-last-last-progress : where to split old/new?
import 'dart:ui' as ui show Canvas, Size;

import '../../chart/view_maker.dart';
import '../../chart/painter.dart';
import 'package:logger/logger.dart' as logger;

// import 'dart:developer' as dart_developer;

// this level or equivalent
import 'container.dart' as container;
import '../../chart/container_new/data_container_new.dart' as data_container_new;
import '../../chart/container_new/container_common_new.dart' as container_common_new;
import '../../chart/container_new/legend_container_new.dart' as legend_container_new;
import '../../chart/container_new/axis_container_new.dart' as axis_container_new;
import 'view_maker.dart' as view_maker;
import '../../chart/container_layouter_base.dart' as container_base;
import '../../chart/model/data_model_new.dart' as model;
import '../../util/util_labels.dart' as util_labels;
import '../chart/presenter.dart' as presenter; // OLD

import '../../chart/options.dart' as options;
import '../../morphic/rendering/constraints.dart' as constraints;

import '../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

abstract class ChartViewMakerCL extends ChartViewMaker {

  ChartViewMakerCL({
    required this.chartData,
    this.isStacked = false,
    this.xContainerLabelLayoutStrategy,
  }) : super(
    chartData: chartData,
    isStacked: isStacked,
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  )

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

  container.ChartRootContainer makeViewRoot({required ChartViewMaker chartViewMaker});

  // ##### Methods which create views (containers) for individual chart areas

  container.XContainer makeViewForDomainAxis() {
    return isUseOldDataContainer
        ? container.XContainer(chartViewMaker: this)
        : axis_container_new.NewXContainer(chartViewMaker: this);
  }

  container.YContainer makeViewForRangeAxis() {
    return isUseOldDataContainer
        ? container.YContainer(chartViewMaker: this)
        : axis_container_new.NewYContainer(chartViewMaker: this);
  }

  container.YContainer makeViewForYContainerFirst() {
    return isUseOldDataContainer
        ? container.YContainer(chartViewMaker: this)
        : axis_container_new.NewYContainer(chartViewMaker: this);
  }

  legend_container_new.LegendContainer makeViewForLegendContainer() {
    return  isUseOldDataContainer
        ? legend_container_new.LegendContainer(chartViewMaker: this)
        : legend_container_new.LegendContainer(chartViewMaker: this);
  }

  container.DataContainer makeViewForDataContainer();

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
}
*/
