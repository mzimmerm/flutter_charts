import 'dart:ui' as ui show Size, Rect, Paint, Canvas;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// this level
import 'package:flutter_charts/src/chart/cartesian/container/container_common.dart' as container_common
    show ChartAreaContainer;

import 'package:flutter_charts/src/chart/view_model/view_model.dart' as view_model;
import 'package:flutter_charts/src/chart/options.dart' as chart_options;
import 'package:flutter_charts/src/chart/chart_label_container.dart' as chart_label_container;

import 'package:flutter_charts/src/morphic/container/label_container.dart' as label_container;
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart' as container_base;
import 'package:flutter_charts/src/morphic/container/layouter_one_dimensional.dart';

/// Lays out the legend area for the chart for legends in [ChartModel.byRowLegends].
///
/// The legend area contains individual legend items represented
/// by [LegendItemContainer]. Each legend item
/// has a color square and text, which describes one data row (that is,
/// one data series).
///
/// The legends label texts should be short as we use [container_base.Row] for the layout, which
/// may overflow to the right.
///
/// This extension of [ChartAreaContainer] operates as follows:
/// - Horizontally available space is all used (filled).
/// - Vertically available space is used only as much as needed.
/// The used amount is given by the maximum label or series indicator height,
/// plus extra spacing.
class LegendContainer extends container_common.ChartAreaContainer {
  // ### calculated values

  /// Constructs the container that holds the data series legends labels and
  /// color indicators.
  LegendContainer({
    required view_model.ChartViewModel chartViewModel,
    // List<container_base.BoxContainer>? children, // could add for extensibility by e.g. add legend comment
  }) : super(
          chartViewModel: chartViewModel,
        ) {
    // Create children and attach to self: moved to buildAndReplaceChildren : addChildren(_createChildrenOfLegendContainer());

    // If option set to hide (not shown), set the member [orderedSkip = true],
    //  which will cause offset and paint of self and all children to be skipped by the default implementations
    //  of [paint] and [applyParentOffset].
    if (!chartViewModel.chartOptions.legendOptions.isLegendContainerShown) {
      applyParentOrderedSkip(this, true);
    }
  }

  /// Creates child of this [LegendItemContainer] a [container_base.Row] with two containers:
  ///   - the [LegendIndicatorRectContainer] which is a color square indicator for data series,
  ///   - the [chart_label_container.ChartLabelContainer] which describes the series.
  ///
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
      default:
        throw StateError(
            '_createChildrenOfLegendContainer: Invalid option: ${options.legendOptions.legendAndItemLayoutEnum}');
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
          indicatorPaint: (ui.Paint()..color = chartViewModel.getLegendItemAt(index).color),
        ),
    ];
  }

  label_container.LabelStyle defaultLabelStyle(chart_options.ChartOptions options) {
    // Initially all [label_container.LabelContainer]s share same text style object from chart_options.
    label_container.LabelStyle labelStyle = label_container.LabelStyle(
      textStyle: options.labelCommonOptions.labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.legendOptions.legendTextAlign, // keep left, close to indicator
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );
    return labelStyle;
  }

  /// Lays out the legend area.
  ///
  /// Lays out legend items, one for each data series.
  @override
  void layout() {
    buildAndReplaceChildren();
    // todo-023 : can we just call super? this appears needed, otherwise not-label results change slightly, but still correct
    //                we should probably remove this block orderedSkip - but check behavior in debugger, what
    //                happens to layoutSize, it may never be set?
    if (orderedSkip) {
      layoutSize = const ui.Size(0.0, 0.0);
      return;
    }
    // Important: This flips from using layout() on parents to using layout() on children
    super.layout();
  }
}

/// Represents one item of the legend:  The rectangle for the series color
/// indicator, followed by the series label text.
///
/// Two child containers are created during the [layout]:
///    - [LegendIndicatorRectContainer] indRectContainer for the series color indicator
///    - [ChartLabelContainer] labelContainer for the series label

/// Container of one item in the chart legend; each instance corresponds to one row (series) of data.
class LegendItemContainer extends container_common.ChartAreaContainer {
  /// Rectangle of the legend color square series indicator

  /// Paint used to paint the indicator
  final ui.Paint _indicatorPaint;

  final label_container.LabelStyle _labelStyle;
  final String _label;

  LegendItemContainer({
    required view_model.ChartViewModel chartViewModel,
    required String label,
    required label_container.LabelStyle labelStyle,
    required ui.Paint indicatorPaint,
    // List<container_base.BoxContainer>? children, // could add for extensibility by e.g. chart description
  })  :
        // We want to only create as much as we can in layout for clarity,
        // as a price, need to hold on on label and style from constructor
        _label = label,
        _labelStyle = labelStyle,
        _indicatorPaint = indicatorPaint,
        super(
          chartViewModel: chartViewModel,
        ) {
    // Create children and attach to self : moved to addAndReplaceChildren : addChildren(_makeChildrenOfLegendItemContainer());
  }

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
    var children = makeItemIndAndLabelBase();
    switch (chartViewModel.chartOptions.legendOptions.legendAndItemLayoutEnum) {
      case chart_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightDefault:
        // LegendOptions default: children created as [LegendItem]s in row which is start tight
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsWrappingRowItemIsRowStartTight:
        layoutChild = container_base.WrappingRow(
          children: children,
        );
        break;
      default:
        throw StateError(
            '_makeChildrenOfLegendItemContainer: Invalid option: ${chartViewModel.chartOptions.legendOptions.legendAndItemLayoutEnum}');
    }
    return [layoutChild];
  }

  /// Constructs the list with the legend indicator and legend label, which caller wraps
  /// in [RowLayout].
  ///
  /// Publicly visible only to allow test extensions.
  List<container_base.BoxContainer> makeItemIndAndLabelBase() {
    var indRect = LegendIndicatorRectContainer(
      chartViewModel: chartViewModel,
      indicatorPaint: _indicatorPaint,
    );
    var label = chart_label_container.ChartLabelContainer(
      chartViewModel: chartViewModel,
      label: _label,
      labelTiltMatrix: vector_math.Matrix2.identity(), // No tilted labels in LegendItemContainer
      labelStyle: _labelStyle,
    );
    return [
      indRect,
      label,
    ];
  }
}

/// Represents the series color indicator square in the legend.
class LegendIndicatorRectContainer extends container_common.ChartAreaContainer {
  /// Rectangle of the legend color square series indicator.
  /// This is moved to offset then [paint]ed using rectangle paint primitive.
  late final ui.Size _indicatorSize;

  /// Paint used to paint the indicator
  final ui.Paint _indicatorPaint;

  LegendIndicatorRectContainer({
    required view_model.ChartViewModel chartViewModel,
    required ui.Paint indicatorPaint,
  })  : _indicatorPaint = indicatorPaint,
        // Create the indicator square, later offset in applyParentOffset
        _indicatorSize = ui.Size(
          chartViewModel.chartOptions.legendOptions.legendColorIndicatorWidth,
          chartViewModel.chartOptions.legendOptions.legendColorIndicatorWidth,
        ),
        super(
          chartViewModel: chartViewModel,
        );

  /// Overridden to set the concrete layout size on this leaf.
  ///
  /// Note: Alternatively, the same result would be achieved by overriding a getter, like so:
  ///    ``` dart
  ///       @override
  ///       ui.Size get layoutSize => ui.Size(
  ///         _indicatorSize.width,
  ///         _indicatorSize.height,
  ///       );
  ///    ```
  @override
  void layout_Post_Leaf_SetSize_FromInternals() {
    if (!isLeaf) {
      throw StateError('Only a leaf can be sent this message.');
    }
    layoutSize = ui.Size(
      _indicatorSize.width,
      _indicatorSize.height,
    );
  }

  /// Overridden super's [paint] to also paint the rectangle indicator square.
  @override
  void paint(ui.Canvas canvas) {
    ui.Rect indicatorRect = offset & _indicatorSize;
    canvas.drawRect(
      indicatorRect,
      _indicatorPaint,
    );
  }

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }
}
