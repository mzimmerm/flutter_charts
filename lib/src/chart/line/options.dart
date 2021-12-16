import '../options.dart';
import 'dart:ui' as ui show Color, Paint;

// todo-00-new done: Use ui.Color as it can be const:  import 'package:flutter/material.dart' as material show Colors;
import 'package:flutter/material.dart' as material show Colors;
import 'package:flutter/foundation.dart' show immutable;

class LineChartOptions extends ChartOptions {
  /// Control the look of the circle on line chart
  final double hotspotInnerRadius;
  final double hotspotOuterRadius;

  /// Paint for the inner circle on line chart.
  /// Using common paint object for all circles, we
  /// force all circles to look the same.
  /// todo 3 - consider per dataRow control.
  final ui.Paint hotspotInnerPaint;

  final ui.Paint hotspotOuterPaint;

  /// Width of the line connecting the circles on line chart.
  /// Paint for one series. Using one option for all series, we
  /// force all series width the same.
  /// todo 3 - consider per dataRow width instances.
  final double lineStrokeWidth;

  /// Constructor with default values; super values can be set by passing an instantiated [ChartOptions] super.
  LineChartOptions({
      // forward an instance which values will be set on super
      ChartOptions chartOptions = const ChartOptions(),
      this.hotspotInnerRadius = 3.0,
      this.hotspotOuterRadius = 6.0,
      this.lineStrokeWidth = 3.0,
      // Note-design : this is how to initialize final fields which types do not have const constructor!!
      //               add them to named arguments, and initialize in initializer list.
      hotspotInnerPaint,
      hotspotOuterPaint
      // Note-design:
      // In fields with default value, the default must be constant.
      // For the hotspot paint fields, there is no ui.Paint constructor that can be constant,
      // so they must be initialized in the initialization list (NOT constructor body if they are final,
      //   as that would call setter in the body, and final does not have setters.
      // So, initializer list is the only place to set final fields which types do not have constant constructor.
      })
      : hotspotInnerPaint = ui.Paint()..color = material.Colors.yellow,
        hotspotOuterPaint = ui.Paint()..color = material.Colors.black,
        super(
          isLegendContainerShown: chartOptions.isLegendContainerShown,
          isXContainerShown: chartOptions.isXContainerShown,
          isYContainerShown: chartOptions.isYContainerShown,
          isYGridlinesShown: chartOptions.isYGridlinesShown,
          useUserProvidedYLabels: chartOptions.useUserProvidedYLabels,
          largestValuePointOnVeryTop: chartOptions.largestValuePointOnVeryTop,
          maxNumYLabels: chartOptions.maxNumYLabels,
          gridLinesColor: chartOptions.gridLinesColor,
          xLabelsColor: chartOptions.xLabelsColor,
          yLeftMinTicksWidth: chartOptions.yLeftMinTicksWidth,
          yRightMinTicksWidth: chartOptions.yRightMinTicksWidth,
          xBottomMinTicksHeight: chartOptions.xBottomMinTicksHeight,
          xLabelsPadTB: chartOptions.xLabelsPadTB,
          xLabelsPadLR: chartOptions.xLabelsPadLR,
          yLabelsPadTB: chartOptions.yLabelsPadTB,
          yLabelsPadLR: chartOptions.yLabelsPadLR,
          legendContainerMarginLR: chartOptions.legendContainerMarginLR,
          legendContainerMarginTB: chartOptions.legendContainerMarginTB,
          betweenLegendItemsPadding: chartOptions.betweenLegendItemsPadding,
          legendColorIndicatorWidth: chartOptions.legendColorIndicatorWidth,
          legendItemIndicatorToLabelPad: chartOptions.legendItemIndicatorToLabelPad,
          gridStepWidthPortionUsedByAtomicPresenter: chartOptions.gridStepWidthPortionUsedByAtomicPresenter,
          dataRowsPaintingOrder: chartOptions.dataRowsPaintingOrder,
          labelFontSize: chartOptions.labelFontSize,
          labelTextColor: chartOptions.labelTextColor,
          maxLabelReLayouts: chartOptions.maxLabelReLayouts,
          decreaseLabelFontRatio: chartOptions.decreaseLabelFontRatio,
          showEveryNthLabel: chartOptions.showEveryNthLabel,
          multiplyLabelSkip: chartOptions.multiplyLabelSkip,
          labelTiltRadians: chartOptions.labelTiltRadians,
          labelTextDirection: chartOptions.labelTextDirection,
          labelTextAlign: chartOptions.labelTextAlign,
          legendTextAlign: chartOptions.legendTextAlign,
          labelTextScaleFactor: chartOptions.labelTextScaleFactor,
          yLabelUnits: chartOptions.yLabelUnits,
        );

  /// Constructor with default values except no labels.
  LineChartOptions.noLabels() : this(chartOptions: const ChartOptions.noLabels());
}
