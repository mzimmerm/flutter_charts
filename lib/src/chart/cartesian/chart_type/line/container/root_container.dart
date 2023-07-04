// base libraries
import 'package:flutter_charts/src/chart/cartesian/container/root_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/axislabels_axislines_gridlines_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/data_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/legend_container.dart';
import 'package:flutter_charts/src/chart/view_model/view_model.dart';

/// The container-hierarchy root container of the line chart.
class LineChartRootContainer extends ChartRootContainer {
  LineChartRootContainer({
    required LegendContainer       legendContainer,
    required TransposingAxisLabels horizontalAxisContainer,
    required TransposingAxisLabels verticalAxisContainerFirst,
    required TransposingAxisLabels verticalAxisContainer,
    required DataContainer         dataContainer,
    required ChartViewModel        chartViewModel,
  }) : super(
    legendContainer: legendContainer,
    horizontalAxisContainer: horizontalAxisContainer,
    verticalAxisContainerFirst: verticalAxisContainerFirst,
    verticalAxisContainer: verticalAxisContainer,
    dataContainer: dataContainer,
    chartViewModel: chartViewModel,
    );

}
