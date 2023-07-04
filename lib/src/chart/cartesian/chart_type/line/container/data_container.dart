/// Library for concrete [LineChartDataContainer] extension of [DataContainer] and it's inner classes.
///
/// Each class here extends it's abstract base in ../data_container.dart,
/// and implements methods named 'makeInner', which allow all internals
/// of the [DataContainer] to be overridden and extended.
import 'dart:ui' as ui show Paint, Canvas, Offset;

// up 2 level chart
import 'package:flutter_charts/src/chart/cartesian/container/data_container.dart'
    show DataContainer, BarsContainer, PointContainersBar, BasePointContainer, PointContainer, FillerPointContainer;
import 'package:flutter_charts/src/chart/view_model/view_model.dart' show ChartViewModel, PointsBarModel, BasePointModel, FillerPointModel;
import 'package:flutter_charts/src/chart/options.dart' show ChartOptions;

// morphic
import 'package:flutter_charts/src/morphic/container/container_key.dart' show ContainerKey;
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart' show BoxContainer, ConstraintsWeight;
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart' show TransposingStackLayouter;
import 'package:flutter_charts/src/morphic/ui2d/point.dart' show PointOffset;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart' show ChartOrientation, ChartStacking;
import 'package:flutter_charts/src/morphic/container/morphic_dart_enums.dart' show Sign;

/// Concrete [DataContainer] for bar chart.
class LineChartDataContainer extends DataContainer {
  LineChartDataContainer({
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
    return LineChartBarsContainer(
      chartViewModel: chartViewModel,
      outerDataContainer: outerDataContainer,
      barsAreaSign: barsAreaSign,
      constraintsWeight: constraintsWeight,
      key: key,
    );
  }
}

class LineChartBarsContainer extends BarsContainer {

  LineChartBarsContainer({
    required super.chartViewModel,
    required super.outerDataContainer,
    required super.barsAreaSign,
    required super.constraintsWeight,
    super.key,
  });

  @override
  PointContainersBar makeInnerPointContainersBar({
    required PointsBarModel pointsBarModel,
    required DataContainer outerDataContainer,
    required Sign barsAreaSign,
  }) {
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerPointContainersBar(
        pointsBarModel: pointsBarModel,
        outerBarsContainer: this,
        barsAreaSign: barsAreaSign,
      );
    }
    return LineChartPointContainersBar(
      chartViewModel: chartViewModel,
      outerDataContainer: outerDataContainer,
      barsAreaSign: barsAreaSign,
      pointsBarModel: pointsBarModel,
    );
  }
}

class LineChartPointContainersBar extends PointContainersBar {

  LineChartPointContainersBar({
    required super.chartViewModel,
    required super.outerDataContainer,
    required super.barsAreaSign,
    required super.pointsBarModel,
    super.key,
  });

  /// Creates the layouter for passed [pointContainerList] of children.
  ///
  /// Result does not depend on [ChartOrientation], does depend on [ChartStacking]:
  ///
  /// For [ChartViewModel.chartStacking] = [ChartStacking.column] a [TransposingStackLayouter.Column] is built;
  /// for [ChartViewModel.chartStacking] = [ChartStacking.row]    a [TransposingStackLayouter.Row] is built.
  ///
  /// Note: Currently, [TransposingStackLayouter.Column] and [TransposingStackLayouter.Row] are the same.
  ///
  /// See super [DataContainer.makePointContainersLayouter] for details.
  @override
  BoxContainer makePointContainersLayouter({
    required List<BoxContainer> pointContainerList,
  }) {
    TransposingStackLayouter pointContainersLayouter;
    switch (chartViewModel.chartStacking) {
      case ChartStacking.stacked:
        pointContainersLayouter = TransposingStackLayouter.Column(
          children: barsAreaSign == Sign.positiveOr0 ? pointContainerList.reversed.toList() : pointContainerList,
        );
        break;
      case ChartStacking.nonStacked:
        pointContainersLayouter = TransposingStackLayouter.Row(
          children: pointContainerList,
        );
        break;
    }

    return pointContainersLayouter;
  }

  @override
  PointContainer makePointContainer({
    required BasePointModel pointModel,
  }) {
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerPointContainer(
        pointModel: pointModel,
      );
    }
    return LineAndPointContainer(
      pointModel: pointModel,
      chartViewModel: chartViewModel,
      outerPointContainersBar: this,
    );
  }

  @override
  BasePointContainer makePointContainerWithFiller() {
    // return LineAndPointContainer with 0 layoutSize in the value orientation
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerPointContainerWithFiller(
      );
    }
    return FillerPointContainer(
      pointModel: FillerPointModel(),
      chartViewModel: chartViewModel,
    );
  }

}

/// Container presents it's [pointModel] as a point on a line, or a rectangle in a bar chart.
///
/// See [LegendIndicatorRectContainer] for similar implementation.
///
/// It implements the mixins [WidthSizerLayouterChildMixin] and [HeightSizerLayouterChildMixin]
/// needed to affmap the [pointModel] to a position on the chart.
class LineAndPointContainer extends PointContainer {

  /// Generate view for this single leaf [PointModel] - a single [LineAndPointContainer].
  ///
  /// Note: On the leaf, we return single element by agreement, higher ups return lists.
  LineAndPointContainer({
    required super.pointModel,
    required super.chartViewModel,
    required super.outerPointContainersBar,
    super.children,
    super.key,
  });

  /// Full [layout] implementation calculates and sets the pixel point [_pixelPointOffset]
  /// that represents the line point data.
  ///
  /// This implementation is somewhat tied to the rudimentary implementation of [TransposingStackLayouter]
  /// the intended layouter of [LineAndPointContainer]s, in the following:
  ///   1. It is assumed that the [TransposingStackLayouter] obtains full constraints of it's parent layouter,
  ///     the [PointContainersBar].
  ///   2. It is assumed that all sibling children ([LineAndPointContainer]s) of the [TransposingStackLayouter]
  ///     also obtain the same full constraints. In other words, it is assumed that
  ///       - [PointContainersBar]
  ///       - it's child [TransposingStackLayouter]
  ///       - all it's children, the [LineAndPointContainer]s
  ///     all get same constraints.
  ///   3. As a result of 2. all [LineAndPointContainer]s above one label (in the [PointContainersBar])
  ///      can [layout] and [paint] it's points and connecting lines
  ///      into the same [constraints] area (which is like the canvas into which one vertical stack of data is painted).
  @override
  void layout() {
    buildAndReplaceChildren();

    PointOffset pixelPointOffset = layoutUsingPointModelAffmapToPixels();

    // KEEP generateTestCode(pointOffset, inputRangeDescriptor, outputRangeDescriptor, pixelPointOffset);

    // Store pixelPointOffset as member for paint to use as added offset
    this.pixelPointOffset = pixelPointOffset;

    // Must set layoutSize same as passed constraints, for the rudimentary [StackLayouter] to layout and paint
    //   this child correctly - the rudimentary [StackLayouter] relies on all children to paint into its not-offset
    //   rectangle that has size = constraints size.
    // Note: For [BarPointContainer]: layoutSize = pixelPointOffset.barPointRectSize;
    layoutSize = constraints.size;
  }

  @override
  paint(ui.Canvas canvas) {
    /* KEEP print info about what is painted
    print(' ### Log.Info: $runtimeType.circlePaint: color=${circlePaint.color}, _pixelPointOffset = $_pixelPointOffset, '
        '_pixelPointOffset.barPointRectSize=${_pixelPointOffset.barPointRectSize}, '
        'layoutSize=$layoutSize, accumulated offset=$offset');
    */

    ChartOptions options = chartViewModel.chartOptions;
    ui.Paint circlePaint = ui.Paint();
    circlePaint.color = pointModel.color;

    // Note: For [BarPointContainer], we circlePaint: ui.Rect rect = offset & layoutSize;
    // Note: For non-zero-crossing, in chartOrientation direction: pixelPointOffset +  pixelPointOffset.barPointRectSize == constraints.size == layoutSize,
    //       See [PointOffset._validateAffmapToPixelMethodInputsOutputs]

    ui.Offset thisPointOffset = offset + pixelPointOffset;

    canvas.drawCircle(
      thisPointOffset,
      options.lineChartOptions.hotspotOuterRadius,
      circlePaint,
    );

    // If there is next point in the same row of data, also circlePaint the line connecting this point with next
    if (pointModel.hasNextPointModel) {
      var nextPointModel = pointModel.nextPointModel;
      var nextPointOffsetInItsPointContainer = nextPointModel.pointContainer!.pixelPointOffset;
      var nextPointOffsetInParent = nextPointModel.pointContainer!.offset;
      var nextPointOffset = nextPointOffsetInParent + nextPointOffsetInItsPointContainer;

      ui.Paint linePaint = ui.Paint();
      linePaint
        ..color = circlePaint.color
        ..strokeWidth = options.lineChartOptions.lineStrokeWidth;
      canvas.drawLine(thisPointOffset, nextPointOffset, linePaint);
      // ui.Offset nextPointOffset =
    }
  }
}
