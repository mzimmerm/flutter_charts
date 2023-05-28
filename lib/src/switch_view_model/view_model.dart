import 'package:logger/logger.dart' as logger;

import '../chart/view_model/view_model.dart'; // NEW VIEW MODEL BASE

import '../morphic/container/chart_support/chart_style.dart';
import 'auto_layout/line/view_model.dart'; // NEW VIEW MODEL LINE
import 'auto_layout/bar/view_model.dart'; // NEW VIEW MODEL BAR
import 'coded_layout/line/view_model.dart'; // OLD VIEW MODEL LINE
import 'coded_layout/bar/view_model.dart'; // OLD VIEW MODEL BAR

import '../chart/model/data_model.dart' as model;
import '../chart/iterative_layout_strategy.dart' as strategy;
import '../util/extensions_dart.dart';

/// Classes (the only classes) that know about both new auto layout and old coded_layout
/// classes.
///
/// The abstract view model has factory constructors that return the old coded_layout or the
/// new auto-layout instances for bar chart view model or line chart view model,
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
abstract class SwitchChartViewModel extends ChartViewModel {
  SwitchChartViewModel ({
    required model.ChartModel chartModel,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super (
  chartModel: chartModel,
  chartOrientation: chartOrientation,
  chartStacking: chartStacking,
  inputLabelLayoutStrategy: inputLabelLayoutStrategy,
  );

  /// Factory switch returns instances of auto-layout or coded_layout versions of view model
  /// for vertical bar chart.
  factory SwitchChartViewModel.barChartViewModelFactory({
    required model.ChartModel chartModel,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing SwitchChartViewModel');
    // todo-00-done : bool isUseOldLayouter = const bool.fromEnvironment('IS_USE_OLD_LAYOUTER', defaultValue: true);
    String chartLayouterStr = const String.fromEnvironment('CHART_LAYOUTER', defaultValue: 'oldManualLayouter').replaceFirst('ChartLayouter.', '');
    ChartLayouter chartLayouter = chartLayouterStr.asEnum(ChartLayouter.values);

    // todo-00-done : if (isUseOldLayouter) {
    if (chartLayouter == ChartLayouter.oldManualLayouter) {
      return SwitchBarChartViewModelCL(
        chartModel: chartModel,
        chartOrientation: chartOrientation,
        chartStacking: chartStacking,
        inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    } else {
      return SwitchBarChartViewModel(
          chartModel: chartModel,
          chartOrientation: chartOrientation,
          chartStacking: chartStacking,
          inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    }
  }

  /// Factory switch returns instances of auto-layout or coded_layout versions of view model
  /// for line chart.
  factory SwitchChartViewModel.lineChartViewModelFactory({
    required model.ChartModel chartModel,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing SwitchChartViewModel');
    // todo-00-done : bool isUseOldLayouter = const bool.fromEnvironment('IS_USE_OLD_LAYOUTER', defaultValue: true);

    String chartLayouterStr = const String.fromEnvironment('CHART_LAYOUTER', defaultValue: 'oldManualLayouter').replaceFirst('ChartLayouter.', '');
    ChartLayouter chartLayouter = chartLayouterStr.asEnum(ChartLayouter.values);

    // todo-00-done : if (isUseOldLayouter) {
    if (chartLayouter == ChartLayouter.oldManualLayouter) {
      return SwitchLineChartViewModelCL(
        chartModel: chartModel,
        chartOrientation: chartOrientation,
        chartStacking: chartStacking,
        inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    } else {
      return SwitchLineChartViewModel(
        chartModel: chartModel,
        chartOrientation: chartOrientation,
        chartStacking: chartStacking,
        inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    }
  }

  // final ChartOrientation chartOrientation;

}


