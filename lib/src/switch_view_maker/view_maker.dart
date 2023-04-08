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
/// determined by the environment variable `USE_OLD_DATA_CONTAINER` defined on scripts command lines using
///   ```sh
///     --dart-define=USE_OLD_DATA_CONTAINER=true # false
///   ```
/// and picked up in Dart code using code similar to
///   ```dart
///     bool isUseOldDataContainer = const bool.fromEnvironment('USE_OLD_DATA_CONTAINER', defaultValue: true);
///   ```
///
abstract class SwitchChartViewMaker extends ChartViewMaker {
  SwitchChartViewMaker ({
    required model.ChartModel chartModel,
    required ChartSeriesOrientation chartSeriesOrientation,
    bool isStacked = false,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super (
  chartModel: chartModel,
  chartSeriesOrientation: chartSeriesOrientation,
  isStacked: isStacked,
  xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  );

  /// Factory switch returns instances of auto-layout or coded_layout versions of view maker
  /// for vertical bar chart.
  factory SwitchChartViewMaker.barChartViewMakerFactory({
    required model.ChartModel chartModel,
    required ChartSeriesOrientation chartSeriesOrientation,
    bool isStacked = false,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing SwitchChartViewMaker');
    bool isUseOldDataContainer = const bool.fromEnvironment('USE_OLD_DATA_CONTAINER', defaultValue: true);

    if (isUseOldDataContainer) {
      return SwitchVerticalBarChartViewMakerCL(
        chartModel: chartModel,
        chartSeriesOrientation: chartSeriesOrientation,
        isStacked: isStacked,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    } else {
      return SwitchVerticalBarChartViewMaker(
          chartModel: chartModel,
          chartSeriesOrientation: chartSeriesOrientation,
          isStacked: isStacked,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    }
  }

  /// Factory switch returns instances of auto-layout or coded_layout versions of view maker
  /// for line chart.
  factory SwitchChartViewMaker.lineChartViewMakerFactory({
    required model.ChartModel chartModel,
    required ChartSeriesOrientation chartSeriesOrientation,
    bool isStacked = false,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing SwitchChartViewMaker');
    bool isUseOldDataContainer = const bool.fromEnvironment('USE_OLD_DATA_CONTAINER', defaultValue: true);

    if (isUseOldDataContainer) {
      return SwitchLineChartViewMakerCL(
        chartModel: chartModel,
        chartSeriesOrientation: chartSeriesOrientation,
        isStacked: isStacked,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    } else {
      return SwitchLineChartViewMaker(
        chartModel: chartModel,
        chartSeriesOrientation: chartSeriesOrientation,
        isStacked: isStacked,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    }
  }

  // final ChartSeriesOrientation chartSeriesOrientation;

}


