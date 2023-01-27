import 'dart:ui' as ui show Offset, Paint, Canvas;
import 'container_layouter_base.dart' show BoxContainer, LayoutableBox;

/// Manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
class LineContainer extends BoxContainer {
  /// Points from which line starts and ends. NOT added to children ATM.
  ui.Offset lineFrom;
  ui.Offset lineTo;
  ui.Paint linePaint;

  // todo-01-full-autolayout :  this was added temporarily to move between build and layout, remove
  /// todo-01-full-autolayout : THIS IS TEMPORARY FOR MANUAL LAYOUT TO SHUFFLE VALUES FROM PARENT LAYOUT (GridLinesContainer, something else??)
  /// todo-01-full-autolayout :   TO LineContainer.layout()
  /// With manual layout, holds on to the layout value of horizontal or vertical lines,
  /// between the lifecycle events of [LineContainer]
  /// creation in parent [buildAndAddChildren_DuringParentLayout]
  /// and it's layout in parent [layout].
  ///
  /// ONLY used on horizontal xLineContainer or vertical yLineContainer, maintains the
  /// coordinate that remains the same: y on xLineContainer, x on yLineContainer.
  ///
  double manualLayedOutFromX;
  double manualLayedOutFromY;
  double manualLayedOutToX;
  double manualLayedOutToY;

  LineContainer({
    required this.lineFrom,
    required this.lineTo,
    required this.linePaint,
    this.manualLayedOutFromX = 0.0,
    this.manualLayedOutFromY = 0.0,
    this.manualLayedOutToX = 0.0,
    this.manualLayedOutToY = 0.0,
  });

  // #####  Implementors of method in superclass [Container].

  /// Implementor of method in superclass [Container].
  @override
  void layout() {
    // todo-00-last-last-last : throw StateError('No need to call layout on $runtimeType, extension of LineContainer.');
    /// Use the manually layed out coordinates
    lineFrom = ui.Offset(manualLayedOutFromX, manualLayedOutFromY);
    lineTo = ui.Offset(manualLayedOutToX, manualLayedOutToY);

    layoutSize = constraints.size; // todo-00-last-last also added this
  }

  /// Override method in superclass [Container].
  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    super.applyParentOffset(caller, offset);
    lineFrom += offset;
    lineTo += offset;
  }

  @override
  void paint(ui.Canvas canvas) {
    canvas.drawLine(lineFrom, lineTo, linePaint);
  }

  // todo-00-last-last-last : added as this must be implemented in Leafs. Bizarrely, layoutSize must be set in layout,
  //                          and this just needs to be overriden.
  @override
  void post_Leaf_SetSize_FromInternals() {
    if (!isLeaf) {
      throw StateError('Only a leaf can be sent this message.');
    }
    // throw UnimplementedError('Method must be overridden by leaf BoxLayouters');
    layoutSize = constraints.size; // todo-00-last-last also added this
  }


}
