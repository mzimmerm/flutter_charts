// import 'package:logger/logger.dart' as logger;
// import 'dart:developer' as dart_developer;

// this level or equivalent

import 'package:flutter_charts/src/coded_layout/chart/container.dart' as container; // OLD CONTAINER
import 'view_model.dart'; // NEW SWITCH
import 'package:flutter_charts/src/chart/view_model/view_model.dart'; // NEW
import 'package:flutter_charts/src/chart/model/data_model.dart' as model;
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';

import 'package:flutter_charts/src/coded_layout/chart/presenter.dart' as presenter; // OLD - ok to use in switch

abstract class SwitchChartViewModelCL extends SwitchChartViewModel {

  SwitchChartViewModelCL({
    required model.ChartModel chartModel,
    required ChartType chartType,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super(
    chartModel: chartModel,
    chartType: chartType,
    chartOrientation: chartOrientation,
    chartStacking: chartStacking,
    inputLabelLayoutStrategy: inputLabelLayoutStrategy,
  );

  /// Makes pointPresenters, the visuals painted on each chart column that
  /// represent data, (points and lines for the line chart,
  /// rectangles for the bar chart, and so on).
  ///
  /// See [PointPresenterCreator] and [PointPresenter] for more details.
  late presenter.PointPresenterCreator pointPresenterCreator; // equivalent of NEW ChartViewModel in OLD layout

  /// Overridden view models for chart areas.
  @override
  container.ChartRootContainerCL makeChartRootContainer({required ChartViewModel chartViewModel});

}

