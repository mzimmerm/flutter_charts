import 'package:flutter_charts/src/chart/container.dart' show XContainer;
import 'package:flutter_charts/src/chart/options.dart' show ChartOptions;
import 'dart:math' as math show PI;

enum LabelFitMethod { RotateLabels, DecreaseLabelFont, SkipLabels }

/// Strategy of achieving that labels "fit" on the X axis.
///
/// Strategy defines a sequence of steps, each performing a specific strategy
/// to achieve X labels fit, currently, [LabelFitMethod.RotateLabels],
/// [LabelFitMethod.DecreaseLabelFont] and [LabelFitMethod.SkipLabels].
///
/// The steps are repeated at most [maxReLayouts] times.
/// If a "fit" is not achieved on last step, the last step is repeated
/// until [maxReLayouts] is reached.
class DefaultIterativeLabelLayoutStrategy {
  XContainer _xContainer;
  ChartOptions _options;

  /// Members related to re-layout (iterative layout).
  /// The values are incremental, each re-layout "accumulates" changes
  /// from previous layouts
  double _labelFontSize;
  int _reLayoutsCounter = 0;
  int _showEveryNthLabel;
  get showEveryNthLabel => _showEveryNthLabel;

  /// On multiple auto layout iterations, every new iteration skips more labels.
  /// every iteration, the number of labels skipped is multiplied by
  /// [_multiplyLabelSkip]. For example, if on first layout,
  /// [_showEveryNthLabel] was 3, and labels still overlap, on the next re-layout
  /// the  [_showEveryNthLabel] would be `3 * _multiplyLabelSkip`.
  int _multiplyLabelSkip;

  int _maxReLayouts;

  double decreaseLabelFontRatio;

  double get labelFontSize => _labelFontSize;

  DefaultIterativeLabelLayoutStrategy({XContainer xContainer, ChartOptions options}) {
    _xContainer = xContainer;
    _options = options;
    decreaseLabelFontRatio = _options.decreaseLabelFontRatio;
    _showEveryNthLabel = _options.showEveryNthLabel;
    _maxReLayouts = _options.maxReLayouts;
    _multiplyLabelSkip = options.multiplyLabelSkip;
  }

  LabelFitMethod _atDepth(int depth) {
    switch (depth) {
      case 1:
        return LabelFitMethod.DecreaseLabelFont;
        break;
      case 2:
        return LabelFitMethod.DecreaseLabelFont;
        break;
      case 3:
        return LabelFitMethod.RotateLabels;
        break;
      case 4:
        return LabelFitMethod.SkipLabels;
        break;
      default:
        return LabelFitMethod.SkipLabels;
    }
  }

  /// Core of the auto layout strategy.
  ///
  /// If labels in the [_xContainer] overlap, this method takes the
  /// next prescribed auto-layout action - one of the actions defined in the
  /// [LabelFitMethod] enum (DecreaseLabelFont, RotateLabels,  SkipLabels)
  ///
  void reLayout() {
    if (!_xContainer.labelsOverlap()) {
      // if there is no ovelap, no more iterative calls
      //   to layout(). Exits from iterative layout.
      return;
    }
    _reLayoutsCounter++;

    if (_reLayoutsCounter > _maxReLayouts) {
      return;
    }

    switch (_atDepth(_reLayoutsCounter)) {
      case LabelFitMethod.DecreaseLabelFont:
        _reLayoutDecreaseLabelFont();
        break;
      case LabelFitMethod.RotateLabels:
        _reLayoutRotateLabels();
        break;
      case LabelFitMethod.SkipLabels:
        _reLayoutSkipLabels();
        break;
    }
    _xContainer.layout(); // will call this function back!

    print("Iterative layout finished after $_reLayoutsCounter iterations.");
  }

  void _reLayoutRotateLabels() {
    double labelTiltRadians = _options.labelTiltRadians;
    //  angle must be in interval `<-math.PI, +math.PI>`
    if (!(-1 * math.PI <= labelTiltRadians && labelTiltRadians <= math.PI)) {
      throw new StateError("angle must be between -PI and +PI");
    }

    _xContainer.makeTiltMatricesFrom(labelTiltRadians);
  }

  void _reLayoutDecreaseLabelFont() {
    // Decrease font and call layout again
    _labelFontSize ??= _options.labelFontSize;
    _labelFontSize *= this.decreaseLabelFontRatio;
  }

  void _reLayoutSkipLabels() {
    // Most advanced; Keep list of labels, but only display every nth
    this._showEveryNthLabel *= this._multiplyLabelSkip;
  }
}
