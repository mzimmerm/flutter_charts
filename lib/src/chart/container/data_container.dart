import 'dart:ui' as ui show Rect, Paint, Canvas, Size;

// this level base libraries or equivalent
//import '../../morphic/container/chart_support/chart_orientation.dart';
import 'package:flutter_charts/src/util/extensions_flutter.dart';

import '../../morphic/container/chart_support/chart_orientation.dart';
import '../../morphic/ui2d/point.dart';
import '../../util/util_labels.dart';
import 'axis_container.dart';
import 'container_common.dart' as container_common;
import '../../morphic/container/container_layouter_base.dart';
import '../model/data_model.dart' as model;
import '../view_maker.dart';
import '../../morphic/container/container_edge_padding.dart';
import '../../morphic/container/layouter_one_dimensional.dart';
import '../options.dart';
import '../../morphic/container/container_key.dart';
//import 'line_segment_container.dart';

class DataContainer extends container_common.ChartAreaContainer {

  DataContainer({
    required ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker,
  );

  // todo-013 : why do we construct in buildAndReplaceChildren here in DataContainer, while construct in constructor in NewVerticalAxisContainer???
  @override
  void buildAndReplaceChildren() {
    var padGroup = ChartPaddingGroup(fromChartOptions: chartViewMaker.chartOptions);

    // Generate list of containers, each container represents one bar (chartViewMaker defines if horizontal or vertical)
    // This is the entry point where this container's [chartViewMaker] starts to generate this container (view).
    addChildren([
      // Pad DataContainer on top and bottom from options. Children are height and width sizers
      Padder(
        edgePadding: EdgePadding.withSides(
          top: padGroup.heightPadTopOfYAndData(),
          bottom: padGroup.heightPadBottomOfYAndData(),
        ),
        child: HeightSizerLayouter(
          children: [
            WidthSizerLayouter(
              children: [
                // RowOrColumn's first item shows positive Bars, second item negative Bars, X axis line between them
                _buildLevel1PosAndNegBarsAreasContainerAsTransposingColumn (
                  children: [
                    // Row with columns of positive values
                    _buildLevel2PosOrNegBarsContainerAsTransposingRow(
                      barsAreaSign: model.Sign.positiveOr0,
                    ),
                    // X axis line. Could place in Row with main constraints weight=0.0
                    TransposingInputAxisLineContainer(
                      chartViewMaker:             chartViewMaker,
                      inputLabelsGenerator:       chartViewMaker.inputLabelsGenerator,
                      outputLabelsGenerator:      chartViewMaker.outputLabelsGenerator,
                    ),
                    // Row with columns of negative values
                    _buildLevel2PosOrNegBarsContainerAsTransposingRow(
                      barsAreaSign: model.Sign.negative,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

  RollingBoxLayouter _buildLevel1PosAndNegBarsAreasContainerAsTransposingColumn({
    required List<BoxContainer> children,
  }) {
    return TransposingRoller.Column(
      chartSeriesOrientation: chartViewMaker.chartSeriesOrientation,
      mainAxisAlign: Align.start, // default
      children: children,
    );
  }

  /// For column chart, ([ChartSeriesOrientation.column]), build row    of (column) bars
  /// For row    chart, ([ChartSeriesOrientation.row])     build column of (row)    bars
  ///
  /// Either are build for only positive or only negative values,
  /// depending on
  RollingBoxLayouter _buildLevel2PosOrNegBarsContainerAsTransposingRow({
    required model.Sign barsAreaSign,
  }) {

    double ratioOfPositiveOrNegativePortion;
    Align crossAxisAlign;
    List<model.CrossPointsModel> crossPointsModels;

    switch(barsAreaSign) {
      case model.Sign.positiveOr0:
        crossPointsModels = chartViewMaker.chartModel.crossPointsModelList;
        ratioOfPositiveOrNegativePortion = chartViewMaker.outputLabelsGenerator.dataRange.ratioOfPositivePortion();
        crossAxisAlign = Align.end; // cross align end for pos / start for neg push negative and positive together.
        break;
      case model.Sign.negative:
        crossPointsModels = chartViewMaker.chartModel.crossPointsModelList;
        ratioOfPositiveOrNegativePortion = chartViewMaker.outputLabelsGenerator.dataRange.ratioOfNegativePortion();
        crossAxisAlign = Align.start;
        break;
      case model.Sign.any:
        throw StateError('Should be called only with [barsAreaSign] positive or negative.');
    }
    // Row with a positive or negative bars, depending on [barsAreaSign].
    // The Row constraints are weighted by the ratio for positives and negatives passed here.
    return TransposingRoller.Row(
      chartSeriesOrientation: chartViewMaker.chartSeriesOrientation,
      mainAxisConstraintsWeight: ConstraintsWeight(
        weight: ratioOfPositiveOrNegativePortion,
      ),
      mainAxisAlign: Align.start, // default
      crossAxisAlign: crossAxisAlign,
      // Switches from DataContainer to ChartViewMaker, as it needs a model
      children: chartViewMaker.makeViewsForDataContainer_Bars(
        crossPointsModels: crossPointsModels,
        barsAreaSign: barsAreaSign,
      ),
    );
  }
}

class CrossPointsContainer extends container_common.ChartAreaContainer {

  CrossPointsContainer({
    required ChartViewMaker chartViewMaker,
    required this.crossPointsModel,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  /// Model backing this container.
  model.CrossPointsModel crossPointsModel;
}

abstract class PointContainer extends container_common.ChartAreaContainer {

  PointContainer({
    required this.pointModel,
    required ChartViewMaker chartViewMaker,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  /// The [PointModel] presented by this container.
  model.PointModel pointModel;
}

/// Container presents it's [pointModel] as a point on a line, or a rectangle in a bar chart.
///
/// See [LegendIndicatorRectContainer] for similar implementation.
///
/// It implements the mixins [WidthSizerLayouterChildMixin] and [HeightSizerLayouterChildMixin]
/// needed to lextr the [pointModel] to a position on the chart.
class BarPointContainer extends PointContainer with WidthSizerLayouterChildMixin, HeightSizerLayouterChildMixin {

  BarPointContainer({
    required model.PointModel pointModel,
    required ChartViewMaker chartViewMaker,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    pointModel: pointModel,
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  /// Full [layout] implementation calculates and set the final [_rectangleSize],
  /// the width and height of the Rectangle that represents data as pixels.
  @override
  void layout() {
    buildAndReplaceChildren();

    DataRangeLabelInfosGenerator inputLabelsGenerator = chartViewMaker.inputLabelsGenerator;
    DataRangeLabelInfosGenerator outputLabelsGenerator = chartViewMaker.outputLabelsGenerator;

    // Create PointOffset from this [pointModel] by giving it a range,
    // positions the [pointModel] on the x axis on it's label x coordinate.
    // The [pointOffset] can be lextr-ed to it's target value depending on chart direction.
    PointOffset pointOffset = pointModel.asPointOffsetOnInputRange(
          dataRangeLabelInfosGenerator: inputLabelsGenerator,
        );
    PointOffset pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartSeriesOrientation: chartViewMaker.chartSeriesOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: inputLabelsGenerator.dataRange,
      outputDataRange: outputLabelsGenerator.dataRange,
      heightToLextr: heightToLextr,
      widthToLextr: widthToLextr,
      isLextrUseSizerInsteadOfConstraint: false,
    );

    // In the bar container, we only need the [pixelPointOffset.barPointRectSize]
    // which is the [layoutSize] of the rectangle presenting the point.
    // The offset, [pixelPointOffset] is used in line chart.
    //
    // The [layoutSize] is also the size of the rectangle, which, when positioned
    // by the parent layouter, is the pixel-lextr-ed value of the [pointModel]
    // in the main axis direction of the layouter which owns this [BarPointContainer].
    layoutSize = pixelPointOffset.barPointRectSize;
  }

  @override paint(ui.Canvas canvas) {

    ui.Rect rect = offset & layoutSize;

    // Rectangle color should be from pointModel's color.
    ui.Paint paint = ui.Paint();
    paint.color = pointModel.color;

    canvas.drawRect(rect, paint);
  }
}

/// A dummy [BarPointContainer] with zero [layoutSize] in the direction of the main axis.,
class ZeroValueBarPointContainer extends BarPointContainer {

  ZeroValueBarPointContainer({
    required model.PointModel pointModel,
    required ChartViewMaker chartViewMaker,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    pointModel: pointModel,
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  /// Layout this container by calling super, then set the [layoutSize] in the value direction
  /// (owner layouter mainAxisDirection) to be zero.
  ///
  /// This container is a stand-in for Non-Stacked value point, on the positive or negative side against
  /// where the actual value bar is shown.
  // todo-010-next : The algorithm is copied from super, just adding the piece of logic setting layoutSize 0.0 in the value direction.
  //                 This is bad for both performance and principle. Find a faster, clearer way - basically we need the logic from super to calculate layoutSize in the cross-value direction,
  //                 maybe not even that.
  @override
  void layout() {
    buildAndReplaceChildren();

    DataRangeLabelInfosGenerator inputLabelsGenerator = chartViewMaker.inputLabelsGenerator;
    DataRangeLabelInfosGenerator outputLabelsGenerator = chartViewMaker.outputLabelsGenerator;

    // Create PointOffset from this [pointModel] by giving it a range,
    // positions the [pointModel] on the x axis on it's label x coordinate.
    // The [pointOffset] can be lextr-ed to it's target value depending on chart direction.
    PointOffset pointOffset = pointModel.asPointOffsetOnInputRange(
      dataRangeLabelInfosGenerator: inputLabelsGenerator,
    );
    PointOffset pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartSeriesOrientation: chartViewMaker.chartSeriesOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: inputLabelsGenerator.dataRange,
      outputDataRange: outputLabelsGenerator.dataRange,
      heightToLextr: heightToLextr,
      widthToLextr: widthToLextr,
      isLextrUseSizerInsteadOfConstraint: false,
    );

    // Make the layoutSize zero in the direction of the chart orientation
    layoutSize = pixelPointOffset.barPointRectSize.fromMySideAlongPassedAxisOtherSideAlongCrossAxis(
      axis: chartViewMaker.chartSeriesOrientation.inputDataAxisOrientation,
      other: const ui.Size(0.0, 0.0),
    );
  }

  @override
  paint(ui.Canvas canvas) {
    return;
  }
}
