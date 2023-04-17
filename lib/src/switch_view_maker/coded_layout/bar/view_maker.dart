import 'package:logger/logger.dart' as logger;

// base libraries
import '../../../chart/view_maker.dart';
import '../../../coded_layout/chart/container.dart';
import '../../../chart/model/data_model.dart';

import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import '../../../coded_layout/chart/bar/container.dart';

import '../../../morphic/container/chart_support/chart_orientation.dart';
import '../../view_maker_cl.dart'; // OLD

class SwitchVerticalBarChartViewMakerCL extends SwitchChartViewMakerCL {
  SwitchVerticalBarChartViewMakerCL({
    required ChartModel chartModel,
    required ChartSeriesOrientation chartSeriesOrientation,
    required bool isStacked,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super(
          chartModel: chartModel,
          chartSeriesOrientation: chartSeriesOrientation,
          isStacked: true, // only supported for now for bar chart
          inputLabelLayoutStrategy: inputLabelLayoutStrategy,
        ) {
    logger.Logger().d('$runtimeType created');
  }

  @override
  VerticalBarChartRootContainerCL makeViewRoot({required ChartViewMaker chartViewMaker}) {
    var legendContainer = makeViewForLegendContainer();
    var horizontalAxisContainer = makeViewForHorizontalAxis();
    var verticalAxisContainerFirst = makeViewForVerticalAxisContainerFirst();
    var verticalAxisContainer = makeViewForVerticalAxis();
    var dataContainer = makeViewForDataContainer();

    return VerticalBarChartRootContainerCL(
      legendContainer: legendContainer,
      horizontalAxisContainer: horizontalAxisContainer,
      verticalAxisContainerFirst: verticalAxisContainerFirst,
      verticalAxisContainer: verticalAxisContainer,
      dataContainer: dataContainer,
      chartViewMaker: chartViewMaker,
      chartModel: chartModel,
      chartOptions: chartViewMaker.chartOptions,
      isStacked: isStacked,
      inputLabelLayoutStrategy: inputLabelLayoutStrategy,
    );
  }

  @override
  DataContainerCL makeViewForDataContainer() {
    return VerticalBarChartDataContainerCL(
      chartViewMaker: this,
    );
  }

  @override
  bool get extendAxisToOrigin => true;
}
