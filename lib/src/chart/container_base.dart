import 'dart:ui' as ui show Size, Offset, Canvas;
// import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// import 'package:flutter/foundation.dart';
import 'package:flutter_charts/src/chart/new/container_base_new.dart' 
    show BoxContainerVisitor;
import 'package:flutter_charts/src/chart/container_layouter_base.dart'
    show LayoutAxis;


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
  BoxContainer()
      : _parentSandbox = BoxContainerParentSandbox(),
        _layoutSandbox = BoxContainerLayoutSandbox();

  // ----------- Fields managed by Container
  late final BoxContainer _parent;
  final List<BoxContainer> _children = [];
  bool isRoot = false;
  bool get isLeaf => children.isEmpty;
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
  LayoutAxis mainLayoutAxis = LayoutAxis.none;
  LayoutAxis crossLayoutAxis = LayoutAxis.none;
  bool get isLayout => mainLayoutAxis != LayoutAxis.none || crossLayoutAxis != LayoutAxis.none;

  void traverseAndApply(BoxContainerVisitor visitor) {
    // todo-03
  }

  void addChild(BoxContainer boxContainer) {
    boxContainer._parent = boxContainer;
    _children.add(boxContainer);
  }

  List<BoxContainer> get children => _children;

  double layoutLengthAlongMainLayoutAxis() {
    if (mainLayoutAxis == LayoutAxis.horizontal) {
      return layoutSize.width;
    }    
    if (mainLayoutAxis == LayoutAxis.vertical) {
      return layoutSize.height;
    }
    return 0.0;
  }

  // ------------ Fields managed by Sandbox and methods delegated to Sandbox.

  // todo-00-last : consider moving some fields to layoutSandbox
  final BoxContainerParentSandbox _parentSandbox;
  /// Member used during the [layout] processing.
  final BoxContainerLayoutSandbox _layoutSandbox;
  
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

  // Core recursive layout method.
  // todo-00-last : Why do I need greedy children last? So I can give them a Constraint which is a remainder of non-greedy children sizes!!
  void newCoreLayout() {
    if (isRoot) {
      rootStep1_setRootConstraint();
      rootStep2_Recurse_setupContainerHierarchy();
      rootStep3_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast();
      // todo-00-last : make sure it is set before call : _layoutSandbox.constraints = boxContainerConstraints;
    }
    // node-pre-descend
    step301_PreDescend_DistributeMyConstraintToImmediateChildren();
    // node-descend  
    for (var child in children) {
      // child-pre-descend
      // child-descend
      child.newCoreLayout();
      // child-post-descend
    }
    // node-post-descend
    step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize(); // todo-00-last layout specific
  }

  /// Create and add children of this container.
  void rootStep2_Recurse_setupContainerHierarchy() {
    for (var child in children) {
      child.createChildrenOrUseChildrenFromConstructor();
      child.rootStep2_Recurse_setupContainerHierarchy();
    }
  } 
  
  // todo-00-last make abstract, each Container must implement. Layouter has this no-op.
  // Create children one after another, or do nothing if children were created in constructor.
  // Any child created here must be added to the list of children.
  //   - if (we do not want any children created here (may exist from constructor)) return
  //   - create childN
  //   - addChild(childN)
  //   - etc
  void createChildrenOrUseChildrenFromConstructor() {}

  void rootStep3_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast() {
    // sets up childrenGreedyInMainLayoutAxis,  childrenGreedyInCrossLayoutAxis
    // if exactly 1 child greedy in MainLayoutAxis, put it last in childrenInLayoutOrder, otherwise childrenInLayoutOrder=children
    // this.constraints = passedConstraints
    int numGreedyAlongMainLayoutAxis = 0;
    BoxContainer? greedyChild;
    for (var child in children) {
      child.rootStep3_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast();
      if (child.layoutLengthAlongMainLayoutAxis() == double.infinity) {
        numGreedyAlongMainLayoutAxis += 1;
        greedyChild = child;
      }
      _layoutSandbox.addedSizeOfAllChildren += ui.Offset(child.layoutSize.width, child.layoutSize.height);
    }
    if (numGreedyAlongMainLayoutAxis >= 2) {
      throw StateError('Max one child can ask for unlimited (greedy) size along main layout axis. Violated in $this');
    }
    _layoutSandbox.childrenInLayoutOrderGreedyLast = List.from(children);
    if (greedyChild != null) {
      _layoutSandbox.childrenInLayoutOrderGreedyLast
          ..remove(greedyChild)
          ..add(greedyChild);
    }
  }

  void rootStep1_setRootConstraint() {
    // todo-00-last implement where needed
  }
  // Layout specific. only children changed, then next method. Default sets same constraints
  void step301_PreDescend_DistributeMyConstraintToImmediateChildren() {
    for (var child in _layoutSandbox.childrenInLayoutOrderGreedyLast) {
      // todo-00-last - how does this differ for Column, Row, etc?
      child._layoutSandbox.constraints = _layoutSandbox.constraints;
    }
  }
  
  void step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize() {
    if (isLeaf) {
      step301_IfLeafSetMySizeFromInternalsToFitWithinConstraints();
    } else {
      step301_IfNotLeafOffsetChildrenAndCheckIfMySizeFitWithinConstraints();
    }
  }

  // Layouter specific!
  // Exception or visual indication if "my size" is NOT "within my constraints"
  void step301_IfNotLeafOffsetChildrenAndCheckIfMySizeFitWithinConstraints() {
    BoxContainer? previousChild;
    for (var child in _layoutSandbox.childrenInLayoutOrderGreedyLast) {
      // todo-00 : add static method on Size to do Size + Size.
      // todo-00-last-last : need method for envelop of list of children except last greedy
      /* todo-00-last-last : implement this for RowLayouter and ColumnLayouter
          MAYBE THIS NEEDS TO BE A SEPARATE ABSTRACT METHOD 
      ui.Size previousChildOffset = previousChild != null ? previousChild.offset : const ui.Size(0.0, 0.0);
      child.applyParentOffset(previousChild.offset + child.layoutSize); 
      layoutSize = const ui.Size(0.0, 0.0); // size of children envelop
      IF THIS IS A LAST CHILD, AND IT IS GREEDY, RE-SET THE CHILD CONSTRAINT AS MY_CONSTRAINT minus ENVELOP OF PREVIOUS CHILDREN
      THEN CALCULATE THIS GREEDY CHILD LAYOUT AND SET SIZE.
      */
      previousChild = child;
    }
  }
  
  
  void step301_IfLeafSetMySizeFromInternalsToFitWithinConstraints() {} // todo-00-last : make abstract
  
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
  
  // todo-00-done : added then removed : BoxContainerConstraints constraints = BoxContainerConstraints.exactBox(size: const ui.Size(0.0, 0.0));
  
}

// todo-00-done BoxContainerLayoutSandbox - a new class -----------------------------------------------------------------

// todo-01-last : try to make non-nullable and final
class BoxContainerLayoutSandbox {
  List<BoxContainer> childrenInLayoutOrderGreedyLast = [];
  // List<BoxContainer> childrenGreedyAlongMainLayoutAxis = [];
  // List<BoxContainer> childrenGreedyAlongCrossLayoutAxis = [];
  ui.Size addedSizeOfAllChildren = const ui.Size(0.0, 0.0);
  BoxContainerConstraints? constraints;
  
}
