import 'dart:ui' as ui show Size, Rect, Paint, Canvas;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// this level
import 'package:flutter_charts/src/chart/cartesian/container/container_common.dart' as container_common
    show ChartAreaContainer;

import 'package:flutter_charts/src/chart/cartesian/view_model/view_model.dart' as view_model;
import 'package:flutter_charts/src/chart/options.dart' as live_options;
import 'package:flutter_charts/src/chart/chart_label_container.dart' as chart_label_container;

import 'package:flutter_charts/src/morphic/container/label_container.dart' as label_container;
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart' as container_base;

import 'package:flutter_charts/src/morphic/container/layouter_one_dimensional.dart' show Align, Packing;
import 'package:flutter_charts/src/morphic/container/container_edge_padding.dart' as container_edge_padding;

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
abstract class LegendContainer extends container_common.ChartAreaContainer {
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

    // manage visibility
    // If option set to hide (not shown), set the member [orderedSkip = true],
    //  which will cause offset and paint of self and all children to be skipped by the default implementations
    //  of [paint] and [applyParentOffset].
    if (!chartViewModel.chartOptions.legendOptions.isShown) {
      applyParentOrderedSkip(this, container_base.ParentOrderedSkip.skipLayoutAndPaint());
    }
  }

  /// Returns a LegendContainer with the described layout of
  /// legend items and each legend item.
  factory LegendContainer.wrappingRow({
    required view_model.ChartViewModel chartViewModel,
  }) {
    return _LegendContainerLiveWrappingRow(chartViewModel: chartViewModel);
  }

  /// Lays out the legend area.
  ///
  /// Lays out legend items, one for each data series.
  @override
  void layout() {

    if (orderedSkip.isSkipLayout) {
      layoutSize = ui.Size.zero;
      return;
    }

    buildAndReplaceChildren();
    // todo-023 : can we just call super? this appears needed, otherwise not-label results change slightly, but still correct
    //                we should probably remove this block orderedSkip - but check behavior in debugger, what
    //                happens to layoutSize, it may never be set?
    if (orderedSkip.isSkipLayout) {
      layoutSize = ui.Size.zero;
      return;
    }
    // Important: This flips from using layout() on parents to using layout() on children
    super.layout();
  }

  /// Builds the legend container contents below self,
  /// a child [container_base.Row] or [container_base.Column],
  /// which contains a list of [LegendItemContainer]s,
  /// created separately in [_createLegendItemContainers].
  @override
  void buildAndReplaceChildren() {
    replaceChildrenWith(_createChildrenOfLegendContainer());
  }

  /// Implementations of this abstract method should create a layouter that holds
  /// [LegendItemContainer]s , add the passed containers as children to the
  /// created layouter, and return the layouter.
  container_base.BoxContainer createLegendChildrenLayouter(List<container_base.BoxContainer> children);

  /// Abstract method; implementations should create a [LegendItemContainer]
  /// with specified arguments.
  ///
  /// The created [LegendItemContainer] is used (injected)
  /// by [_createLegendItemContainers] as a child of this [LegendContainer].
  /// The child describes one legend item (rectangular colored indicator
  /// and a name) for one series of data.
  ///
  LegendItemContainer makeInjectedLegendItemContainer({
    required view_model.ChartViewModel chartViewModel,
    required String label,
    required label_container.LabelStyle labelStyle,
    required ui.Paint indicatorPaint,
    // List<container_base.BoxContainer>? children, // could add for extensibility by e.g. chart description
    required int index,
  });

  /// Creates child of this [LegendItemContainer] a [container_base.Row] with two containers:
  ///   - the [LegendIndicatorRectContainer] which is a color square indicator for data series,
  ///   - the [chart_label_container.ChartLabelContainer] which describes the series.
  ///
  List<container_base.BoxContainer> _createChildrenOfLegendContainer() {

    live_options.ChartOptions options = chartViewModel.chartOptions;

    // Initially all [label_container.LabelContainer]s share same text style object from live_options.
    label_container.LabelStyle labelStyle = defaultLabelStyle(options);

    // Create the list of [LegendItemContainer]s, each an indicator and label for one data series
    var children = _createLegendItemContainers(chartViewModel, labelStyle, options);
    container_base.BoxContainer legendChildrenLayouter = createLegendChildrenLayouter(children);

    return [legendChildrenLayouter];
  }

  List<container_base.BoxContainer> _createLegendItemContainers(
    view_model.ChartViewModel chartViewModel,
    label_container.LabelStyle labelStyle,
    live_options.ChartOptions options,
  ) {
    return [
      // Using collections-for to expand to list of LegendItems. But e cannot have a block in collections-for
      for (int index = 0; index < chartViewModel.numRows; index++)
        makeInjectedLegendItemContainer(
          chartViewModel: chartViewModel,
          label:  chartViewModel.getLegendItemAt(index).name,
          labelStyle: labelStyle,
          indicatorPaint: (ui.Paint()..color = chartViewModel.getLegendItemAt(index).color),
          index: index,
      ),
    ];
  }

  label_container.LabelStyle defaultLabelStyle(live_options.ChartOptions options) {
    // Initially all [label_container.LabelContainer]s share same text style object from options.
    label_container.LabelStyle labelStyle = label_container.LabelStyle(
      textStyle: options.labelCommonOptions.labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.legendOptions.textAlign, // keep left, close to indicator
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );
    return labelStyle;
  }

}

/// Private legend container with specific layout, returned from
/// abstract factory on [LegendContainer].
class _LegendContainerLiveWrappingRow extends LegendContainer {

  _LegendContainerLiveWrappingRow({
    required super.chartViewModel,
  });

  @override
  container_base.BoxContainer createLegendChildrenLayouter(
      List<container_base.BoxContainer> children) {

    return container_base.WrappingRow(children: children);
  }

  /// Implements the creation of the [LegendItemContainer].
  @override
  LegendItemContainer makeInjectedLegendItemContainer({
    required view_model.ChartViewModel chartViewModel,
    required String label,
    required label_container.LabelStyle labelStyle,
    required ui.Paint indicatorPaint,
    required int index,
    // List<container_base.BoxContainer>? children, // could add for extensibility by e.g. chart description
  }) {
    return _LegendItemContainerLiveRow(
      chartViewModel: chartViewModel,
      label: chartViewModel.getLegendItemAt(index).name,
      labelStyle: labelStyle,
      indicatorPaint: (ui.Paint()..color = chartViewModel.getLegendItemAt(index).color),
    );
  }
}

/// Represents one item of the legend:  The rectangle for the series color
/// indicator, followed by the series label text.
///
/// Two child containers are created during the [layout]:
///    - [LegendIndicatorRectContainer] indRectContainer for the series color indicator
///    - [ChartLabelContainer] labelContainer for the series label

/// Container of one item in the chart legend; each instance corresponds to one row (series) of data.
abstract class LegendItemContainer extends container_common.ChartAreaContainer {
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
    // Create children and attach to self : moved to addAndReplaceChildren : addChildren(_createChildrenOfLegendItemContainer());
  }

  @override
  void buildAndReplaceChildren() {
    replaceChildrenWith(_createChildrenOfLegendItemContainer());
    // buildAndReplaceChildrenDefault();
  }

  /// Creates the hierarchical contents of this [LegendItemContainer]
  /// wrapped into a single layouter.
  ///
  /// The core contents is a series item indicator and a series label.
  ///
  /// Result becomes this container single child.
  List<container_base.BoxContainer> _createChildrenOfLegendItemContainer() {

    // children = list [itemInd, label], no pad or align around.
    var children = makeItemIndAndLabelBase();
    container_base.BoxContainer legendItemChildrenLayouter = createLegendItemChildrenLayouter(children);

    return [legendItemChildrenLayouter];
  }

  /// Implementations of this abstract method should create a layouter that holds
  /// [LegendItemContainer]s , add the passed containers as children to the
  /// created layouter, and return the layouter.
  container_base.BoxContainer createLegendItemChildrenLayouter(List<container_base.BoxContainer> children);

  /// Constructs the list with the legend indicator and legend label,
  /// which the caller of this method should wrap in a layout such
  /// as [RowLayout].
  ///
  /// Note: Publicly visible only to allow test extensions.
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

/// Private legend item container with specific layout, returned from
/// abstract factory on [LegendContainer].
class _LegendItemContainerLiveRow extends LegendItemContainer {

  _LegendItemContainerLiveRow({
    required super.chartViewModel,
    required super.label,
    required super.labelStyle,
    required super.indicatorPaint,
    // List<container_base.BoxContainer>? children, // could add for extensibility by e.g. chart description
  });

  /// See super.
  @override
  List<container_base.BoxContainer> _createChildrenOfLegendItemContainer() {

    // From [makeItemIndAndLabel]
    List indRectAndLabel = makeItemIndAndLabelBase();
    var indRect = indRectAndLabel[0];
    var label = indRectAndLabel[1];

    container_edge_padding.EdgePadding edgePadding = const container_edge_padding.EdgePadding(
      start: 2,
      top: 2,
      end: 2,
      bottom: 2,
    );

    return [
      container_base.Row(
        // = createLegendItemChildrenLayouter
        mainAxisAlign: Align.start,
        mainAxisPacking: Packing.tight,
        children: [
          container_base.Padder(
            edgePadding: edgePadding,
            child: indRect,
          ),
          container_base.Padder(
            edgePadding: edgePadding,
            child: label,
          ),
        ],
      )
    ];
    ////////////////
    // // children = list [itemInd, label], no pad or align around.
    // var children = makeItemIndAndLabelBase();
    // container_base.BoxContainer legendItemChildrenLayouter = createLegendItemChildrenLayouter(children);
    //
    // return [legendItemChildrenLayouter];
  }

  /// Overriden from parent with exception to verify
  /// work flow should not reach here, because this class reimplemented the caller,
  /// [_createChildrenOfLegendItemContainer].
  @override
  container_base.BoxContainer createLegendItemChildrenLayouter(
      List<container_base.BoxContainer> children) {

    throw StateError('should not reach here, this class reimplemented the caller, [_createChildrenOfLegendItemContainer]');
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
          chartViewModel.chartOptions.legendOptions.colorIndicatorWidth,
          chartViewModel.chartOptions.legendOptions.colorIndicatorWidth,
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
    if (orderedSkip.isSkipPaint) {
      return;
    };

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
