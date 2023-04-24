import 'package:logger/logger.dart' as logger;

import '../chart/view_maker.dart'; // NEW MAKER BASE

import '../morphic/container/chart_support/chart_orientation.dart';
import 'auto_layout/line/view_maker.dart'; // NEW MAKER LINE
import 'auto_layout/bar/view_maker.dart'; // NEW MAKER BAR
import 'coded_layout/line/view_maker.dart'; // OLD MAKER LINE
import 'coded_layout/bar/view_maker.dart'; // OLD MAKER BAR

import '../chart/model/data_model.dart' as model;
import '../chart/iterative_layout_strategy.dart' as strategy;

/// Classes (the only classes) that know about both new auto layout and old coded_layout
/// classes.
///
/// The abstract view maker has factory constructors that return the old coded_layout or the
/// new auto-layout instances for bar chart view maker or line chart view maker,
/// determined by the environment variable `IS_USE_OLD_LAYOUTER` defined on scripts command lines using
///   ```sh
///     --dart-define=IS_USE_OLD_LAYOUTER=true # false
///   ```
/// and picked up in Dart code using code similar to
///   ```dart
///     bool isUseOldLayouter = const bool.fromEnvironment('IS_USE_OLD_LAYOUTER', defaultValue: true);
///   ```
///
abstract class SwitchChartViewMaker extends ChartViewMaker {
  SwitchChartViewMaker ({
    required model.ChartModel chartModel,
    required ChartSeriesOrientation chartSeriesOrientation,
    required ChartStackingEnum chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super (
  chartModel: chartModel,
  chartSeriesOrientation: chartSeriesOrientation,
  chartStacking: chartStacking,
  inputLabelLayoutStrategy: inputLabelLayoutStrategy,
  );

  /// Factory switch returns instances of auto-layout or coded_layout versions of view maker
  /// for vertical bar chart.
  factory SwitchChartViewMaker.barChartViewMakerFactory({
    required model.ChartModel chartModel,
    required ChartSeriesOrientation chartSeriesOrientation,
    required ChartStackingEnum chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing SwitchChartViewMaker');
    bool isUseOldLayouter = const bool.fromEnvironment('IS_USE_OLD_LAYOUTER', defaultValue: true);

    if (isUseOldLayouter) {
      return SwitchBarChartViewMakerCL(
        chartModel: chartModel,
        chartSeriesOrientation: chartSeriesOrientation,
        chartStacking: chartStacking,
        inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    } else {
      return SwitchBarChartViewMaker(
          chartModel: chartModel,
          chartSeriesOrientation: chartSeriesOrientation,
        chartStacking: chartStacking,
          inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    }
  }

  /// Factory switch returns instances of auto-layout or coded_layout versions of view maker
  /// for line chart.
  factory SwitchChartViewMaker.lineChartViewMakerFactory({
    required model.ChartModel chartModel,
    required ChartSeriesOrientation chartSeriesOrientation,
    required ChartStackingEnum chartStacking,
    bool isStacked = false,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing SwitchChartViewMaker');
    bool isUseOldLayouter = const bool.fromEnvironment('IS_USE_OLD_LAYOUTER', defaultValue: true);

    if (isUseOldLayouter) {
      return SwitchLineChartViewMakerCL(
        chartModel: chartModel,
        chartSeriesOrientation: chartSeriesOrientation,
        chartStacking: chartStacking,
        inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    } else {
      return SwitchLineChartViewMaker(
        chartModel: chartModel,
        chartSeriesOrientation: chartSeriesOrientation,
        chartStacking: chartStacking,
        inputLabelLayoutStrategy: inputLabelLayoutStrategy,
      );
    }
  }

  // final ChartSeriesOrientation chartSeriesOrientation;

}


