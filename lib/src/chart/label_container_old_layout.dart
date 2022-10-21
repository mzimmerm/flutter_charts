import 'dart:ui';

import 'package:flutter/widgets.dart' as widgets show TextStyle, TextSpan, TextPainter;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:tuple/tuple.dart' show Tuple2;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'dart:ui' as ui show TextAlign, TextDirection, Canvas, Offset;

import 'container_layouter_base.dart' show BoxContainer;
import '../morphic/rendering/constraints.dart' show BoxContainerConstraints;
import '../util/geometry.dart' as geometry;


class LabelContainerOriginalKeep extends BoxContainer {
  /// Max width of label (outside constraint)
  final double _labelMaxWidth;

  /// Offset of this [LabelContainerOriginalKeep]'s label, created by the [_textPainter].
  ///
  Offset offsetOfPotentiallyRotatedLabel = Offset.zero;

  /// Rotation matrix representing the angle by which the label is tilted.
  ///
  /// Tilting of labels is achieve by applying this [Matrix2] on the
  /// rectangle which surrounds the label text.
  final vector_math.Matrix2 _labelTiltMatrix;

  /// [TextPainter] wrapped in this label container.
  /// Paints the [_label]. It is the only painted content of this container.
  final widgets.TextPainter _textPainter;

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
  /// needed to reach the point where the text in the [_textPainter]
  /// should start painting the tilted or non-tilted situation.
  /// In the non-tilted situation, the returned value is always Offset.zero.
  Offset get tiltedLabelEnvelopeTopLeft {
    if (_labelTiltMatrix == vector_math.Matrix2.identity()) {
      assert (_tiltedLabelEnvelope.topLeft == Offset.zero);
    }
    return _tiltedLabelEnvelope.topLeft;
  }

  // Allows to configure certain sizes, colors, and layout.
  // final LabelStyle _labelStyle;

  /// Constructs an instance for a label, it's text style, and label's
  /// maximum width.
  ///
  /// todo-01 : Does not set parent container's [_boxConstraints] and [chartRootContainer].
  /// It is currently assumed clients will not call any methods using them.
  LabelContainerOriginalKeep({
    required String label,
    required double labelMaxWidth,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
  })  : _labelMaxWidth = labelMaxWidth,
        _labelTiltMatrix = labelTiltMatrix,
  // _labelStyle = labelStyle,
        _textPainter = widgets.TextPainter(
          text: widgets.TextSpan(
            text: label,
            style: labelStyle.textStyle, // All labels share one style object
          ),
          textDirection: labelStyle.textDirection,
          textAlign: labelStyle.textAlign,
          // center in available space
          textScaleFactor: labelStyle.textScaleFactor,
          // removed, causes lockup: ellipsis: "...", // forces a single line - without it, wraps at width
        ),
  //  textScaleFactor does nothing ??
        super() {
    // var text = new widgets.TextSpan(
    //   text: label,
    //   style: _labelStyle.textStyle, // All labels share one style object
    // );
    // _textPainter = new widgets.TextPainter(
    //   text: text,
    //   textDirection: _labelStyle.textDirection,
    //   textAlign: _labelStyle.textAlign,
    //   // center in available space
    //   textScaleFactor: _labelStyle.textScaleFactor,
    //   // todo-02 add to test - was removed, causes lockup: ellipsis: "...", // forces a single line - without it, wraps at width
    // ); //  textScaleFactor does nothing ??
  }

  // #####  Implementors of method in superclass [Container].

  /// Calls super method, then adds the passed [offset] to the locally-kept slot
  /// [offsetOfPotentiallyRotatedLabel].
  ///
  /// In more details:  After calling super, rotate the point at which label will start painting -
  /// the [offset] + [_tiltedLabelEnvelope.topLeft] - by the tilt angle against the
  /// tilt (this angle is represented by [_labelTiltMatrix] inverse).
  ///
  /// In *non-tilted labels*, the [_tiltedLabelEnvelope] was created as
  /// ```dart
  ///   ui.Offset.zero & _textPainter.size, // offset & size => Rect
  /// ```
  /// so the [_tiltedLabelEnvelope.topLeft] is always origin ([0.0, 0.0]).
  /// In addition, the [_labelTiltMatrix] is identity, so this method will set
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
  // todo-01-morph : this implementation only works for tilting in [XContainer] because first call to it is
  //                 made in [XContainer.layout], after label container is created, as
  //                    `xLabelContainer.applyParentOffset(labelLeftTop + xLabelContainer.tiltedLabelEnvelopeTopLeft)`.
  //                 In this first call(s), the result of offsetOfPotentiallyRotatedLabel is the rotated
  //                    value, which is OVERWRITTEN by the last call described below;
  //                    also, the accumulated non-rotated this.offset is kept on super slot
  //                    This is what we want - we want to keep the non-rotated this.offset on super slot,
  //                    and only do the rotation on the last call (last before paint)
  //                 The last call is made in [ChartRootContainer.layout] inside
  //                     `xContainer.applyParentOffset(xContainerOffset)` as
  //                 as
  //                    for (AxisLabelContainer xLabelContainer in _xLabelContainers) {
  //                      xLabelContainer.applyParentOffset(offset);
  //                    }
  //                 which calculates and stores the rotated value of the accumulated non-rotated this.offset
  //                 into offsetOfPotentiallyRotatedLabel; which value is used by paint.
  @override
  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);

    // todo-01-morph : This should be part of new method 'findPosition' in the layout process
    // Next, _rotateLabelEnvelopeTopLeftToPaintOffset:
    // Transform the point where label painting starts against the tilt of labels.
    // No-op for non-tilted labels, where _labelTiltMatrix is identity,
    //   and  _tiltedLabelEnvelope.topLeft is center = Offset.zero.
    vector_math.Matrix2 canvasTiltMatrix = _labelTiltMatrix.clone();
    canvasTiltMatrix.invert();

    offsetOfPotentiallyRotatedLabel = geometry.transform(
      matrix: canvasTiltMatrix,
      offset: (this.offset),
    );
  }

  /// Implementor of method in superclass [Container].
  @override
  void paint(ui.Canvas canvas) {
    _textPainter.paint(canvas, offsetOfPotentiallyRotatedLabel);
  }

  /// Lays out this [LabelContainerOriginalKeep].
  ///
  /// The layout step 1 is calling the contained [_textPainter.layout];
  /// step 2 is creating the [_tiltedLabelEnvelope] around the horizontally layed out [_textPainter]
  /// by calling
  /// ```dart
  ///   _tiltedLabelEnvelope = _createLabelEnvelope();
  /// ```
  ///
  @override
  void layout(BoxContainerConstraints boxConstraints, BoxContainer parentBoxContainer) {
    // todo-01-morph : cannot set _boxConstraints here, as it is private in another src file
    //                  it does not appear needed.
    Tuple2 sizeAndOverflow = _layoutAndCheckOverflowInTextDirection();
    layoutSize = sizeAndOverflow.item1;
  }

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
  /// - Because the underlying [_textPainter] is always
  ///   - created using [widgets.TextPainter.ellipses]
  ///   - and layed out using `textPainter.layout(maxWidth:)`
  ///     the subsequent `textPainter.paint(canvas)` call paints the label
  ///     **as always cropped to it's allocated size [_labelMaxWidth]**.
  /// - [_isOverflowingInLabelDirection] can be asked but this is information only.
  Tuple2<Size, bool> _layoutAndCheckOverflowInTextDirection() {
    _textPainter.layout();

    bool isOverflowingHorizontally = false;
    _tiltedLabelEnvelope = _createLabelEnvelope();
    Size layoutSize = _tiltedLabelEnvelope.size;

    if (layoutSize.width > _labelMaxWidth) {
      isOverflowingHorizontally = true;
      _textPainter.layout(maxWidth: _labelMaxWidth);
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
      rect: ui.Offset.zero & _textPainter.size, // offset & size => Rect
      rotateMatrix: _labelTiltMatrix,
    );
  }

}
