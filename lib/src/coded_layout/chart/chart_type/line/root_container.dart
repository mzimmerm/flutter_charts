// base libraries
import 'package:flutter_charts/src/coded_layout/chart/container.dart';
import 'package:flutter_charts/src/coded_layout/chart/axis_container.dart';
import 'package:flutter_charts/src/coded_layout/chart/data_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/legend_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/root_container.dart';
import 'package:flutter_charts/src/chart/view_model/view_model.dart';
import 'package:flutter_charts/src/switch_view_model/view_model_cl.dart';

// this level
import 'presenter.dart'; // OLD

/// The container-hierarchy root container of the line chart in the coded_layout legacy version.
class LineChartRootContainerCL extends ChartRootContainerCL implements ChartRootContainer {
  LineChartRootContainerCL({
    required LegendContainer legendContainer,
    required HorizontalAxisContainerCL horizontalAxisContainer,
    required OutputAxisContainerCL verticalAxisContainerFirst,
    required OutputAxisContainerCL verticalAxisContainer,
    required DataContainerCL dataContainer,
    required ChartViewModel chartViewModel,
  }) : super(
          legendContainer: legendContainer,
          horizontalAxisContainer: horizontalAxisContainer,
          verticalAxisContainerFirst: verticalAxisContainerFirst,
          verticalAxisContainer: verticalAxisContainer,
          dataContainer: dataContainer,
          chartViewModel: chartViewModel,
        ) {
    (chartViewModel as SwitchChartViewModelCL).pointPresenterCreator = LineAndHotspotLeafPointPresenterCreator();
  }
}
