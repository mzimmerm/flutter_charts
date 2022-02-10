import 'dart:ui' as ui show Size, Offset, Canvas;
// import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

import 'package:flutter/foundation.dart';
import 'package:flutter_charts/src/chart/new/container_base_new.dart' show BoxContainerVisitor;

import '../morphic/rendering/constraints.dart' show BoxContainerConstraints;

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
  void layout(BoxContainerConstraints boxConstraints);

  void paint(ui.Canvas canvas);
}

abstract class BoxContainer {

  /// Default generative constructor. Prepares [_parentSandbox].
  BoxContainer() : _parentSandbox = BoxContainerParentSandbox();

  // ----------- Fields managed by Container

  /// Manages the layout size during the layout process in [layout].
  /// Should be only mentioned in this class, not super
  ui.Size layoutSize = ui.Size.zero;

  /// If size constraints imposed by parent are too tight,
  /// some internal calculations of sizes may lead to negative values,
  /// making painting of this containerNew not possible.
  ///
  /// Setting the [allowParentToSkipOnDistressedSize] `true` helps to solve such situation.
  /// It causes the containerNew not be painted
  /// (skipped during layout) when space is constrained too much
  /// (not enough space to reasonably paint the containerNew contents).
  /// Note that setting this to `true` may result
  /// in surprizing behavior, instead of exceptions.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  ///
  /// Unlike [parentOrderedToSkip], which directs the parent to ignore this containerNew,
  /// [allowParentToSkipOnDistressedSize] is intended to be checked in code
  /// for some invalid conditions, and if they are reached, bypass painting
  /// the containerNew.
  bool allowParentToSkipOnDistressedSize = true;
  
  late final BoxContainer _parent;
  
  final List<BoxContainer> _children = [];

  void addChild(BoxContainer boxContainer) {
    boxContainer._parent = boxContainer;
    _children.add(boxContainer);
  }

  List<BoxContainer> get children => _children;
  
  bool isRoot = false;
  
  String name = 'DefaultBoxContainerName';
  
  void traverseAndApply(BoxContainerVisitor visitor) {
    // todo-03
  }

  // ------------ Fields managed by Sandbox and methods delegated to Sandbox.

  final BoxContainerParentSandbox _parentSandbox;

  /// Current absolute offset, set by parent (and it's parent etc, to root).
  ///
  /// That means, it is the offset from (0,0) of the canvas. There is only one
  /// canvas, managed by the top ContainerNew, passed to all children in the
  /// [paint(Canvas, Size)].
  ///
  ///
  ///
  /// It is a sum of all offsets passed in subsequent calls
  /// to [applyParentOffset] during object lifetime.
  ui.Offset get offset => _parentSandbox.offset;

  /// Allow a parent containerNew to move this ContainerNew
  /// after [layout].
  ///
  /// Override if parent move needs to propagate to internals of
  /// this [ContainerNew].
  void applyParentOffset(ui.Offset offset) {
    // todo-01-last : add caller arg, pass caller=this and check : assert(caller == _parent);
    //                same on all methods delegated to _parentSandbox
    _parentSandbox.applyParentOffset(offset);
  }

  set parentOrderedToSkip(bool skip) {
    if (skip && !allowParentToSkipOnDistressedSize) {
      throw StateError('Parent did not allow to skip');
    }
    _parentSandbox.parentOrderedToSkip = skip;
  }
  bool get parentOrderedToSkip => _parentSandbox.parentOrderedToSkip;

  // ##### Abstract methods to implement

  void layout(BoxContainerConstraints boxConstraints);

  // todo-01 : split:
  //           - Container to BoxContainer and PieContainer
  //           - Shape to BoxShape (wraps Size) and PieShape
  //           - ContainerConstraint to BoxContainerConstraint and PieContainerConstraint 
  // todo-01 : Change this base class Container.layout to 
  //               Shape layout({required covariant ContainerConstraints constraints}); // Must set Shape (Size for now) on parentSandbox 
  //           This base layout maybe eventually configures some constraints caching and debugging.
  //           Extensions of Container: BoxContainer, PieContainer override layout as
  //               BoxShape layout({required covariant BoxContainerConstraints constraints}); // Must set BoxShape (essentially, this is Size)  on parentSandbox 
  //               PieShape layout({required covariant PieContainerConstraints constraints}); // Must set PieShape on parentSandbox

  void paint(ui.Canvas canvas);

/* END of ContainerBridgeToNew: KEEP
  // todo-02 : Replace ParentOffset with ParentTransform. ParentTransform can be ParentOffsetTransform, 
  //           ParentTiltTransform, ParentSheerTransform etc. 
  /// Maintains current tiltMatrix, a sum of all tiltMatrixs
  /// passed in subsequent calls to [applyParentTransformMatrix] during object
  /// lifetime.
  vector_math.Matrix2 _transformMatrix = vector_math.Matrix2.identity();

  /// Provides access to tiltMatrix for extension's [paint] methods.
  vector_math.Matrix2 get transformMatrix => _transformMatrix;

  /// Tilt may apply to the whole containerNew.
  /// todo-2 unused? move to base class? similar to offset?
  void applyParentTransformMatrix(vector_math.Matrix2 transformMatrix) {
    if (transformMatrix == vector_math.Matrix2.identity()) return;
    _transformMatrix = _transformMatrix * transformMatrix;
  }
  */
}

// todo-00-document
/// Only parent containers of the container that owns this object should be allowed to 
/// get or set any field inside this object.
class BoxContainerParentSandbox {

  /// Current absolute offset, set by parent (and it's parent etc, to root).
  ///
  /// That means, it is the offset from (0,0) of the canvas. There is only one
  /// canvas, managed by the top ContainerNew, passed to all children in the
  /// [paint(Canvas, Size)].
  ///
  ///
  ///
  /// It is a sum of all offsets passed in subsequent calls
  /// to [applyParentOffset] during object lifetime.
  ui.Offset offset = ui.Offset.zero;

  /// Allow a parent containerNew to move this ContainerNew
  /// after [layout].
  ///
  /// Override if parent move needs to propagate to internals of
  /// this [ContainerNew].
  void applyParentOffset(ui.Offset offset) {
    this.offset += offset;
  }

  /// [parentOrderedToSkip] instructs the parent containerNew that this containerNew should not be
  /// painted or layed out - as if it collapsed to zero size.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  bool parentOrderedToSkip = false;
  
}
