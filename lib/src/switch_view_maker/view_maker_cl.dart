// import 'package:logger/logger.dart' as logger;
// import 'dart:developer' as dart_developer;

// this level or equivalent
import 'package:flutter_charts/src/morphic/container/chart_support/chart_orientation.dart';

import '../coded_layout/chart/container.dart' as container; // OLD CONTAINER
import 'view_maker.dart'; // NEW SWITCH
import '../chart/view_maker.dart'; // NEW
import '../chart/model/data_model.dart' as model;
import '../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

import '../coded_layout/chart/presenter.dart' as presenter; // OLD - ok to use in switch

abstract class SwitchChartViewMakerCL extends SwitchChartViewMaker {

  SwitchChartViewMakerCL({
    required model.ChartModel chartModel,
    required ChartSeriesOrientation chartSeriesOrientation,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartModel: chartModel,
    chartSeriesOrientation: chartSeriesOrientation,
    isStacked: isStacked,
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  );

  /// Makes pointPresenters, the visuals painted on each chart column that
  /// represent data, (points and lines for the line chart,
  /// rectangles for the bar chart, and so on).
  ///
  /// See [PointPresenterCreator] and [PointPresenter] for more details.
  late presenter.PointPresenterCreator pointPresenterCreator; // equivalent of NEW ChartViewMaker in OLD layout

  /// Overridden view makers for chart areas.
  @override
  container.ChartRootContainerCL makeViewRoot({required ChartViewMaker chartViewMaker});

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

  @override
  container.DataContainerCL makeViewForDataContainer();

}

