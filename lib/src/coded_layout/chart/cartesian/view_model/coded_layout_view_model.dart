// import 'package:logger/logger.dart' as logger;
// import 'dart:developer' as dart_developer;

// this level

// Morphic base
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';

// Base class ChartViewModel is from auto_layout
import 'package:flutter_charts/src/chart/cartesian/view_model/view_model.dart' show ChartViewModel;
import 'package:flutter_charts/src/chart/model/data_model.dart' as model;
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';

import 'package:flutter_charts/src/coded_layout/chart/container.dart' as container; // OLD CONTAINER
import 'package:flutter_charts/src/coded_layout/chart/presenter.dart' as presenter; // OLD -

import 'package:flutter_charts/src/chart/options.dart' show ChartPaddingGroup;

List<BoxContainer> directionWrapperAroundCL(List<BoxContainer> p1, ChartPaddingGroup p2) => throw StateError('Should not be called in coded_layout CL situation.');

abstract class ChartViewModelCL extends ChartViewModel {

  ChartViewModelCL({
    required model.ChartModel chartModel,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super(
    chartModel: chartModel,
    chartOrientation: chartOrientation,
    chartStacking: chartStacking,
    inputLabelLayoutStrategy: inputLabelLayoutStrategy,
  );

  /// Makes pointPresenters, the visuals painted on each chart column that
  /// represent data, (points and lines for the line chart,
  /// rectangles for the bar chart, and so on).
  ///
  /// See [PointPresenterCreatorOCL] and [PointPresenter] for more details.
  late presenter.PointPresenterCreatorOCL pointPresenterCreator; // equivalent of NEW ChartViewModel in OLD layout

  /// Overridden view models for chart areas.
  @override
  container.ChartRootContainerCL makeChartRootContainer({required ChartViewModel chartViewModel});

}

