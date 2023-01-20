import 'dart:ui' as ui show Size, Offset, Paint, Canvas, Color;
import 'dart:math' as math show max;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

import '../morphic/rendering/constraints.dart' show BoxContainerConstraints;
import 'container.dart';
import 'label_container.dart';
import 'options.dart';

import 'container_layouter_base.dart' show BoxContainer, LayoutableBox;
import 'label_container_old_layout.dart' show LabelContainerOriginalKeep;

class LegendContainerOriginalKeep extends ChartAreaContainer {
  // ### calculated values

  /// Constructs the container that holds the data series legends labels and
  /// color indicators.
  ///
  /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  LegendContainerOriginalKeep({
    required ChartRootContainer chartRootContainer,
  }) : super(
    chartRootContainer: chartRootContainer,
  );

  /// Lays out the legend area.
  ///
  /// Evenly divides the [availableWidth] to all legend items.
  @override
  void layout(BoxContainerConstraints boxConstraints) {
    if (!chartRootContainer.data.chartOptions.legendOptions.isLegendContainerShown) {
      return;
    }
    ChartOptions options = chartRootContainer.data.chartOptions;
    double containerMarginTB = options.legendOptions.legendContainerMarginTB;
    double containerMarginLR = options.legendOptions.legendContainerMarginLR;

    List<String> dataRowsLegends = chartRootContainer.data.dataRowsLegends;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: options.labelCommonOptions.labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.legendOptions.legendTextAlign, // keep left, close to indicator
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );

    // First paint all legends, to figure out max height of legends to center all
    // legends label around common center.

    double legendItemWidth = (boxConstraints.size.width - 2.0 * containerMarginLR) / dataRowsLegends.length;

    // Layout legend core: for each row, create and position
    //   - an indicator rectangle and it's paint
    //   - label painter
    for (int index = 0; index < dataRowsLegends.length; index++) {
      ui.Paint indicatorPaint = ui.Paint();
      List<ui.Color> dataRowsColors = chartRootContainer.data.dataRowsColors;
      indicatorPaint.color = dataRowsColors[index % dataRowsColors.length];

      var legendItemBoxConstraints = BoxContainerConstraints(
          minSize: boxConstraints.minSize,
          maxSize: ui.Size(legendItemWidth, boxConstraints.maxSize.height,),
      );

      var legendItemContainer = LegendItemContainerOriginalKeep(
        label: dataRowsLegends[index],
        labelStyle: labelStyle,
        indicatorPaint: indicatorPaint,
        options: options,
      );

      legendItemContainer.layout(legendItemBoxConstraints);

      legendItemContainer.applyParentOffset(this, 
        ui.Offset(
          containerMarginLR + index * legendItemWidth,
          containerMarginTB,
        ),
      );

      addChildToHierarchyDeprecated(this, legendItemContainer);
    }

    layoutSize = ui.Size(
      boxConstraints.size.width,
      children.map((legendItemContainer) => legendItemContainer.layoutSize.height).reduce(math.max) + (2.0 * containerMarginTB),

    );
  }

  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    if (!chartRootContainer.data.chartOptions.legendOptions.isLegendContainerShown) {
      return;
    }
    // super.applyParentOffset(caller, offset); // super did double-offset as legendItemContainer etc are on 2 places

    for (BoxContainer legendItemContainer in children) {
      legendItemContainer.applyParentOffset(this, offset);
    }
  }

  @override
  void paint(ui.Canvas canvas) {
    if (!chartRootContainer.data.chartOptions.legendOptions.isLegendContainerShown) {
      return;
    }
    for (BoxContainer legendItemContainer in children) {
      legendItemContainer.paint(canvas);
    }
  }
}

class LegendItemContainerOriginalKeep extends BoxContainer {

  /// Rectangle of the legend color square series indicator

  /// Paint used to paint the indicator
  final ui.Paint _indicatorPaint;

  final ChartOptions _options;

  final LabelStyle _labelStyle;
  final String _label;

  LegendItemContainerOriginalKeep({
    required String label,
    required LabelStyle labelStyle,
    required ui.Paint indicatorPaint,
    required ChartOptions options,
  })  :
  // We want to only create as much as we can in layout for clarity,
  // as a price, need to hold on on label and style from constructor
        _label = label,
        _labelStyle = labelStyle,
        _indicatorPaint = indicatorPaint,
        _options = options,
        super();

  @override
  void layout(BoxContainerConstraints boxConstraints) {
    // Save a few repeated values, calculated the width given to LabelContainer,
    //   and create the LabelContainer.

    double indicatorSquareSide = _options.legendOptions.legendColorIndicatorWidth;
    double indicatorToLabelPad = _options.legendOptions.legendItemIndicatorToLabelPad;
    double betweenLegendItemsPadding = _options.legendOptions.betweenLegendItemsPadding;
    double labelMaxWidth =
        boxConstraints.size.width - (indicatorSquareSide + indicatorToLabelPad + betweenLegendItemsPadding);
    if (allowParentToSkipOnDistressedSize && labelMaxWidth <= 0.0) {
      applyParentOrderedSkip(this, true);
      // orderedSkip = true;
      layoutSize = ui.Size.zero;
      return;
    }

    // Create member containers, add as children, and lay them out
    LegendIndicatorRectContainer indRectContainer = LegendIndicatorRectContainer(
      indicatorPaint: _indicatorPaint,
      options: _options,
    );
    addChildToHierarchyDeprecated(this, indRectContainer);
    indRectContainer.layout(BoxContainerConstraints.unused());

    LabelContainerOriginalKeep labelContainer = LabelContainerOriginalKeep(
      label: _label,
      labelTiltMatrix: vector_math.Matrix2.identity(), // No tilted labels in LegendItemContainer
      labelMaxWidth: labelMaxWidth,
      labelStyle: _labelStyle,
    );
    addChildToHierarchyDeprecated(this, labelContainer);
    labelContainer.layout(BoxContainerConstraints.unused());

    // Layout legend item elements (indicator, pad, label) flowing from left:

    // 2. Y Center the indicator and label on same horizontal Y level
    //   ind stands for "indicator" - the series color indicator square
    double indAndLabelCenterY = math.max(
      labelContainer.layoutSize.height,
      indRectContainer.layoutSize.height,
    ) /
        2.0;
    double indOffsetY = indAndLabelCenterY - indRectContainer.layoutSize.height / 2.0;
    double labelOffsetY = indAndLabelCenterY - labelContainer.layoutSize.height / 2.0;

    // 3. Calc the X offset to both indicator and label, so indicator is left,
    //    then padding, then the label
    double indOffsetX = 0.0; // indicator starts on the left
    double labelOffsetX = indOffsetX + indRectContainer.layoutSize.width + indicatorToLabelPad;

    // 4. Position the child rectangle and label within this container
    indRectContainer.applyParentOffset(this, ui.Offset(
      indOffsetX,
      indOffsetY,
    ));

    labelContainer.applyParentOffset(this, ui.Offset(
      labelOffsetX,
      labelOffsetY,
    ));

    // 6. And store the layout size on member of self
    layoutSize = ui.Size(
      indRectContainer.layoutSize.width + indicatorToLabelPad + labelContainer.layoutSize.width + betweenLegendItemsPadding,
      math.max(
        labelContainer.layoutSize.height,
        indRectContainer.layoutSize.height,
      ),
    );

    // Make sure we fit all available width
    assert(boxConstraints.size.width + 1.0 >= layoutSize.width); // todo-2 within epsilon
  }

  /// Overridden super's [paint] to also paint the rectangle indicator square.
  @override
  void paint(ui.Canvas canvas) {
    if (orderedSkip) return;

    for (var rectThenLabelContainer in children) {
      rectThenLabelContainer.paint(canvas);
    }
  }

  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    if (orderedSkip) return;

    // super.applyParentOffset(caller, offset); // super did double-offset as rectThenLabelContainer etc are on 2 places
    for (var rectThenLabelContainer in children) {
      rectThenLabelContainer.applyParentOffset(this, offset);
    }
  }
}

