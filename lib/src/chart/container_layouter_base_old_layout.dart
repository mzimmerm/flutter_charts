import 'dart:ui' as ui show Size, Offset, Canvas;

import 'package:flutter_charts/src/morphic/rendering/constraints.dart' show BoxContainerConstraints;
import 'package:flutter_charts/src/chart/container_layouter_base.dart';


/// Base class which manages, lays out, moves, and paints
/// graphical elements on the chart, for example individual
/// labels, but also a collection of labels.
///
/// This base class manages
///
/// Roles:
/// - Container: through the [layout] method.
/// - Translator (in X and Y direction): through the [applyParentOffset]
///   method.
/// - Painter: through the [paint] method.
///
/// Note on Lifecycle of [BoxContainer] : objects should be such that
///   after construction, methods should be called in the order declared here.
///
abstract class ContainerOld {
  /// Manages the layout size during the layout process in [layout].
  /// Should be only mentioned in this class, not super
  ui.Size layoutSize = ui.Size.zero;

  /// Current absolute offset, set by parent (and it's parent etc, to root).
  ///
  /// That means, it is the offset from (0,0) of the canvas. There is only one
  /// canvas, managed by the top Container, passed to all children in the
  /// [paint(Canvas, Size)].
  ///
  ///
  ///
  /// It is a sum of all offsets passed in subsequent calls
  /// to [applyParentOffset] during object lifetime.
  ui.Offset offset = ui.Offset.zero;

  /// Allow a parent container to move this Container
  /// after [layout].
  ///
  /// Override if parent move needs to propagate to internals of
  /// this [BoxContainer].
  void applyParentOffset(ui.Offset offset) {
    this.offset += offset;
  }

  /// [skipByParent] instructs the parent container that this container should not be
  /// painted or layed out - as if it collapsed to zero size.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  bool skipByParent = false;

  /// If size constraints imposed by parent are too tight,
  /// some internal calculations of sizes may lead to negative values,
  /// making painting of this container not possible.
  ///
  /// Setting the [enableSkipOnDistressedSize] `true` helps to solve such situation.
  /// It causes the container not be painted
  /// (skipped during layout) when space is constrained too much
  /// (not enough space to reasonably paint the container contents).
  /// Note that setting this to `true` may result
  /// in surprizing behavior, instead of exceptions.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  ///
  /// Unlike [skipByParent], which directs the parent to ignore this container,
  /// [enableSkipOnDistressedSize] is intended to be checked in code
  /// for some invalid conditions, and if they are reached, bypass painting
  /// the container.
  bool enableSkipOnDistressedSize = true; // todo-10 set to true for distress test

  bool isDistressed = false;

  ContainerOld();

  // ##### Abstract methods to implement

  // todo-01-morph : This should pass Constraints - see [RenderObject]
  void layout(BoxContainerConstraints boxConstraints, BoxContainer parentBoxContainer);

  void paint(ui.Canvas canvas);
}
