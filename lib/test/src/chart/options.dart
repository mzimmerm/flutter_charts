import 'package:flutter/cupertino.dart';
import 'package:flutter_charts/src/chart/options.dart' as live_options;
import 'package:flutter_charts/test/src/chart/test_examples_legend_enums.dart' as test_examples_legend_enums;

/// Test extension of [live_options.ChartOptions] which uses the
/// test [LegendOptions] from this test library.
@immutable
class ChartOptions extends live_options.ChartOptions {
  const ChartOptions({
    super.iterativeLayoutOptions,
    super.legendOptions = const LegendOptions(),
    super.horizontalAxisContainerOptions,
    super.verticalAxisContainerOptions,
    super.dataContainerOptions,
    super.labelCommonOptions,
    super.lineChartOptions,
    super.barChartOptions,
  });

  /// Convenience constructor sets all values to default except labels and gridlines are defined not to show.
  const ChartOptions.noLabels()
      : this(
    legendOptions: const LegendOptions(
      isLegendContainerShown: false,
    ),
    horizontalAxisContainerOptions: const live_options.HorizontalAxisContainerOptions(
      isShown: false,
    ),
    verticalAxisContainerOptions: const live_options.VerticalAxisContainerOptions(
      isShown: false,
      isInputGridLinesShown: false,
    ),
  );
}

/// Test extension of [live_options.LegendOptions] which adds
/// the [LegendAndItemLayoutEnum]
/// enums used to manage tested images.
@immutable
class LegendOptions extends live_options.LegendOptions {
  const LegendOptions({
    super.isLegendContainerShown,
    super.legendContainerMarginLR,
    super.legendContainerMarginTB,
    super.betweenLegendItemsPadding,
    super.legendColorIndicatorWidth,
    super.legendItemIndicatorToLabelPad,
    super.legendTextAlign,
    this.legendAndItemLayoutEnum = test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightDefault,
  });

  /// Controls the build-in layouts for legends that client can choose
  /// without requiring code extensions.
  final test_examples_legend_enums.LegendAndItemLayoutEnum legendAndItemLayoutEnum;

}
