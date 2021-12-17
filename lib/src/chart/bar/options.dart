import '../options.dart';

import 'package:flutter/foundation.dart' show immutable;

@immutable
class VerticalBarChartOptions extends ChartOptions {
  VerticalBarChartOptions({
    // forward an instance which values will be set on super
    ChartOptions chartOptions = const ChartOptions(),
   })
      :
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
  VerticalBarChartOptions.noLabels() : this(chartOptions: const ChartOptions.noLabels());
  
}
