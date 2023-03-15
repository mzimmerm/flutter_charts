import 'dart:ui' as ui show Size, Rect, Paint, Canvas;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// this level base libraries or equivalent
import 'container_common_new.dart' as container_common_new show ChartAreaContainer;
//import '../container.dart' as container;
import '../label_container.dart' as label_container;
import '../chart_label_container.dart' as chart_label_container;
import '../container_edge_padding.dart' as container_edge_padding;
import '../container_alignment.dart' as container_alignment;
import '../container_layouter_base.dart' as container_base;
//import '../model/data_model_new.dart' as model;
import '../view_maker.dart' as view_maker;
import '../options.dart' as chart_options;
import '../layouter_one_dimensional.dart';
//import '../../container/container_key.dart';
//import '../../util/util_dart.dart';
//import '../../util/util_labels.dart' show DataRangeLabelInfosGenerator;

/// Lays out the legend area for the chart.
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
class LegendContainer extends container_common_new.ChartAreaContainer {
  // ### calculated values

  /// Constructs the container that holds the data series legends labels and
  /// color indicators.
  LegendContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    // List<container_base.BoxContainer>? children, // could add for extensibility by e.g. add legend comment
  }) : super(
    chartViewMaker: chartViewMaker,
  ) {
    // Create children and attach to self
    addChildren(_createChildrenOfLegendContainer());

    // If option set to hide (not shown), set the member [orderedSkip = true],
    //  which will cause offset and paint of self and all children to be skipped by the default implementations
    //  of [paint] and [applyParentOffset].
    if (!chartViewMaker.chartOptions.legendOptions.isLegendContainerShown) {
      applyParentOrderedSkip(this, true);
    }
  }

  /// Builds the legend container contents below self,
  /// a child [container_base.Row] or [container_base.Column],
  /// which contains a list of [LegendItemContainer]s,
  /// created separately in [_legendItems].
  List<container_base.BoxContainer> _createChildrenOfLegendContainer() {
    chart_options.ChartOptions options = chartViewMaker.chartOptions;

    List<String> dataRowsLegends = chartViewMaker.chartModel.dataRowsLegends;

    // Initially all [label_container.LabelContainer]s share same text style object from chart_options.
    label_container.LabelStyle labelStyle = label_container.LabelStyle(
      textStyle: options.labelCommonOptions.labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.legendOptions.legendTextAlign, // keep left, close to indicator
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );

    container_base.BoxContainer childLayout;
    // Create the list of [LegendItemContainer]s, each an indicator and label for one data series
    var children = _legendItems(dataRowsLegends, labelStyle, options);
    switch (options.legendOptions.legendAndItemLayoutEnum) {
      case chart_options.LegendAndItemLayoutEnum.legendIsColumnStartLooseItemIsRowStartLoose:
        childLayout = container_base.Column(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.loose,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsColumnStartTightItemIsRowStartTight:
      // default for legend column : desired and tested
        childLayout = container_base.Column(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsRowCenterLooseItemIsRowEndLoose:
        childLayout = container_base.Row(
          mainAxisAlign: Align.center,
          mainAxisPacking: Packing.loose,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTight:
      // default for legend row : desired and tested
        childLayout = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightSecondGreedy:
      // wrap second item to container_base.Greedy to test container_base.Greedy layout
        children[1] = container_base.Greedy(child: children[1]);
        childLayout = container_base.Row(
          // Note: Attempt to make Align.center + Packing.loose shows no effect - the LegendItem inside container_base.Greedy
          //       remains start + tight. That make sense, as container_base.Greedy is non-positioning.
          //       If we wanted to center the LegendItem inside of container_base.Greedy, wrap the inside into Center.
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenPadded:
      // This option pads items inside LegendItem
        childLayout = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenAligned:
      // This option aligns items inside LegendItem
        childLayout = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
    }
    return [childLayout];
  }

  List<container_base.BoxContainer> _legendItems(
      List<String> dataRowsLegends,
      label_container.LabelStyle labelStyle,
      chart_options.ChartOptions options,
      ) {
    return [
      // Using collections-for to expand to list of LegendItems. But e cannot have a block in collections-for
      for (int index = 0; index < dataRowsLegends.length; index++)
        LegendItemContainer(
          chartViewMaker: chartViewMaker,
          label: dataRowsLegends[index],
          labelStyle: labelStyle,
          indicatorPaint: (ui.Paint()
            ..color = chartViewMaker.chartModel.dataRowsColors
                .elementAt(index % chartViewMaker.chartModel.dataRowsColors.length)),
          options: options,
        ),
    ];
  }

  /// Lays out the legend area.
  ///
  /// Lays out legend items, one for each data series.
  @override
  void layout() {
    buildAndReplaceChildren();
    // todo-013 : can we just call super? this appears needed, otherwise non-label results change slightly, but still correct
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
///    - [LabelContainerOriginalKeep] labelContainer for the series label


/// Container of one item in the chart legend; each instance corresponds to one row (series) of data.
class LegendItemContainer extends container_common_new.ChartAreaContainer {

  /// Rectangle of the legend color square series indicator

  /// Paint used to paint the indicator
  final ui.Paint _indicatorPaint;

  final chart_options.ChartOptions _options;

  final label_container.LabelStyle _labelStyle;
  final String _label;

  LegendItemContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    required String label,
    required label_container.LabelStyle labelStyle,
    required ui.Paint indicatorPaint,
    required chart_options.ChartOptions options,
    // List<container_base.BoxContainer>? children, // could add for extensibility by e.g. chart description
  })  :
  // We want to only create as much as we can in layout for clarity,
  // as a price, need to hold on on label and style from constructor
        _label = label,
        _labelStyle = labelStyle,
        _indicatorPaint = indicatorPaint,
        _options = options,
        super(
          chartViewMaker: chartViewMaker,
      ) {
    // Create children and attach to self
    addChildren(_createChildrenOfLegendItemContainer());
  }


  /// Creates child of this [LegendItemContainer] a [container_base.Row] with two containers:
  ///   - the [LegendIndicatorRectContainer] which is a color square indicator for data series,
  ///   - the [chart_label_container.ChartLabelContainer] which describes the series.
  ///
  List<container_base.BoxContainer> _createChildrenOfLegendItemContainer() {

    // Pull out the creation, remember on this object as member _label,
    // set _labelMaxWidth on it in layout.

    container_base.BoxContainer layoutChild;
    var children = _itemIndAndLabel();
    switch (_options.legendOptions.legendAndItemLayoutEnum) {
    // **IFF* the returned layout is the topmost container_base.Row (Legend starts with container_base.Column),
    //        the passed Packing and Align values are used.
    // **ELSE* the values are irrelevant, will be replaced with Align.start, Packing.tight.
      case chart_options.LegendAndItemLayoutEnum.legendIsColumnStartLooseItemIsRowStartLoose:
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.loose,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsColumnStartTightItemIsRowStartTight:
      // default for legend column : Item row is top, so is NOT overridden, so must be set to intended!
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsRowCenterLooseItemIsRowEndLoose:
        layoutChild = container_base.Row(
          mainAxisAlign: Align.end,
          mainAxisPacking: Packing.loose,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTight:
      // default for legend row : desired and tested
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightSecondGreedy:
      // default for legend row : desired and tested
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenPadded:
      // create padded children
        children = _itemIndAndLabel(doPadIndAndLabel: true);
        // default for legend row : desired and tested
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case chart_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenAligned:
      // create padded children
        children = _itemIndAndLabel(doAlignIndAndLabel: true);
        // default for legend row : desired and tested
        layoutChild = container_base.Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
    }
    return [layoutChild];
  }


  /// Constructs the list with the legend indicator and legend label, which caller wraps
  /// in [RowLayout].
  List<container_base.BoxContainer> _itemIndAndLabel({bool doPadIndAndLabel = false, bool doAlignIndAndLabel = false}) {
    var indRect = LegendIndicatorRectContainer(
      chartViewMaker: chartViewMaker,
      indicatorPaint: _indicatorPaint,
      options: _options,
    );
    var label = chart_label_container.ChartLabelContainer(
      chartViewMaker: chartViewMaker,
      label: _label,
      labelTiltMatrix: vector_math.Matrix2.identity(), // No tilted labels in LegendItemContainer
      labelStyle: _labelStyle,
      // todo-00-last-last-done : options: _options,
    );

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

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }
}

/// Represents the series color indicator square in the legend.
class LegendIndicatorRectContainer extends container_common_new.ChartAreaContainer {

  /// Rectangle of the legend color square series indicator.
  /// This is moved to offset then [paint]ed using rectangle paint primitive.
  late final ui.Size _indicatorSize;

  /// Paint used to paint the indicator
  final ui.Paint _indicatorPaint;

  LegendIndicatorRectContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    required ui.Paint indicatorPaint,
    required chart_options.ChartOptions options,
  })  : _indicatorPaint = indicatorPaint,
        // Create the indicator square, later offset in applyParentOffset
        _indicatorSize = ui.Size(
          options.legendOptions.legendColorIndicatorWidth,
          options.legendOptions.legendColorIndicatorWidth,
        ),
        super(
          chartViewMaker: chartViewMaker,
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
