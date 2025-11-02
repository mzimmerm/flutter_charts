import 'dart:ui' as ui show Paint;

import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart' as container_base;
import 'package:flutter_charts/src/morphic/container/label_container.dart' as label_container;

import 'package:flutter_charts/src/morphic/container/layouter_one_dimensional.dart' show Align, Packing;

import 'package:flutter_charts/src/chart/cartesian/container/legend_container.dart' as legend_container;
import 'package:flutter_charts/src/chart/cartesian/view_model/view_model.dart' as view_model;
import 'package:flutter_charts/src/chart/options.dart' as chart_options;

// test enums. to be removed todo-00-now remove by extending LegendOptions to TestLegendOptions or similar
import '../../test_examples_legend_enums.dart' as test_examples_legend_enums show LegendAndItemLayoutEnum;

class LegendContainer extends legend_container.LegendContainer {

  LegendContainer({
    required view_model.ChartViewModel chartViewModel,
  }) : super(
    chartViewModel: chartViewModel,
  );

  @override
  container_base.BoxContainer createLegendChildrenLayouter(List<container_base.BoxContainer> children) {
    chart_options.ChartOptions options = chartViewModel.chartOptions;

    switch (options.legendOptions.legendAndItemLayoutEnum) {
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightDefault:
      // LegendOptions default: children created as [LegendItem]s in row which is start tight
        return container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsWrappingRowItemIsRowStartTight:
        return container_base.WrappingRow(
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsColumnStartLooseItemIsRowStartLoose:
        return container_base.Column(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.loose,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsColumnStartTightItemIsRowStartTight:
      // legend items in column
        return container_base.Column(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          crossAxisAlign: Align.start,         // override to left-justify
          crossAxisPacking: Packing.matrjoska, // default
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsRowCenterLooseItemIsRowEndLoose:
        return container_base.Row(
          mainAxisAlign: Align.center,
          mainAxisPacking: Packing.loose,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightSecondGreedy:
      // Each child is LegendItemContainer.
      // Wrap the second child (second item in legend) to [container_base.Greedy]
      // to test container_base.Greedy layout. It is mildly confusing we manipulate children here again.
        children[1] = container_base.Greedy(child: children[1]);
        return container_base.Row(
          // This implements legendIsRowStartTight
          // Note: Attempt to make Align.center + Packing.loose shows no effect - the LegendItem inside container_base.Greedy
          //       remains start + tight. That make sense, as container_base.Greedy is not-positioning.
          //       If we wanted to center the LegendItem inside of container_base.Greedy, wrap the inside into Center.
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenPadded:
      // [children] were created as padded [LegendItem]s in `children = makeItemIndAndLabel(doPadIndAndLabel: true)`
        return container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenAligned:
      // [children] were created as aligned LegendItems in `children = makeItemIndAndLabel(doAlignIndAndLabel: true`
        return container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
    }

  }

}

class LegendItemContainer extends legend_container.LegendItemContainer {

  LegendItemContainer({
    required view_model.ChartViewModel chartViewModel,
    required String label,
    required label_container.LabelStyle labelStyle,
    required ui.Paint indicatorPaint,
    // List<container_base.BoxContainer>? children, // could add for extensibility by e.g. chart description
  }) : super(
    chartViewModel: chartViewModel,
    label: label,
    labelStyle: labelStyle,
    indicatorPaint: indicatorPaint,
  );

  @override
  container_base.BoxContainer createLegendItemChildrenLayouter(List<container_base.BoxContainer> children) {
    switch (chartViewModel.chartOptions.legendOptions.legendAndItemLayoutEnum) {
    // **NO** This forcing has been removed, keep historical note:
    //   **IFF* the layouter is the topmost Row or Column (Legend starts with Column or Row),
    //        the passed Packing and Align values are used.
    //   **ELSE* the values are irrelevant, will be replaced with Align.start, Packing.tight.
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightDefault:
      // Handle default: children created as [LegendItem]s in row which is start tight
        return container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsWrappingRowItemIsRowStartTight:
        return container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsColumnStartLooseItemIsRowStartLoose:
        return container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.loose,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsColumnStartTightItemIsRowStartTight:
        return container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsRowCenterLooseItemIsRowEndLoose:
        return container_base.Row(
          mainAxisAlign: Align.end,
          mainAxisPacking: Packing.loose,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightSecondGreedy:
      // This implements 'ItemIsRowStartTight'.
      // The 'SecondGreedy' part is implemented during LegendContainer creation by
      // wrapping the second child in Greedy
        return container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenPadded:
      // create padded children
        children = makeItemIndAndLabel(doPadIndAndLabel: true);
        return container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
      case test_examples_legend_enums.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenAligned:
      // create aligned children
        children = makeItemIndAndLabel(doAlignIndAndLabel: true);
        return container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
    }
  }

}