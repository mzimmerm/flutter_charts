import 'package:flutter_charts/src/chart/container.dart'
    show Container, AdjustableContentChartAreaContainer;
import 'package:flutter_charts/src/chart/options.dart' show ChartOptions;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'dart:math' as math show pi;

enum LabelFitMethod { RotateLabels, DecreaseLabelFont, SkipLabels }

/// Strategy of achieving that labels "fit" on the X axis.
///
/// Strategy defines a sequence of steps, each performing a specific strategy
/// to achieve X labels fit, currently, [LabelFitMethod.RotateLabels],
/// [LabelFitMethod.DecreaseLabelFont] and [LabelFitMethod.SkipLabels].
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
  // todo-00-last : how come the members do not need neither late, nor init to 0.0?
  double _labelFontSize;

  double get labelFontSize => _labelFontSize;

  /// In addition to the rotation matrices, hold on radians for canvas rotation.
  double _labelTiltRadians;

  double get labelTiltRadians => _labelTiltRadians;

  bool _isRotateLabelsReLayout = false;

  bool get isRotateLabelsReLayout => _isRotateLabelsReLayout;

  int _reLayoutsCounter = 0;
  int _showEveryNthLabel = 0;

  int get showEveryNthLabel => _showEveryNthLabel;

  /// On multiple auto layout iterations, every new iteration skips more labels.
  /// every iteration, the number of labels skipped is multiplied by
  /// [_multiplyLabelSkip]. For example, if on first layout,
  /// [_showEveryNthLabel] was 3, and labels still overlap, on the next re-layout
  /// the  [_showEveryNthLabel] would be `3 * _multiplyLabelSkip`.
  int _multiplyLabelSkip;

  int _maxLabelReLayouts;

  double _decreaseLabelFontRatio;

  /// For tilted labels, this is the forward rotation matrix
  /// to apply on both Canvas AND label envelope's topLeft offset's coordinate
  /// (pivoted on origin, once all chart offsets are applied to label).
  /// This is always the inverse of [_labelTiltMatrix].
  /// Just passed down to [LabelContainer]s.
  vector_math.Matrix2 _canvasTiltMatrix = new vector_math.Matrix2.identity();

  vector_math.Matrix2 get canvasTiltMatrix => _canvasTiltMatrix;

  /// Angle by which labels are tilted.
  /// Just passed down to [LabelContainer]s.
  vector_math.Matrix2 _labelTiltMatrix = new vector_math.Matrix2.identity();

  vector_math.Matrix2 get labelTiltMatrix => _labelTiltMatrix;

  /// Constructor uses default values from [ChartOptions]
  DefaultIterativeLabelLayoutStrategy({
    required ChartOptions options,
  })   : _decreaseLabelFontRatio = options.decreaseLabelFontRatio,
        _showEveryNthLabel = options.showEveryNthLabel,
        _maxLabelReLayouts = options.maxLabelReLayouts,
        _multiplyLabelSkip = options.multiplyLabelSkip,
        _labelFontSize = options.labelFontSize,
        _labelTiltRadians = options.labelTiltRadians;

  LabelFitMethod _atDepth(int depth) {
    switch (depth) {
      case 1:
        return LabelFitMethod.RotateLabels;
      // todo-00-last-removed-dead-code: break;
      case 2:
        return LabelFitMethod.SkipLabels;
      // todo-00-last-removed-dead-code: break;
      case 3:
        return LabelFitMethod.DecreaseLabelFont;
      // todo-00-last-removed-dead-code: break;
      case 4:
        return LabelFitMethod.DecreaseLabelFont;
      // todo-00-last-removed-dead-code: break;
      default:
        return LabelFitMethod.SkipLabels;
      // todo-00-last-removed-dead-code: break;
    }
  }

  /// Core of the auto layout strategy.
  ///
  /// If labels in the [_container] overlap, this method takes the
  /// next prescribed auto-layout action - one of the actions defined in the
  /// [LabelFitMethod] enum (DecreaseLabelFont, RotateLabels,  SkipLabels)
  ///
  void reLayout() {
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
      case LabelFitMethod.DecreaseLabelFont:
        _reLayoutDecreaseLabelFont();
        break;
      case LabelFitMethod.RotateLabels:
        _reLayoutRotateLabels();
        _isRotateLabelsReLayout = true;
        break;
      case LabelFitMethod.SkipLabels:
        _reLayoutSkipLabels();
        break;
    }
    _container.layout(); // will call this function back!

    // print("Iterative layout finished after $_reLayoutsCounter iterations.");
  }

  void _reLayoutRotateLabels() {
    //  angle must be in interval `<-math.pi, +math.pi>`
    if (!(-1 * math.pi <= _labelTiltRadians && _labelTiltRadians <= math.pi)) {
      throw new StateError("angle must be between -PI and +PI");
    }

    _makeTiltMatricesFromTiltRadians();
  }

  void _makeTiltMatricesFromTiltRadians() {
    _canvasTiltMatrix = new vector_math.Matrix2.rotation(_labelTiltRadians);
    // label is actually tilted in the direction when canvas is rotated back,
    //   so the label tilt is inverse of the canvas tilt
    _labelTiltMatrix = new vector_math.Matrix2.rotation(-_labelTiltRadians);
  }

  void _reLayoutDecreaseLabelFont() {
    // Decrease font (already init-ted from options), and call layout again
    _labelFontSize *= this._decreaseLabelFontRatio;
  }

  void _reLayoutSkipLabels() {
    // Most advanced; Keep list of labels, but only display every nth
    this._showEveryNthLabel *= this._multiplyLabelSkip;
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
  late AdjustableContentChartAreaContainer _container;

  LabelLayoutStrategy();

  void onContainer(AdjustableContentChartAreaContainer container) {
    this._container = container;
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
  void reLayout();

  /// Should return true if the layout strategy rotates labels during the
  /// current reLayout.
  /// This is needed by paint methods to rotate canvas.
  bool get isRotateLabelsReLayout;

  /// For tilted labels, this is the forward rotation matrix
  /// to apply on both Canvas AND label envelope's topLeft offset's coordinate
  /// (pivoted on origin, once all chart offsets are applied to label).
  /// This is always the inverse of [_labelTiltMatrix].
  /// Just passed down to [LabelContainer]s.
  vector_math.Matrix2 get canvasTiltMatrix =>
      new vector_math.Matrix2.identity();

  /// Angle by which labels are tilted.
  /// Just passed down to [LabelContainer]s.
  vector_math.Matrix2 get labelTiltMatrix => new vector_math.Matrix2.identity();

  /// In addition to the rotation matrices, hold on radians for canvas rotation.
  double get labelTiltRadians => 0.0;

  /// Always showing first label, and after, label on every nth dimension point.
  /// Allows to "thin" labels to fit.
  int get showEveryNthLabel => 1;

  double get labelFontSize;
}
