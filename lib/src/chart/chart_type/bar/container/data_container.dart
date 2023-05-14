/// Library for concrete [BarChartDataContainer] extension of [DataContainer] and it's inner classes.
///
/// Each class here extends it's abstract base in ../data_container.dart,
/// and implements methods named 'makeInner', which allow all internals
/// of the [DataContainer] to be overridden and extended.
import 'dart:ui' as ui show Rect, Paint, Canvas, Size;

// this chart/chart_type/bar level

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
import 'package:flutter_charts/src/morphic/ui2d/point.dart' show PointOffset;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart' show ChartOrientation;
import 'package:flutter_charts/src/morphic/container/morphic_dart_enums.dart' show Sign;

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
    ContainerKey? key,
  })  {
    return BarChartBarsContainer(
      chartViewModel: chartViewModel,
      outerDataContainer: outerDataContainer,
      barsAreaSign: barsAreaSign,
      key: key,
    );
  }
}

class BarChartBarsContainer extends BarsContainer {

  BarChartBarsContainer({
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
    return ZeroValueBarPointContainer(
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

    PointOffset pixelPointOffset = affmapLayoutToConstraintsAsPointOffset();
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

/// A zero-height (thus 'invisible') [BarPointContainer] extension.
///
/// Has zero [layoutSize] in the direction of the input data axis. See [layout] for details.
class ZeroValueBarPointContainer extends BarPointContainer {

  ZeroValueBarPointContainer({
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
/* todo-00-done
    DataRangeLabelInfosGenerator inputLabelsGenerator = chartViewModel.inputLabelsGenerator;
    DataRangeLabelInfosGenerator outputLabelsGenerator = chartViewModel.outputLabelsGenerator;

    // Create PointOffset from this [pointModel] by giving it a range,
    // positions the [pointModel] on the x axis on it's label x coordinate.
    // The [pointOffset] can be affmap-ed to it's target value depending on chart direction.
    PointOffset pointOffset = pointModel.toPointOffsetOnInputRange(
      dataRangeLabelInfosGenerator: inputLabelsGenerator,
    );
    PointOffset pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
      chartOrientation: chartViewModel.chartOrientation,
      withinConstraints: constraints,
      inputDataRange: inputLabelsGenerator.dataRange,
      outputDataRange: outputLabelsGenerator.dataRange,
      sizerHeight: sizerHeight,
      sizerWidth: sizerWidth,
      isFromChartPointForAsserts: false,
    );
*/

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
