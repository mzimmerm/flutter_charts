import 'dart:math' as math show min, max, pow;

// import '../../flutter_charts.dart';
import '../chart/container_layouter_base.dart';
import '../chart/model/data_model_new.dart';
import '../chart/container.dart';
import '../chart/options.dart';
import '../chart/view_maker.dart';

import 'util_dart.dart' as util_dart;
import 'util_labels.dart' as util_labels;

// todo-doc-01 documentation fix, this is old
/// Generates label values from data values, and allows label manipulation: transform, format, extrapolate to axis pixels.
///
/// During construction, decides how many labels will be created, and generates points on which the labels
/// will be placed (these points are also values of the labels).
///
/// All values, including the [AxisLabelInfo]s are calculated using [NewModel].
///
/// The labels are managed in the [labelInfos] member in all forms - raw, transformed, scaled, and raw formatted.
///
class DataRangeLabelInfosGenerator {

  /// Generative constructor allows to create and manage labels, irrespective whether user defined, or generated
  /// by this [DataRangeLabelInfosGenerator].
  ///
  /// If [userLabels] list of user labels is passed, user labels will be used and distributed linearly between the
  /// passed [dataModel] minimum and maximum.
  /// Otherwise, new labels are automatically generated with values of
  /// highest order of numeric values in the passed [dataModel].
  ///
  /// Parameters discussion:
  ///
  /// - [dataModel] contains the numeric data values, passed to constructor.
  ///   An envelope is created from the [dataModel] values, possibly extending the envelope interval to start or end at 0.
  ///   Whether the envelope interval starts or ends at 0.0, even if data are away from 0.0, is controlled by member
  ///   [extendAxisToOrigin].
  /// - [userLabels] may be set by user.
  /// - [_labelInfos] and [dataRange] are created from [dataMode] for only the highest order of values
  ///   in [dataModel], and can be both wider or narrower than extremes of the [dataModel].
  ///     1. Ex1. for [dataModel] values [-600.0 .. 2200.0]
  ///             ==> [labelInfos] =   [-1000, 0, 1000, 2000] (NARROWER THAN dataModel max 2200)
  ///             ==> [dataRange] = [-600 .. 2200]
  ///     2. Ex2. for [dataModel] values  [0.0 .. 1800.0]
  ///             ==> [labelInfos]   = [0, 1000, 2000]
  ///             ==> [dataRange] = [0 .. 2000] (WIDER than dataModel max 1800)
  ///
  /// Constructor calculates the following members:
  ///   - [dataRange]
  ///   - [_labelInfos]


  DataRangeLabelInfosGenerator({
    required this.chartViewMaker, // todo-00-last : added as a temporary to test old vs new
    required NewModel dataModel,
    required bool extendAxisToOrigin,
    required Function valueToLabel,
    required Function inverseTransform,
    required bool isStacked,
    required this.isAxisPixelsAndDisplayedValuesInSameDirection,
    List<String>? userLabels,
  })  :
        _valueToLabel = valueToLabel,
        _inverseTransform = inverseTransform
  {
    util_dart.Interval dataEnvelope;

    // Finds the [dataRange] interval for data values
    //   (which may be an envelop around values, for example if we want to always start at 0),
    //   then creates [_labelInfos] labels evenly distributed in the [dataRange] interval.
    // Both local [dataEnvelope] and member [dataRange]
    //   are **not-extrapolated && transformed** data from [NewModelPoint].
    if (userLabels != null) {
      dataEnvelope = dataModel.dataValuesInterval(isStacked: isStacked);
      _transformedLabelValues = util_labels.evenlySpacedValuesIn(interval: dataEnvelope, pointsCount: userLabels.length);
    } else {
      dataEnvelope = dataModel.extendedDataValuesInterval(extendAxisToOrigin: extendAxisToOrigin, isStacked: isStacked);
      _transformedLabelValues = util_labels.generateValuesForLabelsIn(interval: dataEnvelope, extendAxisToOrigin: extendAxisToOrigin);
    }

    // Store the merged interval of values and label envelope for [AxisLabelInfos] creation
    // that can be created immediately after by invoking [createAxisLabelInfos].
    dataRange = util_dart.Interval(
      _transformedLabelValues.reduce(math.min),
      _transformedLabelValues.reduce(math.max),
    ).merge(dataEnvelope);

    // Format and extrapolate labels from the [_labelPositions] local to the [_labelInfos] member.
    List<AxisLabelInfo> labelInfos = _transformedLabelValues
        .map((transformedLabelValue) =>
        AxisLabelInfo(
          dataValue: transformedLabelValue,
          labelsGenerator: this,
        ))
        .toList();
    _labelInfos = _AxisLabelInfos(
      from: labelInfos,
      labelsGenerator: this,
      userLabels: userLabels,
    );

  }

  final ChartViewMaker chartViewMaker; // todo-00-last : added as a temporary to test old vs new


  /// Describes labels - their values and String values.
  /// Important note: [_AxisLabelInfos] should NOT be part of model,
  ///                 as different views would have a different instance of it.
  ///                 Reason: Different views may have different labels, esp. on the axis.
  late final _AxisLabelInfos _labelInfos;

  /// List describes the labels generated by [DataRangeLabelInfosGenerator],
  /// or all user defined labels from [userLabels].
  ///
  /// User labels from [userLabels], if set, are used, otherwise, the generated labels are used.
  /// The labels are always ordered - numerically increasing by value for numerical
  /// labels, or in the order initialized by user in [userLabels].
  ///
  /// The labels are always in increasing order: For data labels, they are numerically increasing,
  /// for user labels, their order given by user is considered ordered the same order as provided.
  ///
  List<AxisLabelInfo> get labelInfoList => List.from(_labelInfos._labelInfoList, growable: false);


  /// The numerical range of data.
  ///
  /// Calculated in the constructor, from [NewModelPoint]s.
  /// as the merged outer interval of generated labels and [NewModelPoint] values.
  ///
  /// This [Interval] is displayed on the axis pixel domain [AxisContainer.axisPixelsRange].
  /// Extrapolation is done between those intervals.
  late final util_dart.Interval dataRange;

  /// [_transformedLabelValues] keep the transformed, non-extrapolated data values at which labels are shown.
  // todo-00!!! Remove this member and getter entirely. Must address tests first, easy
  late final List<double> _transformedLabelValues;

  /// Public getter is for tests only!
  List<double> get testTransformedLabelValues => _transformedLabelValues;


  // Along the Y axis, label values go up, but axis down. true extrapolate inverses that.
  final bool isAxisPixelsAndDisplayedValuesInSameDirection;

  /// The function converts value to label.
  ///
  /// Assigned from a corresponding function [ChartOptions.yContainerOptions.valueToLabel].
  final Function _valueToLabel;

  /// The function for data inverse transform.
  ///
  /// Assigned from a corresponding function [ChartOptions.dataContainerOptions.yInverseTransform].
  final Function _inverseTransform;

  /// Extrapolates [value] from extended data range [dataRange],
  /// to the pixels domain passed in the passed [axisPixelsMin], [axisPixelsMax],
  /// in the direction defined by [isAxisAndLabelsSameDirection].
  ///
  /// Lifecycle: This method must be invoked in or after [BoxLayouter.layout],
  ///            after the axis size is calculated.
  double lextrValueToPixels({
    required double value,
    required double axisPixelsMin,
    required double axisPixelsMax,
  }) {
    // todo-00-last : added as a confirmation
    if (!chartViewMaker.isUseOldDataContainer) {
      throw StateError('Only should be called in OLD Layouters');
    }

    // Special case, if _labelsGenerator.dataRange=(0.0,0.0), there are either no data, or all data 0.
    // Lerp the result to either start or end of the axis pixels, depending on [isAxisAndLabelsSameDirection]
    if (dataRange == const util_dart.Interval(0.0, 0.0)) {
      double pixels;
      if (!isAxisPixelsAndDisplayedValuesInSameDirection) {
        pixels = axisPixelsMax;
      } else {
        pixels = axisPixelsMin;
      }
      return pixels;
    }
    // lextr the data value range [dataRange] on this [DataRangeLabelInfosGenerator] to the pixel range.
    // The pixel range must be the pixel range available to axis after [BoxLayouter.layout].
    return util_dart.ToPixelsExtrapolation1D(
      fromValuesMin: dataRange.min,
      fromValuesMax: dataRange.max,
      toPixelsMin: axisPixelsMin,
      toPixelsMax: axisPixelsMax,
      doInvertToDomain: !isAxisPixelsAndDisplayedValuesInSameDirection,
    ).apply(value);
  }

  /// Creates an instance of [ExternalTicksLayoutProvider] from self.
  ///
  /// As this [DataRangeLabelInfosGenerator] holds on everything about relative (data ranged)
  /// position of labels, it can be converted to a provider of these label positions
  /// for layouts that use externally defined positions to layout their children.
  ExternalTicksLayoutProvider asExternalTicksLayoutProvider({
    required ExternalTickAtPosition externalTickAtPosition,
  }) {
    // Return [ExternalTicksLayoutProvider] and provide ticks.
    // The ticks must be lextered to pixels, once ticksPixelsDomain is known.
    // See [RollingPositioningExternalTicksBoxLayouter].
    return ExternalTicksLayoutProvider(
      tickValues: labelInfoList.map((labelInfo) => labelInfo.dataValue).toList(growable: false),
      tickValuesDomain: dataRange,
      isAxisPixelsAndDisplayedValuesInSameDirection: isAxisPixelsAndDisplayedValuesInSameDirection,
      externalTickAtPosition: externalTickAtPosition,
    );
  }
}

/// The [AxisLabelInfo] is a holder for one label,
/// it's numeric values (raw, transformed, transformed and extrapolated)
/// and the displayed label String.
///
/// It does not hold anything at all to do with UI - no layout sizes of labels in particular.
///
/// The values used and shown on the chart undergo the following processing:
///    1. [_rawDataValue] -- using [DataContainerOptions.yTransform] (or [DataContainerOptions.xTransform])
///       ==> [_dataValue] (transformed)
///    2. [_dataValue]    -- using [DataRangeLabelInfosGenerator.lextrValueToPixels]
///       ==> [parentOffsetTick]
///    3. [_rawDataValue] -- using formatted String-value
///       ==> [_formattedLabel]
///
/// todo-01-doc below finish documentation, this stuff is old, and simplify
/// The last mapping in item 3. is using either `toString` if [DataRangeLabelInfosGenerator.userLabels] are used,
/// or [DataRangeLabelInfosGenerator._valueToLabel] for chart-generated labels.
///
/// There are four values each [AxisLabelInfo] manages:
/// 1. The [_rawDataValue] : The value of dependent (y) variable in data, given by
///   the [DataRangeLabelInfosGenerator._mergedLabelYsIntervalWithdataEnvelope].
///   - This value is **not-transformed && not-extrapolated**.
///   - This value is in the interval extended from the interval of minimum and maximum data values (x or y)
///     to the interval of the displayed labels. The reason is the chart may show axis lines and labels
///     beyond the strict interval between minimum and maximum in data.
///   - This value is created in the generative constructor's [AxisLabelInfo]
///     initializer list from the [transformedDataValue].
/// 2. The [_dataValue] : The [_rawDataValue] after transformation by the [DataContainerOptions.yTransform]
///   function.
///   - This value is **not-extrapolated && transformed**
///   - This value is same as [_rawDataValue] if the [DataContainerOptions.yTransform]
///     is an identity (this is the default behavior). See [lib/chart/options.dart].
///   - This value is passed in the primary generative constructor [AxisLabelInfo].
/// 3. The [parentOffsetTick] :  Equals to the **transformed && extrapolated** dataValue, in other words
///   ```dart
///    _axisValue = labelsGenerator.scaleY(value: transformedDataValue.toDouble());
///   ```
///   It is created as extrapolated [_dataValue], in the [PointsColumns]
///   where the extrapolation is from the Y data and labels envelop to the Y axis envelop.
///   - This value is **transformed and extrapolated**.
///   - This value is obtained as follows
///     ```dart
///        _axisValue = labelsGenerator.scaleY(value: transformedDataValue.toDouble());
///        // which does
///        return extrapolateValue(
///            value: value.toDouble(),
///            fromDomainMin: mergedLabelYsIntervalWithDataYsEnvelop.min.toDouble(),
///            fromDomainMax: mergedLabelYsIntervalWithDataYsEnvelop.max.toDouble(),
///            toDomainMin: _axisYMin,
///            toDomainMax: _axisYMax);
///     ```
/// 4. The [_formattedLabel] : The formatted String-value of [_rawDataValue].
///
/// Note: The **not-transformed && extrapolated** value is NOT used - does not make sense.
///
/// Note:  **Data displayed inside the chart use transformed data values, displayed labels show raw data values.**
///
class AxisLabelInfo {

  /// Constructs from value at the label, holding on the owner [labelsGenerator],
  /// which provides data range corresponding to axis range.
  AxisLabelInfo({
    required num dataValue,
    required DataRangeLabelInfosGenerator labelsGenerator,
  })  : _dataValue = dataValue,
        _labelsGenerator = labelsGenerator {
    var yInverseTransform = _labelsGenerator._inverseTransform;
    _rawDataValue = yInverseTransform(_dataValue);
  }

  final DataRangeLabelInfosGenerator _labelsGenerator;

  /// Not-extrapolated and not-transformed label value.
  ///
  /// This is only used in labels display, never to calculate or display data values.
  /// All data values calculations are using the [_dataValue].
  late final num _rawDataValue;

  /// The transformed [_rawDataValue].
  ///
  /// In non-transferred (e.g. non-log) charts, this is equal to [_rawDataValue].
  ///
  /// This is the value shown on the chart, before any scaling to pixel value.
  final num _dataValue;
  double get dataValue => _dataValue.toDouble();

  /// Label showing on the Y axis; typically a value with unit.
  ///
  /// Formatted label is just formatted [parentOffsetTick].
  late final String _formattedLabel;
  String get formattedLabel => _formattedLabel;

  @override
  String toString() {
    return ' dataValue=$_rawDataValue,'
        ' transformedDataValue=$_dataValue,'
        ' _formattedLabel=$_formattedLabel,';
  }
}

/// A wrapper for the list of [AxisLabelInfo]s shown on an axis.
///
/// Stores the list of labels as [_AxisLabelInfos] created by [DataRangeLabelInfosGenerator].
///
/// During creation from the `List<LabelInfo>` argument [from] ,
/// formats the labels using each [AxisLabelInfo]'s own formatter.
class _AxisLabelInfos {
  _AxisLabelInfos({
    required List<AxisLabelInfo> from,
    required DataRangeLabelInfosGenerator labelsGenerator,
    List<String>? userLabels,
  })  : _labelInfoList = from
  {
    // Format labels during creation
    for (int i = 0; i < _labelInfoList.length; i++) {
      AxisLabelInfo labelInfo = _labelInfoList[i];
      // If labels were set by user in [userLabels], their formatted value [_formattedLabel]
      //   is set to the user String without formatting or mangling.
      // Otherwise, labels are the raw data values previously generated
      //   by [DataRangeLabelInfosGenerator], formatted by applying the [_valueToLabel]
      if (userLabels != null) {
        labelInfo._formattedLabel = userLabels[i];
      } else {
        labelInfo._formattedLabel = labelsGenerator._valueToLabel(labelInfo._rawDataValue);
      }
    }
  }

  final List<AxisLabelInfo> _labelInfoList;
}

// ########################## Functions ##########################

util_dart.Interval extendToOrigin(util_dart.Interval interval, bool extendAxisToOrigin) {
  if (interval.min - util_dart.epsilon > interval.max) {
    throw StateError('Min < max on interval $interval');
  }
  if (extendAxisToOrigin) {
    return util_dart.Interval(
      interval.min >= 0.0 ? math.min(0.0, interval.min) : interval.min,
      interval.max >= 0.0 ? math.max(0.0, interval.max) : 0.0,
    );
  }
  return interval;
}

/// Evenly places [pointsCount] positions in [interval], starting at [interval.min],
/// ending at [interval.max], and returns the positions list.
///
/// The positions include both ends, unless [pointsCount] is one, then the positions at ends
/// are not included, list with center position is returned.
///
/// As this method simply divides the available interval into [pointsCount],
/// it is not relevant whether the interval is translated or extrapolated or not, as long as it is linear
/// (which it would be even for logarithmic scale). But usually the interval represents
/// scaled, non-transformed values.
List<double> evenlySpacedValuesIn({
  required util_dart.Interval interval,
  required int pointsCount,
}) {
  if (pointsCount <= 0) {
    throw StateError('Cannot distribute 0 or negative number of positions');
  }

  if (pointsCount == 1) {
    return [(interval.max - interval.min) / 2.0];
  }
  double dataStepHeight = (interval.max - interval.min) / (pointsCount - 1);

  // Evenly distribute labels in [interval]
  List<double> pointsPositions = List.empty(growable: true);
  for (int yIndex = 0; yIndex < pointsCount; yIndex++) {
    pointsPositions.add(interval.min + dataStepHeight * yIndex);
  }
  return pointsPositions;
}

/// Automatically generates values (anywhere from zero to nine values) intended to
/// be displayed as label in [interval], which represents a domain
///
/// More precisely, all generated label values are inside, or slightly protruding from,
/// the passed [interval], which was created as tight envelope of all data values.
///
/// As the values are generated from [interval], the values us whatever is the
/// [interval]'s values scale and transform. Likely, the [interval] represents
/// transformed but non-extrapolated values.
///
/// The label values power is the same as the greatest power
/// of the passed number [interval.end], when expanded to 10 based power series.
///
/// Precision is 1 (that is, only leading digit is non-zero, rest are zeros).
///
/// Examples:
///   1. [util_dart.Interval] is <0, 123> then labels=[0, 100]
///   2. [util_dart.Interval] is <0, 299> then labels=[0, 100, 200]
///   3. [util_dart.Interval] is <0, 999> then labels=[0, 100, 200 ... 900]
///
/// Further notes and related topics:
///   - Labels are encapsulated in the [DataRangeLabelInfosGenerator],
///     which creates [AxisLabelInfo]s for all generated labels.
///   - The [axisYMin] and [axisYMax] define the top and the bottom of the Y axis in the canvas coordinate system.
///
List<double> generateValuesForLabelsIn({
  required util_dart.Interval interval,
  required bool extendAxisToOrigin,
}) {
  var polyMin = util_dart.Poly(from: interval.min);
  var polyMax = util_dart.Poly(from: interval.max);

  int powerMax = polyMax.maxPower;
  int coeffMax = polyMax.coefficientAtMaxPower;
  int signMax = polyMax.signum;

  // using Min makes sense if one or both (min, max) are negative
  int powerMin = polyMin.maxPower;
  int coeffMin = polyMin.coefficientAtMaxPower;
  int signMin = polyMin.signum;

  List<double> labels = [];
  int power = math.max(powerMin, powerMax);

  if (signMax <= 0 && signMin <= 0 || signMax >= 0 && signMin >= 0) {
    // both negative or positive
    if (signMax <= 0) {
      double startCoeff = 1.0 * signMin * coeffMin;
      int endCoeff = 0;
      if (!extendAxisToOrigin) {
        endCoeff = signMax * coeffMax;
      }
      for (double l = startCoeff; l <= endCoeff; l++) {
        labels.add(l * math.pow(10, power));
      }
    } else {
      // signMax >= 0
      double startCoeff = 1.0 * 0;
      int endCoeff = signMax * coeffMax;
      if (!extendAxisToOrigin) {
        startCoeff = 1.0 * coeffMin;
      }
      for (double l = startCoeff; l <= endCoeff; l++) {
        labels.add(l * math.pow(10, power));
      }
    }
  } else {
    // min is negative, max is positive - need added logic
    if (powerMax == powerMin) {
      for (double l = 1.0 * signMin * coeffMin; l <= signMax * coeffMax; l++) {
        labels.add(l * math.pow(10, power));
      }
    } else if (powerMax < powerMin) {
      for (double l = 1.0 * signMin * coeffMin; l <= 1; l++) {
        // just one over 0
        labels.add(l * math.pow(10, power));
      }
    } else if (powerMax > powerMin) {
      for (double l = 1.0 * signMin * 1; l <= signMax * coeffMax; l++) {
        // just one under 0
        labels.add(l * math.pow(10, power));
      }
    } else {
      throw Exception('Unexpected power: $powerMin, $powerMax ');
    }
  }

  // Check if positions are fully inside interval - probably not, which is fine
  return labels;
}
