import 'package:flutter_charts/src/chart/container.dart' show AdjustableLabelsChartAreaContainer;
import 'package:flutter_charts/src/chart/options.dart' show ChartOptions;
import 'package:flutter_charts/src/morphic/rendering/constraints.dart';
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'dart:math' as math show pi;

enum LabelFitMethod {
  rotateLabels,
  decreaseLabelFont,
  skipLabels,
}

/// Strategy of achieving that labels do not overlap ("fit") on an axis.
///
/// Currently only used on the X axis, this strategy defines a sequence of steps,
/// each performing a specific strategy to achieve labels fit.
///
/// When the [layout()] finds labels overlap, the following steps are taken
/// to achieve "fit" of labels: [LabelFitMethod.rotateLabels],
/// [LabelFitMethod.decreaseLabelFont] and [LabelFitMethod.skipLabels].
///
/// The steps are repeated at most [maxLabelReLayouts] times.
/// If a "fit" is not achieved on last step, the last step is repeated
/// until [maxLabelReLayouts] is reached.
class DefaultIterativeLabelLayoutStrategy extends LabelLayoutStrategy {
  // todo-2 try using Mixins

  /// Members related to re-layout (iterative layout).
  /// The values are incremental, each re-layout "accumulates" changes
  /// from previous layouts.
  /// For example, _labelFontSize starts with default from options,
  /// later can change by _decreaseLabelFontRatio.
  ///
  // If _reLayoutDecreaseLabelFont is not called, _labelFontSize is never moved away from 0.0
  double _labelFontSize;

  @override
  double get labelFontSize => _labelFontSize;

  /// In addition to the rotation matrices, hold on radians for canvas rotation.
  final double _labelTiltRadians;

  @override
  double get labelTiltRadians => _labelTiltRadians;

  bool _isRotateLabelsReLayout = false;

  @override
  bool get isRotateLabelsReLayout => _isRotateLabelsReLayout;

  int _reLayoutsCounter = 0;
  int _showEveryNthLabel = 0;

  @override
  int get showEveryNthLabel => _showEveryNthLabel;

  /// On multiple auto layout iterations, every new iteration skips more labels.
  /// every iteration, the number of labels skipped is multiplied by
  /// [_multiplyLabelSkip]. For example, if on first layout,
  /// [_showEveryNthLabel] was 3, and labels still overlap, on the next re-layout
  /// the  [_showEveryNthLabel] would be `3 * _multiplyLabelSkip`.
  final int _multiplyLabelSkip;

  final int _maxLabelReLayouts;

  final double _decreaseLabelFontRatio;

  /// For tilted labels, this is the forward rotation matrix
  /// to apply on both Canvas AND label envelope's topLeft offset's coordinate
  /// (pivoted on origin, once all chart offsets are applied to label).
  /// This is always the inverse of [_labelTiltMatrix].
  /// Just passed down to [LabelContainer]s.
  vector_math.Matrix2 _canvasTiltMatrix = vector_math.Matrix2.identity();

  @override
  vector_math.Matrix2 get canvasTiltMatrix => _canvasTiltMatrix;

  /// Angle by which labels are tilted.
  /// Just passed down to [LabelContainer]s.
  vector_math.Matrix2 _labelTiltMatrix = vector_math.Matrix2.identity();

  @override
  vector_math.Matrix2 get labelTiltMatrix => _labelTiltMatrix;

  /// Constructor uses default values from [ChartOptions]
  // todo-11-last : Move all re-layout specific settings from options to DefaultIterativeLabelLayoutStrategy
  //                But they still need to default from options or somewhere?
  DefaultIterativeLabelLayoutStrategy({
    required ChartOptions options,
  })  : _decreaseLabelFontRatio = options.iterativeLayoutOptions.decreaseLabelFontRatio,
        _showEveryNthLabel = options.iterativeLayoutOptions.showEveryNthLabel,
        _maxLabelReLayouts = options.iterativeLayoutOptions.maxLabelReLayouts,
        _multiplyLabelSkip = options.iterativeLayoutOptions.multiplyLabelSkip,
        _labelFontSize = options.labelCommonOptions.labelFontSize,
        _labelTiltRadians = options.iterativeLayoutOptions.labelTiltRadians;

  LabelFitMethod _atDepth(int depth) {
    switch (depth) {
      case 1:
        return LabelFitMethod.rotateLabels;
      case 2:
        return LabelFitMethod.skipLabels;
      case 3:
        return LabelFitMethod.decreaseLabelFont;
      case 4:
        return LabelFitMethod.decreaseLabelFont;
      default:
        return LabelFitMethod.skipLabels;
    }
  }

  /// Core of the auto layout strategy.
  ///
  /// If labels in the [_container] overlap, this method takes the
  /// next prescribed auto-layout action - one of the actions defined in the
  /// [LabelFitMethod] enum (DecreaseLabelFont, RotateLabels,  SkipLabels)
  ///
  @override
  void reLayout(LayoutExpansion parentLayoutExpansion) {
    if (!_container.labelsOverlap()) {
      // if there is no overlap, no (more) iterative calls
      //   to layout(). Exits from iterative layout.
      return;
    }
    _reLayoutsCounter++;

    if (_reLayoutsCounter > _maxLabelReLayouts) {
      return;
    }

    _isRotateLabelsReLayout = false;

    switch (_atDepth(_reLayoutsCounter)) {
      case LabelFitMethod.decreaseLabelFont:
        _reLayoutDecreaseLabelFont();
        break;
      case LabelFitMethod.rotateLabels:
        _reLayoutRotateLabels();
        _isRotateLabelsReLayout = true;
        break;
      case LabelFitMethod.skipLabels:
        _reLayoutSkipLabels();
        break;
    }
    _container.layout(parentLayoutExpansion); // will call this function back!

    // print("Iterative layout finished after $_reLayoutsCounter iterations.");
  }

  void _reLayoutRotateLabels() {
    //  angle must be in interval `<-math.pi, +math.pi>`
    if (!(-1 * math.pi <= _labelTiltRadians && _labelTiltRadians <= math.pi)) {
      throw StateError('angle must be between -PI and +PI');
    }

    _makeTiltMatricesFromTiltRadians();
  }

  void _makeTiltMatricesFromTiltRadians() {
    _canvasTiltMatrix = vector_math.Matrix2.rotation(_labelTiltRadians);
    // label is actually tilted in the direction when canvas is rotated back,
    //   so the label tilt is inverse of the canvas tilt
    _labelTiltMatrix = vector_math.Matrix2.rotation(-_labelTiltRadians);
  }

  void _reLayoutDecreaseLabelFont() {
    // Decrease font (already init-ted from options), and call layout again
    _labelFontSize *= _decreaseLabelFontRatio;
  }

  void _reLayoutSkipLabels() {
    // Most advanced; Keep list of labels, but only display every nth
    _showEveryNthLabel *= _multiplyLabelSkip;
  }
}

/// Base class for layout strategies.
///
/// A Layout strategy is a pluggable class which achieves that labels,
/// (or more generally, some adjustable content) "fit" in a container.
///
/// Strategy defines a zero or more sequences of steps,
/// each performing a specific code to achieve labels fit, for example:
///   - Skip every 2nd label
///   - Tilt all labels
///   - Decrease label font size
abstract class LabelLayoutStrategy {
  late AdjustableLabelsChartAreaContainer _container;

  LabelLayoutStrategy();

  void onContainer(AdjustableLabelsChartAreaContainer container) {
    _container = container;
  }

  /// Core of the auto layout strategy.
  ///
  /// Typically called from the [Container]'s [Container.layout]
  /// method to achieve iterative layout.
  ///
  /// Implementations should either not do anything (OnePassLayoutStrategy),
  /// or check for [_container]'s labels overlap. On overlap,
  /// it should set some values on [_container]'s labels to
  /// make them smaller, less dense, tilt, skip etc, and call
  /// [Container.layout] iteratively.
  void reLayout(LayoutExpansion parentLayoutExpansion);

  /// Should return true if the layout strategy rotates labels during the
  /// current reLayout.
  /// This is needed by paint methods to rotate canvas.
  bool get isRotateLabelsReLayout;

  /// For tilted labels, this is the forward rotation matrix
  /// to apply on both Canvas AND label envelope's topLeft offset's coordinate
  /// (pivoted on origin, once all chart offsets are applied to label).
  /// This is always the inverse of [_labelTiltMatrix].
  /// Just passed down to [LabelContainer]s.
  vector_math.Matrix2 get canvasTiltMatrix => vector_math.Matrix2.identity();

  /// Angle by which labels are tilted.
  /// Just passed down to [LabelContainer]s.
  vector_math.Matrix2 get labelTiltMatrix => vector_math.Matrix2.identity();

  /// In addition to the rotation matrices, hold on radians for canvas rotation.
  double get labelTiltRadians => 0.0;

  /// Always showing first label, and after, label on every nth dimension point.
  /// Allows to "thin" labels to fit.
  int get showEveryNthLabel => 1;

  double get labelFontSize;
}
