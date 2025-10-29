import 'package:logger/logger.dart' as logger;

// this level down
import 'package:flutter_charts/src/switch_view_model/auto_layout/line/view_model.dart'; // NEW VIEW MODEL LINE
import 'package:flutter_charts/src/switch_view_model/auto_layout/bar/view_model.dart'; // NEW VIEW MODEL BAR
import 'package:flutter_charts/src/switch_view_model/coded_layout/line/view_model.dart'; // OLD VIEW MODEL LINE
import 'package:flutter_charts/src/switch_view_model/coded_layout/bar/view_model.dart'; // OLD VIEW MODEL BAR

import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart' show BoxContainer;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';

import 'package:flutter_charts/src/chart/model/data_model.dart' as model;
import 'package:flutter_charts/src/chart/view_model/view_model.dart'; // NEW VIEW MODEL BASE
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy;
import 'package:flutter_charts/src/chart/options.dart' show ChartPaddingGroup;


import 'package:flutter_charts/test/src/switch_view_model/coded_layout/bar/view_model.dart' as testing_bar_view_model;
import 'package:flutter_charts/test/src/switch_view_model/coded_layout/line/view_model.dart' as testing_line_view_model;


List<BoxContainer> directionWrapperAroundCL(List<BoxContainer> p1, ChartPaddingGroup p2) => throw StateError('Should not be called in coded_layout CL situation.');

/// This abstract view model allows to create either the legacy 'coded_layout' ('CL')
/// view model, or the new 'auto_layout' used view model.
///
/// It has factory constructors that return either the old coded_layout or the
/// new auto_layout instances for bar chart view model or line chart view model,
/// determined by the environment variable `CHART_LAYOUTER` defined on scripts command lines using
///   ```sh
///     --dart-define=CHART_LAYOUTER=oldManualLayouter # false
///   ```
/// and picked up in Dart code using code similar to
///   ```dart
///     const String chartLayouterStr = String.fromEnvironment('CHART_LAYOUTER', defaultValue: 'oldManualLayouter').replaceFirst('ChartLayouter.', '');
///     ChartLayouter chartLayouter = chartLayouterStr.asEnum(ChartLayouter.values);
///   ```
///
/// This class [ChartViewModelCL] is the only 'reversed dependency' class,
/// in the sense it is the only 'new' 'auto_layout' related class that knows about (depend on)
/// both the new 'auto_layout' and the old 'coded_layout' classes.
///
/// Example: [ChartViewModelCL.barChartViewModelFactory] returns either
///          [BarChartViewModelCLCL] or [BarChartViewModelCL].
///
abstract class ChartViewModelCL extends ChartViewModel {
  ChartViewModelCL ({
    required model.ChartModel chartModel,
    required ChartType chartType,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    // todo-00-done: required this.liveOrTesting,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super (
  chartModel: chartModel,
  chartType: chartType,
  chartOrientation: chartOrientation,
  chartStacking: chartStacking,
  inputLabelLayoutStrategy: inputLabelLayoutStrategy,
  );

  /// Temporary allows to instantiate live or testing components
  ///
  // todo-00-done: final LiveOrTesting liveOrTesting;

  /// Factory switch returns instances of auto_layout or coded_layout versions of view model
  /// for vertical bar chart.
  factory ChartViewModelCL.barChartViewModelFactory({
    required model.ChartModel chartModel,
    required ChartType chartType,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    // todo-00-done: required LiveOrTesting liveOrTesting,
    ChartLayouter chartLayouter = ChartLayouter.oldManualLayouter,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing ChartViewModelCL');

    if (chartLayouter == ChartLayouter.oldManualLayouter) {
      return BarChartViewModelCLCL(
        chartModel: chartModel,
        chartType: chartType,
        chartOrientation: chartOrientation,
        chartStacking: chartStacking,
        // todo-00-done: liveOrTesting: LiveOrTesting.testing,
        inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    } else {
      // todo-00-done: replaced all with testing
      /*
      switch (liveOrTesting) {
        case LiveOrTesting.live:
          return BarChartViewModelCL(
            chartModel: chartModel,
            chartType: chartType,
            chartOrientation: chartOrientation,
            chartStacking: chartStacking,
            liveOrTesting: LiveOrTesting.live,
            inputLabelLayoutStrategy: inputLabelLayoutStrategy,
          );
        case LiveOrTesting.testing:
          return testing_bar_view_model.BarChartViewModelCL(
            chartModel: chartModel,
            chartType: chartType,
            chartOrientation: chartOrientation,
            liveOrTesting: LiveOrTesting.testing,
            chartStacking: chartStacking,
            inputLabelLayoutStrategy: inputLabelLayoutStrategy,
          );
      }
      */
      return testing_bar_view_model.BarChartViewModelCL(
        chartModel: chartModel,
        chartType: chartType,
        chartOrientation: chartOrientation,
        // todo-00-done: liveOrTesting: LiveOrTesting.testing,
        chartStacking: chartStacking,
        inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    }
  }

  /// Factory switch returns instances of auto_layout or coded_layout versions of view model
  /// for line chart.
  factory ChartViewModelCL.lineChartViewModelFactory({
    required model.ChartModel chartModel,
    required ChartType chartType,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    // todo-00-done: required LiveOrTesting liveOrTesting,
    ChartLayouter chartLayouter = ChartLayouter.oldManualLayouter,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing ChartViewModelCL');

    if (chartLayouter == ChartLayouter.oldManualLayouter) {
      return LineChartViewModelCLCL(
        chartModel: chartModel,
        chartType: chartType,
        chartOrientation: chartOrientation,
        chartStacking: chartStacking,
        // todo-00-done: liveOrTesting: LiveOrTesting.testing,
        inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    } else {
      // todo-00-done: replaced all with testing
      /*
      switch (liveOrTesting) {
        case LiveOrTesting.live:
          return LineChartViewModelCL(
            chartModel: chartModel,
            chartType: chartType,
            chartOrientation: chartOrientation,
            chartStacking: chartStacking,
            liveOrTesting: LiveOrTesting.live,
            inputLabelLayoutStrategy: inputLabelLayoutStrategy,
          );
        case LiveOrTesting.testing:
          return testing_line_view_model.LineChartViewModelCL(
            chartModel: chartModel,
            chartType: chartType,
            chartOrientation: chartOrientation,
            liveOrTesting: LiveOrTesting.testing,
            chartStacking: chartStacking,
            inputLabelLayoutStrategy: inputLabelLayoutStrategy,
          );
      }
      */
      return testing_line_view_model.LineChartViewModelCL(
        chartModel: chartModel,
        chartType: chartType,
        chartOrientation: chartOrientation,
        // todo-00-done: liveOrTesting: LiveOrTesting.testing,
        chartStacking: chartStacking,
        inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    }
  }

  // final ChartOrientation chartOrientation;

}


