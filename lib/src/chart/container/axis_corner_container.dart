import 'dart:ui' as ui show Rect, Offset, Canvas, Paint;
import 'package:flutter/material.dart' as material show Colors;

// base libraries
import '../../morphic/container/container_layouter_base.dart';

import '../view_maker.dart' as view_maker;

// this level libraries
import '../container/container_common.dart' as container_common;

class AxisCornerContainer extends container_common.ChartAreaContainer {
  AxisCornerContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    List<BoxContainer>? children,
  }) : super(
          chartViewMaker: chartViewMaker,
          children: children,
        );

  // todo-00-last-done : late ui.Rect _rect;

  /// This default implementation has no children, it is leaf, so override the only method
  /// needed to override for leafs
  @override
  layout_Post_Leaf_SetSize_FromInternals() {
    /// Set some small layoutSize
    ui.Rect rect = const ui.Rect.fromLTWH(0.0, 0.0, 20.0, 20.0);

    layoutSize = rect.size;
  }

/* todo-00-last-done
  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    // This was a core issue of layout rectangles and child rectangles not matching.
    super.applyParentOffset(caller, offset);
    _rect = _rect.shift(offset);
  }

  @override
  paint(ui.Canvas canvas) {
    ui.Paint paint = (ui.Paint()..color = material.Colors.red);
    canvas.drawRect(_rect, paint);
  }
  */

  @override
  paint(ui.Canvas canvas) {
    ui.Paint paint = (ui.Paint()..color = material.Colors.red);
    canvas.drawRect(offset & layoutSize, paint);
  }
}
