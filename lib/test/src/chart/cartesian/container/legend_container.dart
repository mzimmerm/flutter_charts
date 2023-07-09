import 'dart:ui' as ui show Paint;

import 'package:flutter_charts/src/chart/cartesian/container/legend_container.dart' as chart_legend;
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart' as container_base;
import 'package:flutter_charts/src/morphic/container/label_container.dart' as label_container;
import '../../options.dart' as test_options;
import 'package:flutter_charts/src/chart/view_model/view_model.dart' as view_model;
import 'package:flutter_charts/src/chart/options.dart' as chart_options;
import 'package:flutter_charts/src/morphic/container/layouter_one_dimensional.dart' show Align, Packing;

import 'package:flutter_charts/src/morphic/container/container_edge_padding.dart' as container_edge_padding;
import 'package:flutter_charts/src/morphic/container/container_alignment.dart' as container_alignment;
import 'package:flutter_charts/src/morphic/container/layouter_one_dimensional.dart';

class LegendContainer extends chart_legend.LegendContainer {
  LegendContainer({
    required super.chartViewModel,
  });

  List<container_base.BoxContainer> _createChildrenOfLegendContainer() {
    chart_options.ChartOptions options = chartViewModel.chartOptions;

    // Initially all [label_container.LabelContainer]s share same text style object from chart_options.
    label_container.LabelStyle labelStyle = defaultLabelStyle(options);

    container_base.BoxContainer legendSingleChildLayouter;
    // Create the list of [LegendItemContainer]s, each an indicator and label for one data series
    var children = _makeLegendItemContainers(chartViewModel, labelStyle, options);
    switch (options.legendOptions.legendAndItemLayoutEnum) {
      case chart_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightDefault:
      // LegendOptions default: children created as [LegendItem]s in row which is start tight
        legendSingleChildLayouter = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsWrappingRowItemIsRowStartTight:
        legendSingleChildLayouter = container_base.WrappingRow(
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsColumnStartLooseItemIsRowStartLoose:
        legendSingleChildLayouter = container_base.Column(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.loose,
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsColumnStartTightItemIsRowStartTight:
      // legend items in column
        legendSingleChildLayouter = container_base.Column(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          crossAxisAlign: Align.start,         // override to left-justify
          crossAxisPacking: Packing.matrjoska, // default
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsRowCenterLooseItemIsRowEndLoose:
        legendSingleChildLayouter = container_base.Row(
          mainAxisAlign: Align.center,
          mainAxisPacking: Packing.loose,
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightSecondGreedy:
      // wrap second item to [container_base.Greedy] to test container_base.Greedy layout
        children[1] = container_base.Greedy(child: children[1]);
        legendSingleChildLayouter = container_base.Row(
          // Note: Attempt to make Align.center + Packing.loose shows no effect - the LegendItem inside container_base.Greedy
          //       remains start + tight. That make sense, as container_base.Greedy is not-positioning.
          //       If we wanted to center the LegendItem inside of container_base.Greedy, wrap the inside into Center.
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenPadded:
      // [children] were created as padded [LegendItem]s in `children = makeItemIndAndLabel(doPadIndAndLabel: true)`
        legendSingleChildLayouter = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenAligned:
      // [children] were created as aligned LegendItems in `children = makeItemIndAndLabel(doAlignIndAndLabel: true`
        legendSingleChildLayouter = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      default:
        throw StateError(
            '_makeChildrenOfLegendItemContainer: Invalid option: ${options.legendOptions.legendAndItemLayoutEnum}');
    }
    return [legendSingleChildLayouter];
  }

  /// Builds the legend container contents below self,
  /// a child [container_base.Row] or [container_base.Column],
  /// which contains a list of [LegendItemContainer]s,
  /// created separately in [_makeLegendItemContainers].
  @override
  void buildAndReplaceChildren() {
    replaceChildrenWith(_createChildrenOfLegendContainer());
  }

  List<container_base.BoxContainer> _makeLegendItemContainers(
      view_model.ChartViewModel chartViewModel,
      label_container.LabelStyle labelStyle,
      chart_options.ChartOptions options,
      ) {
    return [
      // Using collections-for to expand to list of LegendItems. But e cannot have a block in collections-for
      for (int index = 0; index < chartViewModel.numRows; index++)
        LegendItemContainer(
          chartViewModel: chartViewModel,
          label: chartViewModel.getLegendItemAt(index).name,
          labelStyle: labelStyle,
          indicatorPaint: (ui.Paint()
            ..color = chartViewModel.getLegendItemAt(index).color),
        ),
    ];
  }

}

class LegendItemContainer extends chart_legend.LegendItemContainer {

  LegendItemContainer({
    required super.chartViewModel,
    required super.label,
    required super.labelStyle,
    required super.indicatorPaint,
    // List<container_base.BoxContainer>? children, // could add for extensibility by e.g. chart description
  });

  @override
  void buildAndReplaceChildren() {
    replaceChildrenWith(_makeChildrenOfLegendItemContainer());
    // buildAndReplaceChildrenDefault();
  }
  
  List<container_base.BoxContainer> _makeChildrenOfLegendItemContainer() {

    // Pull out the creation, remember on this object as member _label,
    // set _labelMaxWidth on it in layout.

    container_base.BoxContainer layoutChild;
    // Default, unless changed in case branches: children = [itemInd, label], no pad or align in children
    var children = makeItemIndAndLabel();
    switch (chartViewModel.chartOptions.legendOptions.legendAndItemLayoutEnum) {
    // **NO** This forcing has been removed, keep historical note:
    //   **IFF* the layouter is the topmost Row or Column (Legend starts with Column or Row),
    //        the passed Packing and Align values are used.
    //   **ELSE* the values are irrelevant, will be replaced with Align.start, Packing.tight.
      case chart_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightDefault:
        // Handle default: children created as [LegendItem]s in row which is start tight
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsWrappingRowItemIsRowStartTight:
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsColumnStartLooseItemIsRowStartLoose:
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.loose,
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsColumnStartTightItemIsRowStartTight:
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsRowCenterLooseItemIsRowEndLoose:
        layoutChild = container_base.Row(
          mainAxisAlign: Align.end,
          mainAxisPacking: Packing.loose,
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightSecondGreedy:
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenPadded:
      // create padded children
        children = makeItemIndAndLabel(doPadIndAndLabel: true);
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case test_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenAligned:
      // create aligned children
        children = makeItemIndAndLabel(doAlignIndAndLabel: true);
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      default:
        throw StateError(
            '_makeChildrenOfLegendItemContainer: Invalid option: ${chartViewModel.chartOptions.legendOptions.legendAndItemLayoutEnum}');
    }
    return [layoutChild];
  }


  /// Returns a  a 2-member list with item indicator and label which caller wraps typically in a [container_base.Row]
  /// or a [container_base.Column]
  ///
  /// Invokes super to get the containers, then pads or wraps them
  /// according to passed [doPadIndAndLabel] and [doAlignIndAndLabel].
  List<container_base.BoxContainer> makeItemIndAndLabel({
    bool doPadIndAndLabel = false,
    bool doAlignIndAndLabel = false,
  }) {
    List indRectAndLabel = super.makeItemIndAndLabelBase(
/* todo-00-done
      doPadIndAndLabel: doPadIndAndLabel,
      doAlignIndAndLabel: doAlignIndAndLabel,
*/
    );
    var indRect = indRectAndLabel[0];
    var label = indRectAndLabel[1];

    if (doPadIndAndLabel) {
      container_edge_padding.EdgePadding edgePadding = const container_edge_padding.EdgePadding(
        start: 3,
        top: 10,
        end: 3,
        bottom: 20,
      );
      return [
        container_base.Padder(
          edgePadding: edgePadding,
          child: indRect,
        ),
        container_base.Padder(
          edgePadding: edgePadding,
          child: label,
        ),
      ];
    } else if (doAlignIndAndLabel) {
      return [
        container_base.Row(
            children: [
              container_base.Aligner(
                childHeightBy: 3,
                childWidthBy: 1.2,
                alignment: container_alignment.Alignment.startTop,
                child: indRect,
              ),
              container_base.Aligner(
                childHeightBy: 5,
                childWidthBy: 1.2,
                alignment: container_alignment.Alignment.endBottom,
                child: label,
              ),
            ]
        )
      ];

    } else {
      return [
        indRect,
        label,
      ];
    }
  }


}