import 'package:logger/logger.dart' as logger;

import '../container_new/data_container_new.dart';
import '../container_new/axis_container_new.dart';

// base libraries
import '../view_maker.dart';
import '../../coded_layout/chart/container.dart';
import '../container_new/bar/root_container_new.dart';
import '../model/data_model_new.dart';

import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import '../../coded_layout/chart/bar/container.dart';
import 'container_new.dart';

/// Concrete [ChartViewMaker] for [VerticalBarChart].
///
/// See [ChartViewMaker] for help.
class VerticalBarChartViewMaker extends ChartViewMaker {
  VerticalBarChartViewMaker({
    required NewModel chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartData: chartData,
          isStacked: true, // only supported for now
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

    if (isUseOldDataContainer) {
      return VerticalBarChartRootContainer(
        legendContainer: legendContainer,
        xContainer: xContainer,
        yContainerFirst: yContainerFirst,
        yContainer: yContainer,
        dataContainer: dataContainer,
        chartViewMaker: chartViewMaker,
        chartData: chartData,
        chartOptions: chartViewMaker.chartOptions,
        isStacked: isStacked,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    } else {
      return NewVerticalBarChartRootContainer(
        legendContainer: legendContainer,
        xContainer: xContainer as NewXContainer,
        yContainerFirst: yContainerFirst as NewYContainer,
        yContainer: yContainer as NewYContainer,
        dataContainer: dataContainer as NewDataContainer,
        chartViewMaker: chartViewMaker,
        chartData: chartData,
        chartOptions: chartViewMaker.chartOptions,
        isStacked: isStacked,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    }
  }

  @override
  DataContainerCL makeViewForDataContainer() {
    if (isUseOldDataContainer) {
      return VerticalBarChartDataContainer(
        chartViewMaker: this,
      );
    } else {
      return NewVerticalBarChartDataContainer(
        chartViewMaker: this,
      );
    }
  }

  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// Overridden to [false] on this bar chart container, where the y axis must start from 0.
  ///
  @override
  bool get extendAxisToOrigin => true;
}
