/// Library for concrete [BarChartDataContainer] extension of [DataContainer] and it's inner classes.
///
/// Each class here extends it's abstract base in ../data_container.dart,
/// and implements methods named 'makeInner', which allow all internals
/// of the [DataContainer] to be overridden and extended.
import 'dart:ui' as ui show Rect, Paint, Canvas;

// this chart/chart_type/bar level

// up 1 level

// up 2 level chart
import 'package:flutter_charts/src/chart/container/data_container.dart'
    show DataContainer, BarsContainer, DataColumnPointsBar, PointContainer, ZeroValuePointContainer;
import 'package:flutter_charts/src/chart/model/data_model.dart' show DataColumnModel, PointModel;
import 'package:flutter_charts/src/chart/view_model.dart' show ChartViewModel;

// util
// import 'package:flutter_charts/src/util/extensions_flutter.dart' show SizeExtension;

// morphic
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart' show BoxContainer, ConstraintsWeight, Padder, TransposingRoller;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart' show ChartOrientation, ChartStacking;
import 'package:flutter_charts/src/morphic/container/morphic_dart_enums.dart' show Sign;
import 'package:flutter_charts/src/morphic/container/container_edge_padding.dart' show EdgePadding;
import 'package:flutter_charts/src/morphic/container/layouter_one_dimensional.dart';
import 'package:flutter_charts/src/morphic/container/container_key.dart' show ContainerKey;
import 'package:flutter_charts/src/morphic/ui2d/point.dart' show PointOffset;

/// Concrete [DataContainer] for bar chart.
class BarChartDataContainer extends DataContainer {
  BarChartDataContainer({
    required ChartViewModel chartViewModel,
  }) : super(
    chartViewModel: chartViewModel,
  );

  @override
  BarsContainer makeInnerBarsContainer ({
    required DataContainer outerDataContainer,
    required Sign barsAreaSign,
    required ConstraintsWeight constraintsWeight,
    ContainerKey? key,
  })  {
    return BarChartBarsContainer(
      chartViewModel: chartViewModel,
      outerDataContainer: outerDataContainer,
      barsAreaSign: barsAreaSign,
      constraintsWeight: constraintsWeight,
      key: key,
    );
  }
}

class BarChartBarsContainer extends BarsContainer {

  BarChartBarsContainer({
    required super.chartViewModel,
    required super.outerDataContainer,
    required super.barsAreaSign,
    required super.constraintsWeight,
    super.key,
  });

  @override
  DataColumnPointsBar makeInnerDataColumnPointsBar({
    required DataColumnModel dataColumnModel,
    required DataContainer outerDataContainer,
    required Sign barsAreaSign,
  }) {
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerDataColumnPointsBar(
        dataColumnModel: dataColumnModel,
        outerBarsContainer: this,
        barsAreaSign: barsAreaSign,
      );
    }
    return BarChartDataColumnPointsBar(
      chartViewModel: chartViewModel,
      outerDataContainer: outerDataContainer,
      barsAreaSign: barsAreaSign,
      dataColumnModel: dataColumnModel,
    );
  }
}

class BarChartDataColumnPointsBar extends DataColumnPointsBar {

  BarChartDataColumnPointsBar({
    required super.chartViewModel,
    required super.outerDataContainer,
    required super.barsAreaSign,
    required super.dataColumnModel,
    super.key,
  });

  /// Overrides by calling super, then wrapping each [PointContainer] in the super returned list into a [Padder].
  @override
  List<BoxContainer> makePointContainerListForSign() {

    List<BoxContainer> pointContainers = super.makePointContainerListForSign();

    // Pad around each [PointContainer] before placing it in TransposingRoller
    EdgePadding pointRectSidePad = EdgePadding.TransposingWithSides(
      chartOrientation: chartViewModel.chartOrientation,
      start: 1.0,
      end: 1.0,
    );

    List<Padder> paddedPointContainers = pointContainers
        .map((pointContainer) => Padder(
              edgePadding: pointRectSidePad,
              child: pointContainer,
            ))
        .toList();

    return paddedPointContainers;
  }

  /// Creates the layouter for passed [pointContainerList] of children.
  ///
  /// For [ChartViewModel.chartOrientation] = [ChartOrientation.column] a [Column] is built;
  /// for [ChartViewModel.chartOrientation] = [ChartOrientation.row]    a [Row] is built.
  ///
  /// See super [DataContainer.makePointContainersLayouter] for details.
  @override
  BoxContainer makePointContainersLayouter({
    required List<BoxContainer> pointContainerList,
  }) {
    BoxContainer pointContainersLayouter;
    switch (chartViewModel.chartStacking) {
      case ChartStacking.stacked:
        pointContainersLayouter = TransposingRoller.Column(
          chartOrientation: chartViewModel.chartOrientation,
          mainAxisAlign: Align.start, // default
          crossAxisAlign: Align.center, // default
          // For stacked, do NOT put weights, as in main direction, each bar has no limit.
          constraintsDivideMethod: ConstraintsDivideMethod.noDivision, // default
          isMainAxisAlignFlippedOnTranspose: false, // do not flip to Align.end, as children have no weight=no divide
          children: barsAreaSign == Sign.positiveOr0 ? pointContainerList.reversed.toList() : pointContainerList,
        );
        break;
      case ChartStacking.nonStacked:
        pointContainersLayouter = TransposingRoller.Row(
          chartOrientation: chartViewModel.chartOrientation,
          mainAxisAlign: Align.start, // default
          // column:  sit positive bars at end,   negative bars at start
          // row:     sit positive bars at start, negative bars at end (Transposing will take care of this row flip)
          crossAxisAlign: barsAreaSign == Sign.positiveOr0 ? Align.end : Align.start,
          // For nonStacked leaf rects are in Transposing Row along main axis,
          // this row must divide width to all leaf rects evenly
          constraintsDivideMethod: ConstraintsDivideMethod.evenDivision,
          isMainAxisAlignFlippedOnTranspose: true, // default
          children: pointContainerList,
        );
        break;
    }
    return pointContainersLayouter;
  }

  @override
  PointContainer makePointContainer({
    required PointModel pointModel,
  }) {
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerPointContainer(
        pointModel: pointModel,
      );
    }
    return BarPointContainer(
      pointModel: pointModel,
      chartViewModel: chartViewModel,
      outerDataColumnPointsBar: this,
    );
  }

  @override
  PointContainer makePointContainerWithZeroValue({
    required PointModel pointModel,
  }) {
    // return BarPointContainer with 0 layoutSize in the value orientation
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerPointContainerWithZeroValue(
        pointModel: pointModel,
      );
    }
    return ZeroValuePointContainer(
      pointModel: pointModel,
      chartViewModel: chartViewModel,
      outerDataColumnPointsBar: this,
    );
  }

}

/// Container presents it's [pointModel] as a point on a line, or a rectangle in a bar chart.
///
/// See [LegendIndicatorRectContainer] for similar implementation.
///
/// It implements the mixins [WidthSizerLayouterChildMixin] and [HeightSizerLayouterChildMixin]
/// needed to affmap the [pointModel] to a position on the chart.
class BarPointContainer extends PointContainer {

  /// Generate view for this single leaf [PointModel] - a single [BarPointContainer].
  ///
  /// Note: On the leaf, we return single element by agreement, higher ups return lists.
  BarPointContainer({
    required super.pointModel,
    required super.chartViewModel,
    required super.outerDataColumnPointsBar,
    super.children,
    super.key,
  }) ;

  /// Full [layout] implementation calculates and sets [PointOffset.barPointRectSize] for this instance,
  /// which is the pixel width and height of the Rectangle bar that represents the data point.
  @override
  void layout() {
    buildAndReplaceChildren();

    PointOffset pixelPointOffset = layoutUsingPointModelAffmapToPixels();
    // KEEP generateTestCode(pointOffset, inputLabelsGenerator, outputLabelsGenerator, pixelPointOffset);

    // In the bar container, we only need the [pixelPointOffset.barPointRectSize]
    // which is the [layoutSize] of the rectangle presenting the point.
    // The offset, [pixelPointOffset] is used in line chart.
    //
    // The [layoutSize] is also the size of the rectangle, which, when positioned
    // by the parent container/layouter, is the pixel-affmap-ed value of the [pointModel]
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
