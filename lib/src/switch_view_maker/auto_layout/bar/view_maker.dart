import 'package:flutter_charts/src/morphic/container/chart_support/chart_orientation.dart';
import 'package:logger/logger.dart' as logger;

import '../../../chart/container/data_container.dart';

// base libraries
import '../../../chart/view_maker.dart';
import '../../../chart/container/bar/root_container.dart';
import '../../../chart/model/data_model.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import '../../../chart/bar/container.dart';

// this level: switch/auto_layout/bar
import '../../view_maker.dart'; // NEW SWITCH

/// Concrete [ChartViewMaker] for [VerticalBarChart].
///
/// See [ChartViewMaker] for help.
class SwitchVerticalBarChartViewMaker extends SwitchChartViewMaker {
  SwitchVerticalBarChartViewMaker({
    required ChartModel chartModel,
    required ChartSeriesOrientation chartSeriesOrientation,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartModel: chartModel,
    chartSeriesOrientation: chartSeriesOrientation,
    isStacked: true, // only supported for now for bar chart
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  ) {
    logger.Logger().d('$runtimeType created');
  }

  /// Concrete implementation returns the root for vertical bar chart.
  @override
  VerticalBarChartRootContainer makeViewRoot({required ChartViewMaker chartViewMaker}) {
    var legendContainer = makeViewForLegendContainer();
    var xContainer = makeViewForDomainAxis();
    var yContainerFirst = makeViewForYContainerFirst();
    var yContainer = makeViewForRangeAxis();
    var dataContainer = makeViewForDataContainer();

    return VerticalBarChartRootContainer(
      legendContainer: legendContainer,
      xContainer: xContainer,
      yContainerFirst: yContainerFirst,
      yContainer: yContainer,
      dataContainer: dataContainer,
      chartViewMaker: chartViewMaker,
      chartModel: chartModel,
      chartOptions: chartViewMaker.chartOptions,
      isStacked: isStacked,
      xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
    );
  }

  @override
  DataContainer makeViewForDataContainer() {
    return VerticalBarChartDataContainer(
      chartViewMaker: this,
    );
  }

  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// Overridden to [false] on this bar chart container, where the y axis must start from 0.
  ///
  @override
  bool get extendAxisToOrigin => true;
}
