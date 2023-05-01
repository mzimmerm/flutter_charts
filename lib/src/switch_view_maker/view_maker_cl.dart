// import 'package:logger/logger.dart' as logger;
// import 'dart:developer' as dart_developer;

// this level or equivalent

import '../coded_layout/chart/container.dart' as container; // OLD CONTAINER
import 'view_maker.dart'; // NEW SWITCH
import '../chart/view_maker.dart'; // NEW
import '../chart/model/data_model.dart' as model;
import '../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import '../morphic/container/chart_support/chart_style.dart';

import '../coded_layout/chart/presenter.dart' as presenter; // OLD - ok to use in switch

abstract class SwitchChartViewMakerCL extends SwitchChartViewMaker {

  SwitchChartViewMakerCL({
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
  /// See [PointPresenterCreator] and [PointPresenter] for more details.
  late presenter.PointPresenterCreator pointPresenterCreator; // equivalent of NEW ChartViewMaker in OLD layout

  /// Overridden view makers for chart areas.
  @override
  container.ChartRootContainerCL makeChartRootContainer({required ChartViewMaker chartViewMaker});

/* todo-00-last-last-done
  @override
  container.HorizontalAxisContainerCL makeViewForHorizontalAxis() {
        return container.HorizontalAxisContainerCL(chartViewMaker: this);
  }


  @override
  container.VerticalAxisContainerCL makeViewForVerticalAxis() {
        return container.VerticalAxisContainerCL(chartViewMaker: this);
  }

  @override
  container.VerticalAxisContainerCL makeViewForVerticalAxisContainerFirst() {
    return container.VerticalAxisContainerCL(chartViewMaker: this);
  }
*/

/* todo-00-last-last-last-done
  @override
  container.DataContainerCL makeViewForDataContainer();
 */
}

