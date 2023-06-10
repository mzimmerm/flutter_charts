import 'dart:ui' as ui show Size;

import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';

// todo-00-progress
class TransposingGrid extends NonPositioningBoxLayouter {

  /// The required generative constructor
  TransposingGrid({
    List<BoxContainer>? children,
  }) : super(
    children: children,
  );

  // todo-00-progress : remove this and add  implementation buildAndReplaceChildren
  //  which has TransposingInputValuesGrid and input
  @override
  bool get isLeaf => true;

  // todo-00-progress : remove this and add  implementation buildAndReplaceChildren
  @override
  void layout_Post_Leaf_SetSize_FromInternals() {
    layoutSize = const ui.Size(0.0, 0.0);
  }
}