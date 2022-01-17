import 'dart:ui' as ui show Size, Offset, Canvas;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

import '../morphic/rendering/constraints.dart' show LayoutExpansion;

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
/// Note on Lifecycle of [Container] : objects should be such that
///   after construction, methods should be called in the order declared here.
///
// todo-00-last: Container core rule: I do not expose position, offset, or layoutSize. 
//                 I stay put until someone calls transform on me, OR it's special case applyParentOffset.
//               Is that possible?
abstract class Container {
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
  /// this [Container].
  void applyParentOffset(ui.Offset offset) {
    this.offset += offset;
  }

  // todo-2 move _tiltMatrix to container base, similar to offset and comment as unused
  /// Maintains current tiltMatrix, a sum of all tiltMatrixs
  /// passed in subsequent calls to [applyParentTiltMatrix] during object
  /// lifetime.
  vector_math.Matrix2 _tiltMatrix = vector_math.Matrix2.identity();

  /// Provides access to tiltMatrix for extension's [paint] methods.
  vector_math.Matrix2 get tiltMatrix => _tiltMatrix;

  /// Tilt may apply to the whole container.
  /// todo-2 unused? move to base class? similar to offset?
  void applyParentTiltMatrix(vector_math.Matrix2 tiltMatrix) {
    if (tiltMatrix == vector_math.Matrix2.identity()) return;
    _tiltMatrix = _tiltMatrix * tiltMatrix;
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

  Container();

  // ##### Abstract methods to implement

  // todo-11-last : This should pass Constraints - see [RenderObject]
  void layout(LayoutExpansion parentLayoutExpansion);

  void paint(ui.Canvas canvas);
}
