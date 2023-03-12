// import 'package:logger/logger.dart' as logger;
// import 'dart:developer' as dart_developer;

// this level or equivalent
import '../coded_layout/chart/container.dart' as container; // OLD CONTAINER
import 'view_maker.dart'; // NEW SWITCH
import '../chart/view_maker.dart'; // NEW
import '../chart/model/data_model_new.dart' as model;
import '../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

abstract class SwitchChartViewMakerCL extends SwitchChartViewMaker {

  SwitchChartViewMakerCL({
    required model.NewModel chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartData: chartData,
    isStacked: isStacked,
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  );

  /// Overridden view makers for chart areas.
  @override
  container.ChartRootContainerCL makeViewRoot({required ChartViewMaker chartViewMaker});

  @override
  container.XContainerCL makeViewForDomainAxis() {
        return container.XContainerCL(chartViewMaker: this);
  }

  @override
  container.YContainerCL makeViewForRangeAxis() {
        return container.YContainerCL(chartViewMaker: this);
  }

  @override
  container.YContainerCL makeViewForYContainerFirst() {
    return container.YContainerCL(chartViewMaker: this);
  }

  @override
  container.DataContainerCL makeViewForDataContainer();

}

