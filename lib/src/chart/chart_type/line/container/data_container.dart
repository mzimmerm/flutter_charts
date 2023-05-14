/// Library for concrete [LineChartDataContainer] extension of [DataContainer] and it's inner classes.
///
/// Each class here extends it's abstract base in ../data_container.dart,
/// and implements methods named 'makeInner', which allow all internals
/// of the [DataContainer] to be overridden and extended.
import 'dart:ui' as ui show Paint, Canvas, Size, Offset;

// this chart/chart_type/line level

// up 1 level

// up 2 level chart
import 'package:flutter_charts/src/chart/container/data_container.dart' show DataContainer, BarsContainer, DataColumnPointsBar, PointContainer;
import 'package:flutter_charts/src/chart/model/data_model.dart' show DataColumnModel, PointModel;
import 'package:flutter_charts/src/chart/view_model.dart' show ChartViewModel;
// import 'package:flutter_charts/src/chart/model/label_model.dart' show DataRangeLabelInfosGenerator;

// util
import 'package:flutter_charts/src/util/extensions_flutter.dart' show SizeExtension;

// morphic
import 'package:flutter_charts/src/morphic/container/container_key.dart' show ContainerKey;
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
    ContainerKey? key,
  })  {
    return LineChartBarsContainer(
      chartViewModel: chartViewModel,
      outerDataContainer: outerDataContainer,
      barsAreaSign: barsAreaSign,
      key: key,
    );
  }
}

class LineChartBarsContainer extends BarsContainer {

  LineChartBarsContainer({
    required super.chartViewModel,
    required super.outerDataContainer,
    required super.barsAreaSign,
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
    return LineChartDataColumnPointsBar(
      chartViewModel: chartViewModel,
      outerDataContainer: outerDataContainer,
      barsAreaSign: barsAreaSign,
      dataColumnModel: dataColumnModel,
    );
  }
}

class LineChartDataColumnPointsBar extends DataColumnPointsBar {

  LineChartDataColumnPointsBar({
    required super.chartViewModel,
    required super.outerDataContainer,
    required super.barsAreaSign,
    required super.dataColumnModel,
    super.key,
  }) ;

  // todo-00-progress vvvvvvvvv
  @override
  void buildAndReplaceChildren() {
    // Creates a list of [PointContainer]s from all points of the passed [dataColumnModel], pads each [PointContainer].
    // The code in [clsPointToNullableContainerForSign] contains logic that processes all combinations of
    // stacked and nonStacked, and positive and negative, distinctly.
    List<PointContainer> pointContainers = dataColumnModel.pointModelList
        // Map applies function converting the [PointModel] to [PointContainer],
        // calling the hook [MyBarChartViewModelPointContainer]
        .map(clsPointToNullableContainerForSign(barsAreaSign))
        // Filters in only non null containers (impl detail of clsPointToNullableContainerForSign)
        .where((containerElm) => containerElm != null)
        .map((containerElm) => containerElm!)
        .toList();

    TransposingStackLayouter pointContainersLayouter;
    switch (chartViewModel.chartStacking) {
      case ChartStacking.stacked:
        pointContainersLayouter = TransposingStackLayouter.Column(
          children: barsAreaSign == Sign.positiveOr0 ? pointContainers.reversed.toList() : pointContainers,
        );
        break;
      case ChartStacking.nonStacked:
        pointContainersLayouter = TransposingStackLayouter.Row(
          children: pointContainers,
        );
        break;
    }
    // KEEP: Note : if children are passed to super, we need instead: replaceChildrenWith([pointContainersLayouter])
    addChildren([pointContainersLayouter]);
  }
  // todo-00-progress ^^^^^^^^





  @override
  PointContainer makePointContainer({
    required PointModel pointModel,
  }) {
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerPointContainer(
        pointModel: pointModel,
      );
    }
    return LineAndPointContainer(
      pointModel: pointModel,
      chartViewModel: chartViewModel,
      outerDataColumnPointsBar: this,
    );
  }

  @override
  PointContainer makePointContainerWithZeroValue({
    required PointModel pointModel,
  }) {
    // return LineAndPointContainer with 0 layoutSize in the value orientation
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerPointContainerWithZeroValue(
        pointModel: pointModel,
      );
    }
    return ZeroValueLineAndPointContainer(
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
class LineAndPointContainer extends PointContainer {

  /// Generate view for this single leaf [PointModel] - a single [LineAndPointContainer].
  ///
  /// Note: On the leaf, we return single element by agreement, higher ups return lists.
  LineAndPointContainer({
    required super.pointModel,
    required super.chartViewModel,
    required super.outerDataColumnPointsBar,
    super.children,
    super.key,
  });

  /// Stores offset calculated by during [layout] for use in [paint].
  late final PointOffset _pixelPointOffset;

  /// Full [layout] implementation calculates and sets the pixel point [_pixelPointOffset]
  /// that represents the line point data.
  ///
  /// This implementation is somewhat tied to the rudimentary implementation of [TransposingStackLayouter]
  /// the intended layouter of [LineAndPointContainer]s, in the following:
  ///   1. It is assumed that the [TransposingStackLayouter] obtains full constraints of it's parent layouter,
  ///     the [DataColumnPointsBar].
  ///   2. It is assumed that all sibling children ([LineAndPointContainer]s) of the [TransposingStackLayouter]
  ///     also obtain the same full constraints. In other words, it is assumed that
  ///       - [DataColumnPointsBar]
  ///       - it's child [TransposingStackLayouter]
  ///       - all it's children, the [LineAndPointContainer]s
  ///     all get same constraints.
  ///   3. As a result of 2. all [LineAndPointContainer]s above one label (in the [DataColumnPointsBar])
  ///      can [layout] and [paint] it's points and connecting lines
  ///      into the same [constraints] area (which is like the canvas into which one vertical stack of data is painted).
  @override
  void layout() {
    buildAndReplaceChildren();

    PointOffset pixelPointOffset = affmapLayoutToConstraintsAsPointOffset();

    // KEEP generateTestCode(pointOffset, inputLabelsGenerator, outputLabelsGenerator, pixelPointOffset);

    // Store pixelPointOffset as member for paint to use as added offset
    _pixelPointOffset = pixelPointOffset;

    // Must set layoutSize same as passed constraints, for the rudimentary [StackLayouter] to layout and paint
    //   this child correctly - the rudimentary [StackLayouter] relies on all children to paint into its not-offset
    //   rectangle that has size = constraints size.
    // Note: For [BarPointContainer]: layoutSize = pixelPointOffset.barPointRectSize;
    layoutSize = constraints.size;
  }

  @override paint(ui.Canvas canvas) {

    /* KEEP print info about what is painted
    print(' ### Log.Info: $runtimeType.paint: color=${paint.color}, _pixelPointOffset = $_pixelPointOffset, '
        '_pixelPointOffset.barPointRectSize=${_pixelPointOffset.barPointRectSize}, '
        'layoutSize=$layoutSize, accumulated offset=$offset');
    */

    ui.Paint paint = ui.Paint();
    paint.color = pointModel.color;

    // Note: For [BarPointContainer], we paint: ui.Rect rect = offset & layoutSize;
    // Note: For non-zero-crossing, in chartOrientation direction: pixelPointOffset +  pixelPointOffset.barPointRectSize == constraints.size == layoutSize,
    //       See [PointOffset._validateAffmapToPixelMethodInputsOutputs]

    ui.Offset circleAtOffset = offset + _pixelPointOffset;
    canvas.drawCircle(
      circleAtOffset,
      chartViewModel.chartOptions.lineChartOptions.hotspotOuterRadius,
      paint,
    );
  }

}

/// A zero-height (thus 'invisible') [LineAndPointContainer] extension.
///
/// Has a zero [layoutSize] in the direction of the input data axis. See [layout] for details.
class ZeroValueLineAndPointContainer extends LineAndPointContainer {

  ZeroValueLineAndPointContainer({
    required super.pointModel,
    required super.chartViewModel,
    required super.outerDataColumnPointsBar,
    super.children,
    super.key,
  });

  /// Layout this container by calling super, then set the [layoutSize] in the value direction
  /// (parent container/layouter mainAxisDirection) to be zero.
  ///
  /// To be precise, the value direction is defined as input data axis, [ChartOrientation.inputDataAxisOrientation].
  ///
  /// This container is a stand-in for Not-Stacked value point, on the positive or negative side against
  /// where the actual value bar is shown.
  // todo-014-functional : The algorithm is copied from super, just adding the piece of logic setting layoutSize 0.0 in the value direction.
  //                 This is bad for both performance and principle. Find a faster, clearer way - basically we need the logic from super to calculate layoutSize in the cross-value direction,
  //                 maybe not even that.
  @override
  void layout() {
    buildAndReplaceChildren();

    PointOffset pixelPointOffset = affmapLayoutToConstraintsAsPointOffset();

    // Make the layoutSize zero in the direction of the chart orientation
    layoutSize = pixelPointOffset.barPointRectSize.fromMySideAlongPassedAxisOtherSideAlongCrossAxis(
      axis: chartViewModel.chartOrientation.inputDataAxisOrientation,
      other: const ui.Size(0.0, 0.0),
    );
  }

  @override
  paint(ui.Canvas canvas) {
    return;
  }
}
