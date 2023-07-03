// base libraries
import 'package:flutter_charts/src/chart/cartesian/container/root_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/axislabels_axislines_gridlines_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/data_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/legend_container.dart';
import 'package:flutter_charts/src/chart/view_model/view_model.dart';

/// The container-hierarchy root container of the vertical bar chart.
class BarChartRootContainer extends ChartRootContainer {

  BarChartRootContainer({
    required LegendContainer legendContainer,
    required TransposingAxisLabelsOrGridLines horizontalAxisContainer,
    required TransposingAxisLabelsOrGridLines verticalAxisContainerFirst,
    required TransposingAxisLabelsOrGridLines verticalAxisContainer,
    required DataContainer dataContainer,
    required ChartViewModel chartViewModel,
  }) : super(
          legendContainer: legendContainer,
          horizontalAxisContainer: horizontalAxisContainer,
          verticalAxisContainerFirst: verticalAxisContainerFirst,
          verticalAxisContainer: verticalAxisContainer,
          dataContainer: dataContainer,
          chartViewModel: chartViewModel,
        );
}
