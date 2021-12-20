import '../options.dart';

import 'package:flutter/foundation.dart' show immutable;

@immutable
class VerticalBarChartOptions extends ChartOptions {
  /// Constructor with default values; super values can be set by passing an instantiated [ChartOptions] super.
  VerticalBarChartOptions({
    // Forward an instance which values will be set on super
    ChartOptions chartOptions = const ChartOptions(),
  }) : super(
          legendOptions: chartOptions.legendOptions,
          xContainerOptions: chartOptions.xContainerOptions,
          yContainerOptions: chartOptions.yContainerOptions,
          dataContainerOptions: chartOptions.dataContainerOptions,
          labelCommonOptions: chartOptions.labelCommonOptions,
        );

  /// Constructor with default values except no labels.
  VerticalBarChartOptions.noLabels()
      : this(
          chartOptions: const ChartOptions.noLabels(),
        );
}
