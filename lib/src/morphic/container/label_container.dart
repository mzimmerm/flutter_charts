import 'package:flutter/widgets.dart' as widgets show TextStyle, TextPainter;
import 'package:tuple/tuple.dart' show Tuple2;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'dart:ui' as ui show TextAlign, TextDirection, Canvas, Offset, Size;

// this level or equivalent
import 'container_layouter_base.dart' show BoxContainer, BoxLayouter, LayoutableBox;
import '../../util/geometry.dart' as geometry;
// import '../util/util_dart.dart' as util_dart;

/// Mixin allows [ChartLabelContainer] extend [ChartAreaContainer]
/// and at the same time allows (future) non-chart specific `LabelContainer` labels.
mixin LabelContainerMixin on BoxContainer {

  /// Max width of label (outside constraint).
  ///
  /// Late initialized in layout.
  late final double labelMaxWidth;

  /// Offset of this [LabelContainerOriginalKeep]'s label, created by the [textPainter].
  ///
  ui.Offset offsetOfPotentiallyRotatedLabel = ui.Offset.zero;

  /// Rotation matrix representing the angle by which the label is tilted.
  ///
  /// Tilting of labels is achieve by applying this [Matrix2] on the
  /// rectangle which surrounds the label text.
  late final vector_math.Matrix2 labelTiltMatrix;

  /// [TextPainter] wrapped in this label container.
  /// Paints the [_label]. It is the only painted content of this container.
  late final widgets.TextPainter textPainter;

  /// Minimum envelope around the contained label (and hence, this container).
  /// It is created and kept such that the envelope topLeft = Offset.zero,
  /// that is, the envelope is in label container (and textPainter)
  /// local coordinates.
  late geometry.EnvelopedRotatedRect _tiltedLabelEnvelope;

  /// Position where paint starts painting the label, expressed
  /// in the coordinate system in which this [_tiltedLabelEnvelope.envelopeRect] topLeft
  /// (NOT the _tiltedLabelEnvelope.topLeft) is at the origin.
  ///
  /// The returned value is the offset (before any rotation!),
  /// needed to reach the point where the text in the [textPainter]
  /// should start painting the tilted or non-tilted situation.
  /// In the non-tilted situation, the returned value is always Offset.zero.
  ui.Offset get tiltedLabelEnvelopeTopLeft {
    if (labelTiltMatrix == vector_math.Matrix2.identity()) {
      assert (_tiltedLabelEnvelope.topLeft == ui.Offset.zero);
    }
    return _tiltedLabelEnvelope.topLeft;
  }

  // #####  Implementors of method in superclass [Container].

  /// Calls super method, then adds the passed [offset] to the locally-kept slot
  /// [offsetOfPotentiallyRotatedLabel].
  ///
  /// In more details:  After calling super, rotate the point at which label will start painting -
  /// the [offset] + [_tiltedLabelEnvelope.topLeft] - by the tilt angle against the
  /// tilt (this angle is represented by [labelTiltMatrix] inverse).
  ///
  /// In *non-tilted labels*, the [_tiltedLabelEnvelope] was created as
  /// ```dart
  ///   ui.Offset.zero & _textPainter.size, // offset & size => Rect
  /// ```
  /// so the [_tiltedLabelEnvelope.topLeft] is always origin ([0.0, 0.0]).
  /// In addition, the [labelTiltMatrix] is identity, so this method will set
  /// ```dart
  ///   offsetOfPotentiallyRotatedLabel = offset
  /// ```
  /// to the value of [offset] (large, after all parent offsets applied).
  ///
  /// In the *tilted labels*, the [_tiltedLabelEnvelope.topLeft]
  /// is a small value below origin such as [0.0, 30.0],
  /// and [offset] is also large, after all parent offsets applied. In this situation,
  /// the non-zero  [_tiltedLabelEnvelope.topLeft] represent the needed slight 'shift down'
  /// of the original [offset] at which to start painting, as the tilted labels take up a bigger rectangle.
  ///
  // todo-04-morph : this implementation only works for tilting in [HorizontalAxisContainer] because first call to it is
  //                 made in [HorizontalAxisContainer.layout], after label container is created, as
  //                    `inputLabelContainer.applyParentOffset(this, labelLeftTop + inputLabelContainer.tiltedLabelEnvelopeTopLeft)`.
  //                 In this first call(s), the result of offsetOfPotentiallyRotatedLabel is the rotated
  //                    value, which is OVERWRITTEN by the last call described below;
  //                    also, the accumulated non-rotated this.offset is kept on super slot
  //                    This is what we want - we want to keep the non-rotated this.offset on super slot,
  //                    and only do the rotation on the last call (last before paint)
  //                 The last call is made in [ChartRootContainer.layout] inside
  //                     `horizontalAxisContainer.applyParentOffset(this, horizontalAxisContainerOffset)` as
  //                 as
  //                    for (AxisLabelContainer inputLabelContainer in _inputLabelContainers) {
  //                      inputLabelContainer.applyParentOffset(this, offset);
  //                    }
  //                 which calculates and stores the rotated value of the accumulated non-rotated this.offset
  //                 into offsetOfPotentiallyRotatedLabel; which value is used by paint.
  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    super.applyParentOffset(caller, offset);

    // Next, _rotateLabelEnvelopeTopLeftToPaintOffset:
    // Transform the point where label painting starts against the tilt of labels.
    // No-op for non-tilted labels, where _labelTiltMatrix is identity,
    //   and  _tiltedLabelEnvelope.topLeft is center = Offset.zero.
    vector_math.Matrix2 canvasTiltMatrix = labelTiltMatrix.clone();
    canvasTiltMatrix.invert();

    offsetOfPotentiallyRotatedLabel = geometry.transform(
      matrix: canvasTiltMatrix,
      offset: (this.offset),
    );
  }

  /// Implementor of method in superclass [Container].
  @override
  void paint(ui.Canvas canvas) {
    textPainter.paint(canvas, offsetOfPotentiallyRotatedLabel);
  }

  /// This override is essentially semi-manual layout for it's class [ChartLabelContainer],
  ///   which allows to calculate several layout related values.
  ///
  /// First, it calculates and sets the [_labelMaxWidth] member,
  ///   in [_layoutLogicToSetMemberMaxSizeForTextLayout]. See [_layoutLogicToSetMemberMaxSizeForTextLayout] for details.
  ///
  /// Second, it calls [textPainter.layout] in [_layoutLogicToSetMemberMaxSizeForTextLayout],
  ///   which obtains the size of [textPainter]. The resulting [layoutSize] of this [ChartLabelContainer]
  ///   is set from the bounding rectangle of potentially rotated [textPainter].
  ///
  /// Note: On this leaf, instead of overriding this internal method, we could override [layout]
  ///        witch exactly same code, and things would work, except missing check if
  ///        layout size is within constraints.
  @override
  void layout_Post_Leaf_SetSize_FromInternals() {
    _layoutLogicToSetMemberMaxSizeForTextLayout();

    // Call manual layout - the returned sizeAndOverflow contains layoutSize in item1
    Tuple2 sizeAndOverflow = _layoutAndCheckOverflowInTextDirection();
    // Set the layout size for parent to know how big this manually layed out label is.
    layoutSize = sizeAndOverflow.item1;
  }

  ///  Calculated and sets [_labelMaxWidth] used to layout [textPainter.layout].
  ///
  ///   [layoutableBoxParentSandbox.constraints] is needed to have been
  ///   set on this object by parent in layout (before this [layout] is called,
  ///   parent would have pushed constraints.
  void _layoutLogicToSetMemberMaxSizeForTextLayout() {
    // todo-0110 : this seems incorrect - used for all labels, yet it acts as legend label!!
    labelMaxWidth = calcLabelMaxWidthFromLayoutOptionsAndConstraints();
    if (allowParentToSkipOnDistressedSize && labelMaxWidth <= 0.0) {
      // todo-02 : fix this as not dealing with width < 0 brings issues further
      applyParentOrderedSkip(parent as BoxLayouter, true);
      layoutSize = ui.Size.zero;
      return;
    }
  }

  double calcLabelMaxWidthFromLayoutOptionsAndConstraints();

  // ##### Internal methods

  /// Lays out for later painting, the member [_label] text
  /// specifying the maximum allowed width [_labelMaxWidth],
  /// then tests if the label fits the width.
  ///
  /// Returns `true` if label would overflow in the direction of text,
  /// `false` otherwise.
  ///
  /// The direction of text is important,  we check for overflow in letters'
  /// horizontal (length) direction, which is normally along horizontal direction.
  /// But note that canvas can be rotated, so we may be checking along
  /// vertical direction in that case.
  ///
  /// Implementation and Behaviour:
  /// - Because the underlying [textPainter] is always
  ///   - created using [widgets.TextPainter.ellipses]
  ///   - and layed out using `textPainter.layout(maxWidth:)`
  ///     the subsequent `textPainter.paint(canvas)` call paints the label
  ///     **as always cropped to it's allocated size [_labelMaxWidth]**.
  /// - [_isOverflowingInLabelDirection] can be asked but this is information only.
  Tuple2<ui.Size, bool> _layoutAndCheckOverflowInTextDirection() {
    textPainter.layout();

    bool isOverflowingHorizontally = false;
    _tiltedLabelEnvelope = _createLabelEnvelope();
    ui.Size layoutSize = _tiltedLabelEnvelope.size;

    // todo-0110 : add exception if reached with _labelMaxWidth < 0.0
    if (layoutSize.width > labelMaxWidth) {
      isOverflowingHorizontally = true;
      textPainter.layout(maxWidth: labelMaxWidth);
      _tiltedLabelEnvelope = _createLabelEnvelope();
      layoutSize = _tiltedLabelEnvelope.size;
    }

    return Tuple2(layoutSize, isOverflowingHorizontally);
  }

  /// Creates the envelope rectangle [EnvelopedRotatedRect], which [EnvelopedRotatedRect.topLeft]
  /// is used to position this [LabelContainerOriginalKeep] for painting with or without tilt.
  geometry.EnvelopedRotatedRect _createLabelEnvelope() {
    // Only after layout, we know the envelope of tilted label
    return geometry.EnvelopedRotatedRect.centerRotatedFrom(
      rect: ui.Offset.zero & textPainter.size, // offset & size => Rect
      rotateMatrix: labelTiltMatrix,
    );
  }

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }
}

/// Class for value objects which group the text styles that may affect
/// [LabelContainerOriginalKeep]'s instances layout.
class LabelStyle {
  widgets.TextStyle textStyle;
  ui.TextDirection textDirection;
  ui.TextAlign textAlign;
  double textScaleFactor;

  LabelStyle({
    required this.textStyle,
    required this.textDirection,
    required this.textAlign,
    required this.textScaleFactor,
  });
}



