import 'dart:ui' as ui show Rect, Paint, Canvas, Size;

// chart/container common
import '../../../container/data_container.dart';

// this level base libraries or equivalent
// import 'package:flutter_charts/src/chart/painter.dart';
import 'package:flutter_charts/src/util/extensions_flutter.dart';

import '../../../../morphic/container/chart_support/chart_style.dart';
import '../../../../morphic/container/morphic_dart_enums.dart' show Sign;
import '../../../../morphic/ui2d/point.dart';
import '../../../model/label_model.dart';
// import '../axis_container.dart';
// import '../container_common.dart' as container_common;
import '../../../../morphic/container/container_layouter_base.dart';
import '../../../model/data_model.dart' as model;
import '../../../view_model.dart';
// import '../../../morphic/container/container_edge_padding.dart';
// import '../../../morphic/container/layouter_one_dimensional.dart';
// import '../../options.dart';
import '../../../../morphic/container/container_key.dart';

/// Concrete
class BarChartDataContainer extends DataContainer {
  BarChartDataContainer({
    required ChartViewModel chartViewModel,
  }) : super(
    chartViewModel: chartViewModel,
  );

  @override
  BarsContainer makeInnerBarsContainer ({
    required DataContainer ownerDataContainer,
    required Sign barsAreaSign,
    ContainerKey? key,
  })  {
    return BarChartBarsContainer(
      chartViewModel: chartViewModel,
      ownerDataContainer: ownerDataContainer,
      barsAreaSign: barsAreaSign,
      key: key,
    );
  }
}

class BarChartBarsContainer extends BarsContainer {

  BarChartBarsContainer({
    required ChartViewModel chartViewModel,
    required DataContainer ownerDataContainer,
    required Sign barsAreaSign,
    ContainerKey? key,
  }) : super(
    chartViewModel: chartViewModel,
    ownerDataContainer: ownerDataContainer,
    barsAreaSign: barsAreaSign,
    key: key,
  );

  @override
  DataColumnPointsBar makeInnerDataColumnPointsBar({
    required model.DataColumnModel dataColumnModel,
    required DataContainer ownerDataContainer,
    required Sign barsAreaSign,
  }) {
    if (ownerDataContainer.isMakeComponentsForwardedToOwner) {
      return ownerDataContainer.makeDeepInnerDataColumnPointsBar(
        dataColumnModel: dataColumnModel,
        // todo-00-done : ownerDataContainer: ownerDataContainer,
        ownerBarsContainer: this,
        barsAreaSign: barsAreaSign,
      );
    }
    return BarChartDataColumnPointsBar(
      chartViewModel: chartViewModel,
      ownerDataContainer: ownerDataContainer,
      barsAreaSign: barsAreaSign,
      dataColumnModel: dataColumnModel,
    );
  }
}

////////////////// vvvvvvvv
class BarChartDataColumnPointsBar extends DataColumnPointsBar {

  BarChartDataColumnPointsBar({
    required ChartViewModel chartViewModel,
    required DataContainer ownerDataContainer,
    required Sign barsAreaSign,
    required model.DataColumnModel dataColumnModel,
    ContainerKey? key,
  }) : super(
     chartViewModel: chartViewModel,
     ownerDataContainer: ownerDataContainer,
     barsAreaSign: barsAreaSign,
     dataColumnModel: dataColumnModel,
     key: key,
  );

  @override
  PointContainer makePointContainer({
    required model.PointModel pointModel,
  }) {
    if (ownerDataContainer.isMakeComponentsForwardedToOwner) {
      return ownerDataContainer.makeDeepInnerPointContainer(
        pointModel: pointModel,
      );
    }
    return BarPointContainer(
      pointModel: pointModel,
      chartViewModel: chartViewModel,
      ownerDataColumnPointsBar: this, // todo-00-done : added
    );
  }

  @override
  PointContainer makePointContainerWithZeroValue({
    required model.PointModel pointModel,
  }) {
    // return BarPointContainer with 0 layoutSize in the value orientation
    if (ownerDataContainer.isMakeComponentsForwardedToOwner) {
      return ownerDataContainer.makeDeepInnerPointContainerWithZeroValue(
        pointModel: pointModel,
      );
    }
    return ZeroValueBarPointContainer(
      pointModel: pointModel,
      chartViewModel: chartViewModel,
      ownerDataColumnPointsBar: this, // todo-00-done : added
    );
  }

}

////////////////// ^^^^


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
    required model.PointModel pointModel,
    required ChartViewModel chartViewModel,
    required DataColumnPointsBar ownerDataColumnPointsBar, // todo-00-done added
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    pointModel: pointModel,
    chartViewModel: chartViewModel,
    ownerDataColumnPointsBar: ownerDataColumnPointsBar, // todo-00-done added
    children: children,
    key: key,
  );

  /// Full [layout] implementation calculates and sets the pixel width and height of the Rectangle
  /// that represents data.
  @override
  void layout() {
    buildAndReplaceChildren();

    DataRangeLabelInfosGenerator inputLabelsGenerator = chartViewModel.inputLabelsGenerator;
    DataRangeLabelInfosGenerator outputLabelsGenerator = chartViewModel.outputLabelsGenerator;

    // Create PointOffset from this [pointModel] by giving it a range,
    // positions the [pointModel] on the x axis on it's label x coordinate.
    // The [pointOffset] can be affmap-ed to it's target value depending on chart direction.
    PointOffset pointOffset = pointModel.asPointOffsetOnInputRange(
      dataRangeLabelInfosGenerator: inputLabelsGenerator,
    );
    PointOffset pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
      chartOrientation: chartViewModel.chartOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: inputLabelsGenerator.dataRange,
      outputDataRange: outputLabelsGenerator.dataRange,
      sizerHeight: sizerHeight,
      sizerWidth: sizerWidth,
    );
    // KEEP generateTestCode(pointOffset, inputLabelsGenerator, outputLabelsGenerator, pixelPointOffset);

    // In the bar container, we only need the [pixelPointOffset.barPointRectSize]
    // which is the [layoutSize] of the rectangle presenting the point.
    // The offset, [pixelPointOffset] is used in line chart.
    //
    // The [layoutSize] is also the size of the rectangle, which, when positioned
    // by the parent layouter, is the pixel-affmap-ed value of the [pointModel]
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

  /// Generates code for testing.
  void generateTestCode(
      PointOffset pointOffset,
      DataRangeLabelInfosGenerator inputLabelsGenerator,
      DataRangeLabelInfosGenerator outputLabelsGenerator,
      PointOffset pixelPointOffset,
      ) {
    var pointOffsetStr = '   pointOffset = ${pointOffset.asCodeConstructor()};\n';
    var callStr = '   pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(\n'
        '       chartOrientation: ChartOrientation.${chartViewModel.chartOrientation.name},\n'
        '       constraintsOnImmediateOwner: ${constraints.asCodeConstructorInsideBox()},\n'
        '       inputDataRange: ${inputLabelsGenerator.dataRange.asCodeConstructor()},\n'
        '       outputDataRange: ${outputLabelsGenerator.dataRange.asCodeConstructor()},\n'
        '       sizerHeight: $sizerHeight,\n'
        '       sizerWidth: $sizerWidth,\n'
        '       //  isAffmapUseSizerInsteadOfConstraint: false,\n'
        '     );\n';
    // var pixelPointOffsetStr = '   pixelPointOffset = ${pixelPointOffset.asCodeConstructor()};\n';
    // var pixelPointOffsetLayoutSizeStr = '   pixelPointOffsetLayoutSize = ${pixelPointOffset.barPointRectSize.asCodeConstructor()};\n';
    var assertOffsetSame = '   assertOffsetResultsSame(pixelPointOffset, ${pixelPointOffset.asCodeConstructor()});\n';
    var assertSizeSame =   '   assertSizeResultsSame(pixelPointOffset.barPointRectSize, ${pixelPointOffset.barPointRectSize.asCodeConstructor()});\n';

    print(' $pointOffsetStr $callStr $assertOffsetSame $assertSizeSame\n\n');
  }
}

/// A zero-height (thus 'invisible') [BarPointContainer] extension.
///
/// Has zero [layoutSize] in the direction of the input data axis. See [layout] for details.
class ZeroValueBarPointContainer extends BarPointContainer {

  ZeroValueBarPointContainer({
    required model.PointModel pointModel,
    required ChartViewModel chartViewModel,
    required DataColumnPointsBar ownerDataColumnPointsBar, // todo-00-done added
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    pointModel: pointModel,
    chartViewModel: chartViewModel,
    ownerDataColumnPointsBar: ownerDataColumnPointsBar, // todo-00-done added
    children: children,
    key: key,
  );

  /// Layout this container by calling super, then set the [layoutSize] in the value direction
  /// (owner layouter mainAxisDirection) to be zero.
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

    DataRangeLabelInfosGenerator inputLabelsGenerator = chartViewModel.inputLabelsGenerator;
    DataRangeLabelInfosGenerator outputLabelsGenerator = chartViewModel.outputLabelsGenerator;

    // Create PointOffset from this [pointModel] by giving it a range,
    // positions the [pointModel] on the x axis on it's label x coordinate.
    // The [pointOffset] can be affmap-ed to it's target value depending on chart direction.
    PointOffset pointOffset = pointModel.asPointOffsetOnInputRange(
      dataRangeLabelInfosGenerator: inputLabelsGenerator,
    );
    PointOffset pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
      chartOrientation: chartViewModel.chartOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: inputLabelsGenerator.dataRange,
      outputDataRange: outputLabelsGenerator.dataRange,
      sizerHeight: sizerHeight,
      sizerWidth: sizerWidth,
    );

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
