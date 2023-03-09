// import 'package:logger/logger.dart' as logger;

import '../container_new/data_container_new.dart';
import '../container_new/axis_container_new.dart';

// base libraries
import '../view_maker.dart';
import '../../coded_layout/chart/container.dart';
import '../container_new/line/root_container_new.dart';
import '../model/data_model_new.dart';

import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import '../../coded_layout/chart/line/container.dart';
import 'container_new.dart';

/// Concrete [ChartViewMaker] for [LineChart].
///
/// See [ChartViewMaker] for help.
class LineChartViewMaker extends ChartViewMaker {
  LineChartViewMaker({
    required NewModel chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartData: chartData,
          isStacked: false, // line chart only supports non-stacked for now
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        );

  /// Concrete implementation returns the root for line chart.
  @override
  LineChartRootContainer makeViewRoot({required ChartViewMaker chartViewMaker}) {
    var legendContainer = makeViewForLegendContainer();
    var xContainer      = makeViewForDomainAxis();
    var yContainerFirst = makeViewForYContainerFirst();
    var yContainer      = makeViewForRangeAxis();
    var dataContainer   = makeViewForDataContainer();

    if (isUseOldDataContainer) {
      return LineChartRootContainer(
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
      return NewLineChartRootContainer(
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
  DataContainer makeViewForDataContainer() {
    if (isUseOldDataContainer) {
      return LineChartDataContainer(
        chartViewMaker: this,
      );
    } else {
      return NewLineChartDataContainer(
        chartViewMaker: this,
      );
    }
  }

  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// If resolved to [true], Y axis will start on the minimum of Y values, otherwise at [0.0].
  ///
  /// This is the method used in code logic when building the Y labels and axis.
  ///
  /// The related variable [DataContainerOptions.extendAxisToOriginRequested],
  /// is merely a request that may not be granted in some situations.
  ///
  /// On this line chart container, allow the y axis start from 0 if requested by options.
  @override
  bool get extendAxisToOrigin => chartOptions.dataContainerOptions.extendAxisToOriginRequested;
}
