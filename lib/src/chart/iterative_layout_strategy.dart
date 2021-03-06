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
  // todo-00-nullable-? : added ? // todo-00-nullable-last : this caused the X fonts zero size when _labelFontSize inited to 0.0
  // todo-00-nullable-last-last : this is the  X fonts zero size when _labelFontSize inited to 0.0
  // If _reLayoutDecreaseLabelFont is not called, _labelFontSize is never moved away from 0.0
  double _labelFontSize;

  double get labelFontSize => _labelFontSize;

  /// In addition to the rotation matrices, hold on radians for canvas rotation.
  double _labelTiltRadians; // = 0.0

  double get labelTiltRadians => _labelTiltRadians;

  bool _isRotateLabelsReLayout = false;
  bool get isRotateLabelsReLayout => _isRotateLabelsReLayout;

  int _reLayoutsCounter = 0;
  int _showEveryNthLabel = 0; // todo-00-nullable-added-init-0

  int get showEveryNthLabel => _showEveryNthLabel;

  /// On multiple auto layout iterations, every new iteration skips more labels.
  /// every iteration, the number of labels skipped is multiplied by
  /// [_multiplyLabelSkip]. For example, if on first layout,
  /// [_showEveryNthLabel] was 3, and labels still overlap, on the next re-layout
  /// the  [_showEveryNthLabel] would be `3 * _multiplyLabelSkip`.
  int _multiplyLabelSkip; // = 0 todo-00-nullable-added-init-0

  int _maxLabelReLayouts; //  = 0 todo-00-nullable-added-init-0

  double _decreaseLabelFontRatio; //  = 0.0 todo-00-nullable-added-init-0

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
  }) :
  // todo-00-nullable-removed : this exists in super, set above : _options = options;
  // todo-00-nullable : changed _options to options in all below
        _decreaseLabelFontRatio = options.decreaseLabelFontRatio,
        _showEveryNthLabel = options.showEveryNthLabel,
        _maxLabelReLayouts = options.maxLabelReLayouts,
        _multiplyLabelSkip = options.multiplyLabelSkip,
        // todo-00-nullable-last-added _labelFontSize and _labelTiltRadians
        _labelFontSize = options.labelFontSize,
        _labelTiltRadians = options.labelTiltRadians;
/* todo-00-nullable-removed todo-00-nullable-last-last :
        , super(
          options: options,
        );
*/
  
  LabelFitMethod _atDepth(int depth) {
    switch (depth) {
      case 1:
        return LabelFitMethod.RotateLabels;
        break;
      case 2:
        return LabelFitMethod.SkipLabels;
        break;
      case 3:
        return LabelFitMethod.DecreaseLabelFont;
        break;
      case 4:
        return LabelFitMethod.DecreaseLabelFont;
        break;
      default:
        return LabelFitMethod.SkipLabels;
        break;
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

/* todo-00-nullable-last : made labelTiltRadians a member, and directly used 
  void _reLayoutRotateLabels() {
    double labelTiltRadians = _options.labelTiltRadians;
    //  angle must be in interval `<-math.pi, +math.pi>`
    if (!(-1 * math.pi <= labelTiltRadians && labelTiltRadians <= math.pi)) {
      throw new StateError("angle must be between -PI and +PI");
    }

    _makeTiltMatricesFrom(labelTiltRadians);
  }
*/

  void _reLayoutRotateLabels() {
    //  todo-00-nullable-last double labelTiltRadians = _options.labelTiltRadians;
    //  angle must be in interval `<-math.pi, +math.pi>`
    if (!(-1 * math.pi <= _labelTiltRadians && _labelTiltRadians <= math.pi)) {
      throw new StateError("angle must be between -PI and +PI");
    }

    _makeTiltMatricesFrom(/* todo-00-nullable-last  labelTiltRadians*/);
  }

/* todo-00-nullable-last : made labelTiltRadians a member, and directly used 
  void _makeTiltMatricesFrom(double labelTiltRadians) {
    _labelTiltRadians = labelTiltRadians;
    _canvasTiltMatrix = new vector_math.Matrix2.rotation(_labelTiltRadians);
    // label is actually tilted in the direction when canvas is rotated back,
    //   so the label tilt is inverse of the canvas tilt
    _labelTiltMatrix = new vector_math.Matrix2.rotation(-_labelTiltRadians);
  }
*/

  void _makeTiltMatricesFrom(
      /*todo-00-nullable-last  double labelTiltRadians*/) {
    //  todo-00-nullable-last : _labelTiltRadians = labelTiltRadians;
    _canvasTiltMatrix = new vector_math.Matrix2.rotation(_labelTiltRadians);
    // label is actually tilted in the direction when canvas is rotated back,
    //   so the label tilt is inverse of the canvas tilt
    _labelTiltMatrix = new vector_math.Matrix2.rotation(-_labelTiltRadians);
  }

  void _reLayoutDecreaseLabelFont() {
    // Decrease font and call layout again
    // todo-00-nullable-last : ori : _labelFontSize ??= _options.labelFontSize;

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
  // todo-00-nullable-late : added late
  // todo-00-nullable-removed todo-00-nullable-last-last : late ChartOptions _options;
  late AdjustableContentChartAreaContainer _container;

  LabelLayoutStrategy(
/*  todo-00-nullable-removed todo-00-nullable-last-last :
      {
    required ChartOptions options, // @required
  }
*/
  );

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

  // todo-00-nullable-added
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
