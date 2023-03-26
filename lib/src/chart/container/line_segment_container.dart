import 'dart:ui' as ui show Offset, Paint, Canvas;

import 'container_common.dart' as container_common_new;
import '../../morphic/container/container_layouter_base.dart' as container_base;
import '../view_maker.dart' as view_maker;
// import '../container.dart' as container;
import '../model/data_model.dart' as model;
import '../../util/util_labels.dart' as util_labels;

/// Leaf container manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
/// todo-00-last-last-progress IMPLEMENT EVERYTHING BELOW:
///   0. Add ChartPoint class, extends Offset, names are inputValue, outputValue, for dx and dy
///   1. Add LineSegmentContainer members - this assumes the container is placed inside Row or Column layouter:
///     - mainLayoutAxis : LayoutAxis.horizontal/vertical : main axis along which the IMMEDIATE parent Row or Column layout (MainAndCross container): horizontal for Row, vertical for Column
///     - independentAxis : LayoutAxis.horizontal/vertical : horizontal if independent values show horizontally (default, X)
///     - chartOrientation : see point 2. , exception otherwise
///   2. Allowed combination of mainLayoutAxis and independentAxis
///      - mainLayoutAxis = vertical (column), independentAxis = horizontal (horizontal bar chart, line chart)         call this combination enum ChartOrientation.column
///      - mainLayoutAxis = horizontal (row),  independentAxis = vertical   (vertical bar chart, inverted line chart)  call this combination enum ChartOrientation.row
///   3. Rules for layout of inputValue and outputValue values - all 'normal' situations
///     - Motivation: any ChartPoint, originally representing data inputValue and outputValue values,
///       can live in a SegmentContainer which NORMALLY lives within a  MainAndCross (Row, Column) container.
///       DURING LAYOUT, THE SegmentContainer  WILL CHANGE THE ChartPoint POSITION (valuer) BY LEXTR OR USING THE LAYOUTER.
///       (the SegmentContainer will position the ChartPoint in layout_Post_NotLeaf_PositionChildren) ???
///   4. Rules for lextr-ing of inputValue and outputValue values
///     4.1 independent values: ChartPoint component is lextr-ed to constraints width (or height)
///       4.11 ChartOrientation.column: inputValue lextr-ed to constraints.width
///       4.12 ChartOrientation.row:    inputValue lextr-ed to constraints.height
///     4.2 dependent values:   ChartPoint component is lextr-ed, to the available Sizer height (or width)
///       4.21 ChartOrientation.column: inputValue lextr-ed to Sizer.height  (dataRange on  dependent axis)
///       4.22 ChartOrientation.row:    inputValue lextr-ed to Sizer.width   (dataRange on  dependent axis - SAME)
///    5. Rules for how ChartPoint changes after lextr:
///       - ChartOrientation.column: ChartPoint(inputValue, outputValue) => pixel ChartPoint(4.11: lextr inputValue to constraints.width, 4.21 lextr outputValue   to Sizer.height)
///       - ChartOrientation.row:    ChartPoint(inputValue, outputValue) => pixel ChartPoint(4.22: lextr outputValue to Sizer.width,         4.12 lextr inputValue to constraints.height)
///       - basically , in row orientation, the inputValue value becomes lextr outputValue when converted to pixels.
///    6. place 0. 3,4,5 to chart_point.dart. 1 to LineSegmentContainer, 2. to chart_orientation.dart
class LineSegmentContainer extends container_common_new.ChartAreaContainer {

  LineSegmentContainer({
    required this.pointFrom,
    required this.pointTo,
    required this.linePaint,
    required this.constraintsSplitAxis,
    required view_maker.ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker
  );


  /// Model contains the transformed, non-extrapolated values of the point where the line starts.
  final model.PointModel pointFrom;
  final model.PointModel pointTo;
  final ui.Paint linePaint;
  final container_base.LayoutAxis constraintsSplitAxis;

  /// Coordinates of the layed out pixel values.
  late final ui.Offset _pixelPointFrom;
  late final ui.Offset _pixelPointTo;


  // #####  Implementors of method in superclass [BoxContainer].

  /// Implementor of method in superclass [BoxContainer].
  ///
  /// Ensure [layoutSize] is set.
  /// Note that because this leaf container overrides [layout] here,
  /// it does not need to override [layout_Post_Leaf_SetSize_FromInternals].
  @override
  void layout() {
    buildAndReplaceChildren();

    // The switch below takes care of the pixel positioning aka layout.

    // layout the [pointFrom] and [pointTo] to pixels, by positioning:
    //   - in the [constraintsSplitAxis],      direction, on the constraints border
    //   - in the [constraintsSplitAxis]-cross direction, by extrapolating their value
    double pixelFromX, pixelFromY, pixelToX, pixelToY;

    // Which labels generator to use for scaling? That depends on which axis is 'independent'
    //   - switch constraints are split along
    //     - horizontal, parent is Row    by definition. We ASSUME dependent axis is Y, use it's extrapolation
    //     - vertical,   parent is Column by definition. We ASSUME dependent axis is X, use it's extrapolation
    util_labels.DataRangeLabelInfosGenerator labelInfosGenerator;

    switch(constraintsSplitAxis) {
      case container_base.LayoutAxis.horizontal:
        // Assuming Row, X is constraints.width, Y is extrapolating value to constraints.height
        labelInfosGenerator = chartViewMaker.yLabelsGenerator;
        pixelFromX = 0;
        pixelToX = constraints.width;
        pixelFromY = labelInfosGenerator.lextrValueToPixels(
          value: pointFrom.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.height,
        );
        pixelToY = labelInfosGenerator.lextrValueToPixels(
          value: pointTo.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.height,
        );
        break;
      case container_base.LayoutAxis.vertical:
      // Assuming Row, Y is constraints.height, X is extrapolating value to constraints.width
        labelInfosGenerator = chartViewMaker.xLabelsGenerator;
        pixelFromY = 0;
        pixelToY = constraints.height;
        pixelFromX = labelInfosGenerator.lextrValueToPixels(
          value: pointFrom.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.width,
        );
        pixelToX = labelInfosGenerator.lextrValueToPixels(
          value: pointTo.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.width,
        );
        break;
    }

    _pixelPointFrom = ui.Offset(pixelFromX, pixelFromY);
    _pixelPointTo = ui.Offset(pixelToX, pixelToY);

    layoutSize = constraints.size; // todo-00!! is this right?
  }

  /// Override method in superclass [Container].
  @override
  void applyParentOffset(container_base.LayoutableBox caller, ui.Offset offset) {
    super.applyParentOffset(caller, offset);

    _pixelPointFrom += offset;
    _pixelPointTo += offset;
  }

  @override
  void paint(ui.Canvas canvas) {
    canvas.drawLine(_pixelPointFrom, _pixelPointTo, linePaint);
  }

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }
}
