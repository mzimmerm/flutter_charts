import 'package:logger/logger.dart' as logger;

import '../chart/view_maker.dart'; // NEW MAKER BASE

import 'auto_layout/line/view_maker.dart'; // NEW MAKER LINE
import 'auto_layout/bar/view_maker.dart'; // NEW MAKER BAR
import 'coded_layout/line/view_maker.dart'; // OLD MAKER LINE
import 'coded_layout/bar/view_maker.dart'; // OLD MAKER BAR

import '../chart/model/data_model_new.dart' as model;
import '../chart/iterative_layout_strategy.dart' as strategy;

/// Classes (the only classes) that know about both new auto layout and old coded_layout
/// classes.
///
/// The 'class-hierarchy-root' view maker has a factory constructor switch,
/// which returns the old or new view maker based on an environment variable.
///
abstract class SwitchChartViewMaker extends ChartViewMaker {
  SwitchChartViewMaker ({
    required model.NewModel chartData,
    bool isStacked = false,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super (
  chartData: chartData,
  isStacked: isStacked,
  xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  );

  /// Factory switch returns instances of auto-layout or coded_layout versions of view maker
  /// for vertical bar chart.
  factory SwitchChartViewMaker.switchBarConstruct({
    required model.NewModel chartData,
    bool isStacked = false,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing SwitchChartViewMaker');
    bool isUseOldDataContainer = const bool.fromEnvironment('USE_OLD_DATA_CONTAINER', defaultValue: true);

    if (isUseOldDataContainer) {
      return SwitchVerticalBarChartViewMakerCL(
        chartData: chartData,
        isStacked: isStacked,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    } else {
      return SwitchVerticalBarChartViewMaker(
          chartData: chartData,
          isStacked: isStacked,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    }
  }

  /// Factory switch returns instances of auto-layout or coded_layout versions of view maker
  /// for line chart.
  factory SwitchChartViewMaker.switchLineConstruct({
    required model.NewModel chartData,
    bool isStacked = false,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing SwitchChartViewMaker');
    bool isUseOldDataContainer = const bool.fromEnvironment('USE_OLD_DATA_CONTAINER', defaultValue: true);

    if (isUseOldDataContainer) {
      return SwitchLineChartViewMakerCL(
        chartData: chartData,
        isStacked: isStacked,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    } else {
      return SwitchLineChartViewMaker(
        chartData: chartData,
        isStacked: isStacked,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    }
  }
}


