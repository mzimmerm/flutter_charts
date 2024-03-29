import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'dart:math' as math show pi;

// this level or equivalent
import 'package:flutter_charts/src/chart/cartesian/container/container_common.dart';
import 'package:flutter_charts/src/chart/options.dart' show ChartOptions;
import 'package:flutter_charts/src/morphic/container/constraints.dart';


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
/// When the [layout] finds labels overlap, the following steps are taken
/// to achieve "fit" of labels: [LabelFitMethod.rotateLabels],
/// [LabelFitMethod.decreaseLabelFont] and [LabelFitMethod.skipLabels].
///
/// The steps are repeated at most [maxLabelReLayouts] times.
/// If a "fit" is not achieved on last step, the last step is repeated
/// until [maxLabelReLayouts] is reached.
class DefaultIterativeLabelLayoutStrategy extends LabelLayoutStrategy {
  /// Constructor uses default values from [ChartOptions]
  // todo-04 : Move all re-layout specific settings from options to DefaultIterativeLabelLayoutStrategy
  //                But they still need to default from options or somewhere?
  //                Also try use as a mixin
  DefaultIterativeLabelLayoutStrategy({
    required ChartOptions options,
  })  : _decreaseLabelFontRatio = options.iterativeLayoutOptions.decreaseLabelFontRatio,
        _showEveryNthLabel = options.iterativeLayoutOptions.showEveryNthLabel,
        _maxLabelReLayouts = options.iterativeLayoutOptions.maxLabelReLayouts,
        _multiplyLabelSkip = options.iterativeLayoutOptions.multiplyLabelSkip,
        // labelCommonOptions.labelFontSize and labelColor now set in LabelCommonOptions.get labelTextStyle
        _labelFontSize = options.labelCommonOptions.labelTextStyle.fontSize!,
        _labelTiltRadians = options.iterativeLayoutOptions.labelTiltRadians;
  
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

  /// Matrix representing rotation by the angle by which labels are tilted.
  /// 
  /// For tilted labels, this is the forward rotation matrix
  /// to apply on both Canvas AND label envelope's topLeft offset's coordinate
  /// (pivoted on origin, once all chart offsets are applied to label).
  /// Just passed down to [LabelContainer]s.
  vector_math.Matrix2 _labelTiltMatrix = vector_math.Matrix2.identity();

  @override
  vector_math.Matrix2 get labelTiltMatrix => _labelTiltMatrix;
  
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
  /// If labels in the [_adjustableLabelsContainer] overlap, this method takes the
  /// next prescribed auto-layout action - one of the actions defined in the
  /// [LabelFitMethod] enum (DecreaseLabelFont, RotateLabels,  SkipLabels)
  ///
  @override
  void reLayout(BoxContainerConstraints boxConstraints) {
    if (!_adjustableLabelsContainer.labelsOverlap()) {
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

    // A recursive [layout] is needed after the above code did some changes to the
    //   [HorizontalAxisContainer _adjustableLabelsContainer]. The changes might have been decreased font,
    //   changed label tilt, or asking some labels not to be shown.
    // The recursively called [layout] rebuilds all children of the [HorizontalAxisContainer _adjustableLabelsContainer],
    //   with the changed state above (font, tilt, or asking less labels to be shown).
    // The rebuild must be the same build called on [HorizontalAxisContainer] in [ChartRootContainer.layout].
    // Because the _adjustableLabelsContainer is HorizontalAxisContainer, it is also the EnableBuildAndAddChildrenLateOnBoxContainer.
    _adjustableLabelsContainer.layout();


    // Return to caller, which is always [layout]. [layout] will call this [reLayout] iteratively
    // if another [reLayout] is needed, up to [_atDepth] iterations.
  }

  /// Prepares the rotation matrix [_labelTiltMatrix] for tilting labels.
  /// 
  /// The matrix will be used by the [_adjustableLabelsContainer] to tilt it's labels.
  void _reLayoutRotateLabels() {
    //  angle must be in interval `<-math.pi, +math.pi>`
    if (!(-1 * math.pi <= _labelTiltRadians && _labelTiltRadians <= math.pi)) {
      throw StateError('angle must be between -PI and +PI');
    }
    
    // Make the tilt matrix from the rotation angle
    _labelTiltMatrix = vector_math.Matrix2.rotation(_labelTiltRadians);
    
  }

  void _reLayoutDecreaseLabelFont() {
    // Reinitialize the tilt matrix, as previous tilt iteration may have set a rotation.
    _labelTiltMatrix = vector_math.Matrix2.identity();

    // Decrease font (already init-ted from options), and call layout again
    _labelFontSize *= _decreaseLabelFontRatio;
  }

  void _reLayoutSkipLabels() {
    // Reinitialize the tilt matrix, as previous tilt iteration may have set a rotation.
    _labelTiltMatrix = vector_math.Matrix2.identity();
    
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
/// - Skip every 2nd label
/// - Tilt all labels
/// - Decrease label font size
abstract class LabelLayoutStrategy {
  late AdjustableLabelsChartAreaContainer _adjustableLabelsContainer;

  LabelLayoutStrategy();

  void onContainer(AdjustableLabelsChartAreaContainer adjustableLabelsContainer) {
    _adjustableLabelsContainer = adjustableLabelsContainer;
  }

  /// Core of the auto layout strategy.
  ///
  /// Typically called from the [Container]'s [Container.layout]
  /// method to achieve iterative layout.
  ///
  /// Implementations should either not do anything (OnePassLayoutStrategy),
  /// or check for [_adjustableLabelsContainer]'s labels overlap. On overlap,
  /// it should set some values on [_adjustableLabelsContainer]'s labels to
  /// make them smaller, less dense, tilt, skip etc, and call
  /// the [Container.layout] iteratively.
  void reLayout(BoxContainerConstraints boxConstraints);

  /// Should return true if the layout strategy rotates labels during the
  /// current reLayout.
  /// This is needed by paint methods to rotate canvas.
  bool get isRotateLabelsReLayout;

  /// Rotation matrix corresponding to the angle by which labels are tilted.
  /// 
  /// Identity for horizontal labels.
  /// Just passed down to [LabelContainer]s.
  vector_math.Matrix2 get labelTiltMatrix => vector_math.Matrix2.identity();

  /// In addition to the rotation matrices, hold on radians for canvas rotation.
  double get labelTiltRadians => 0.0;

  /// Always showing first label, and after, label on every nth dimension point.
  /// Allows to "thin" labels to fit.
  int get showEveryNthLabel => 1;

  double get labelFontSize;
}
