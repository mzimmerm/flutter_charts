import 'dart:math' as math show min, max, pow;
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/chart/model/new_data_model.dart';

import 'util_dart.dart' as util_dart;
import 'util_labels.dart' as util_labels;

// todo-doc-01 documentation fix, this is old
/// Creates, transforms (e.g. to log values), scales to Y axis pixels, and formats the Y labels.
///
/// During it's construction, decides how many Y labels will be created, and generates points on which the Y labels
/// will be placed (these points are also values of the labels).
///
/// All values are calculated using [NewModel].
///
/// From there, Y [LabelInfo]s are created/// The Y labels are kept in the [labelInfos] member in all forms - raw, transformed, scaled, and raw formatted.
///
/// The following members are most relevant in the creating and formatting labels
/// - [_dataYs] is a list of numeric Y values, passed to constructor.
///   An envelope is created from [_dataYs], possibly extending the closure interval to start or end at 0.
///   1. Ex1. for [_dataYs] [-600.0 ....  2200.0] ==> [dataYsEnvelope] = [-600.0, 2200.0]
///   2. Ex2. for [_dataYs] [600.0 ....  1800.0]  ==> [dataYsEnvelope] = [0.0, 1800.0]
/// - [axisY] is the interval of the Y axis coordinates.
///      e.g. [8.0, 400.0]
/// - [userLabels] may be set by user.
/// - [labelInfos] are labels calculated to represent numeric Y values, ONLY in their highest order.
///   1. Ex1. [labelInfos] ==> [-1000, 0, 1000, 2000] (NOT ending at 2200)
///   2. Ex2. [labelInfos] ==> [0, 1000, 2000]
/// From the members [dataYsEnvelope] and [labelInfos], the [_mergedLabelYsIntervalWithDataYsEnvelope]
/// are calculated. The result serves as the '(transformed) data range'.
/// All (transformed) data and labels are located inside the [_mergedLabelYsIntervalWithDataYsEnvelope]
/// 1. Ex1. for [dataYsEnvelope]=[-600.0, 2200.0] and [labelInfos]=[-1000, 0, 1000, 2000] ==> merged=[-1000, 0, 1000, 2200]
/// 2. Ex2. for [dataYsEnvelope]= [0.0, 1800.0]   and [labelInfos]=[0, 1000, 2000]        ==> merged=[0, 1000, 2000]
class DataRangeLabelsGenerator {

  late final NewModel _dataModel;
  final bool _isStacked;

  /// Stores the merged outer interval of generated labels and point values.
  /// It's values are all calculated from [NewModelPoint]s.
  ///
  /// This is the data domain corresponding to the axis pixel domain
  /// such as [YContainer.axisPixelsRange]. Extrapolation is done between those intervals.
  late final util_dart.Interval dataRange;

  /// User labels on the Y axis.
  ///
  /// If not null, user labels are used instead of generated labels.
  List<String>? userLabels;

  /// Keeps the transformed, non-scaled data values at which labels are shown.
  /// [YContainer.labelInfos] are created from them first, and scaled to pixel values during [ChartRootContainer.layout].
  late final List<double> _labelPositions;

  /// Public getter is for tests only!
  List<double> get labelPositions => _labelPositions;

  // On Y axis, label values go up, but axis down. true scale inverses that.
  final bool isAxisAndLabelsSameDirection = false;

  /// The function converts value to label.
  ///
  /// Assigned from a corresponding function [ChartOptions.yContainerOptions.valueToLabel].
  final Function _valueToLabel;

  /// The function for data inverse transform.
  ///
  /// Assigned from a corresponding function [ChartOptions.dataContainerOptions.yInverseTransform].
  final Function _inverseTransform;

  /// Generative constructor allows to create labels.
  ///
  /// If [userLabels] list of user labels is passed, user labels will be used and distributed linearly between the
  /// passed [dataYs] minimum and maximum.
  /// Otherwise, new labels are automatically generated with values of
  /// highest order of numeric values in the passed [dataYs].
  /// See the class comment for examples of how auto labels are created.
  DataRangeLabelsGenerator({
    required NewModel dataModel,
    required bool extendAxisToOrigin,
    required Function valueToLabel,
    required Function inverseTransform,
    this.userLabels,
    required bool isStacked,
  })  :
        _valueToLabel = valueToLabel,
        _inverseTransform = inverseTransform,
        _dataModel = dataModel,
        _isStacked = isStacked {

    // List<double> yLabelPositions;
    util_dart.Interval dataEnvelope;

    // Find the interval for Y values (may be an envelop around values, for example if we want Y to always start at 0),
    //   then create labels evenly distributed in the Y values interval.
    // Both [dataEnvelope] and member [_yLabelPositions] ,
    // are  not-scaled && transformed data from [NewModelPoint].
    if (isUsingUserLabels) {
      dataEnvelope = _dataModel.dataValuesInterval(isStacked: _isStacked);
      _labelPositions = util_labels.evenlySpacedValuesIn(interval: dataEnvelope, pointsCount: userLabels!.length);
    } else {
      dataEnvelope = _dataModel.extendedDataValuesInterval(extendAxisToOrigin: extendAxisToOrigin, isStacked: _isStacked);
      _labelPositions = util_labels.generateValuesForLabelsIn(interval: dataEnvelope, extendAxisToOrigin: extendAxisToOrigin);
    }

    // Store the merged interval of values and label envelope for [LabelInfos] creation
    // that can be created immediately after by invoking [createLabelInfos].
    dataRange = util_dart.Interval(
      _labelPositions.reduce(math.min),
      _labelPositions.reduce(math.max),
    ).merge(dataEnvelope);
  }

  /// Format and scale the labels from [_labelPositions] created and stored by this instance.
  ///
  /// This method should be invoked in a constructor of a container,
  /// such as [YContainer]. [BoxContainer.layout]. Not dependent on pixels.
  FormattedLabelInfos createLabelInfos() {
    List<LabelInfo> labelInfos = _labelPositions
        .map((transformedLabelValue) => LabelInfo(
              dataValue: transformedLabelValue,
              labelsGenerator: this,
            ))
        .toList();
    return FormattedLabelInfos(
      from: labelInfos,
      labelsGenerator: this,
    );
  }

  bool get isUsingUserLabels => userLabels != null;

  /// Extrapolates [value] from extended data range kept in self [dataRange],
  /// to the pixels domain passed in the passed [axisPixelsYMin], [axisPixelsYMax],
  /// in the direction defined by [isAxisAndLabelsSameDirection].
  ///
  /// This must be called in layout, after the axis size is known.
  double lerpValueToPixels({
    required double value,
    required double axisPixelsYMin,
    required double axisPixelsYMax,
    required bool isAxisAndLabelsSameDirection,
  }) {
    // Special case, if _labelsGenerator.dataRange=(0.0,0.0), there are either no data, or all data 0.
    // Lerp the result to either start or end of the axis pixels, depending on [isAxisAndLabelsSameDirection]
    if (dataRange == const util_dart.Interval(0.0, 0.0)) {
      double pixels;
      if (isAxisAndLabelsSameDirection) {
        pixels = axisPixelsYMax;
      } else {
        pixels = axisPixelsYMin;
      }
      return pixels;
    }
    // lerp the data value on this LabelInfo to the pixel range.
    return util_dart.ToPixelsExtrapolation1D(
      fromValuesMin: dataRange.min,
      fromValuesMax: dataRange.max,
      toPixelsMin: axisPixelsYMin,
      toPixelsMax: axisPixelsYMax,
      doInvertToDomain: isAxisAndLabelsSameDirection,
    ).apply(value);
  }
}

/// The [LabelInfo] is a holder for one label,
/// it's numeric values (raw, transformed, transformed and scaled)
/// and the displayed label.
///
/// It does not hold anything at all to do with UI - no layout sizes of labels in particular.
///
/// The values used and shown on the chart undergo the following processing:
///    [_rawDataValue] -- using [DataContainerOptions.yTransform]         --> [_dataValue] (transformed)
///    [_dataValue]    -- using labelsGenerator.scaleY(value: _dataValue)   --> [_pixelPositionOnAxis] (transformed AND scaled)
///    [_rawDataValue] -- using formatted String-value of [_rawDataValue] --> [_formattedLabel]
/// The last mapping is using either `toString` if [DataRangeLabelsGenerator.userLabels] are used,
/// or [DataRangeLabelsGenerator._valueToLabel] for chart-generated labels.
///
/// There are four values each [LabelInfo] manages:
/// 1. The [_rawDataValue] : The value of dependent (y) variable in data, given by
///   the [DataRangeLabelsGenerator._mergedLabelYsIntervalWithDataYsEnvelope].
///   - This value is **not-scaled && not-transformed**.
///   - This value is in the interval extended from the interval of minimum and maximum y in data
///     to the interval of the displayed labels. The reason is the chart may show axis lines and labels
///     beyond the strict interval between minimum and maximum y in data.
///   - This value is created in the generative constructor's [LabelInfo]
///     initializer list from the [transformedDataValue].
/// 2. The [_dataValue] : The [_rawDataValue] after transformation by the [DataContainerOptions.yTransform]
///   function.
///   - This value is **not-scaled && transformed**
///   - This value is same as [_rawDataValue] if the [DataContainerOptions.yTransform]
///     is an identity (this is the default behavior). See [lib/chart/options.dart].
///   - This value is passed in the primary generative constructor [LabelInfo].
/// 3. The [_pixelPositionOnAxis] :  Equals to the **scaled && transformed** dataValue, in other words
///   ```dart
///    _axisValue = labelsGenerator.scaleY(value: transformedDataValue.toDouble());
///   ```
///   It is created as scaled [_dataValue], in the [PointsColumns]
///   where the scaling is from the Y data and labels envelop to the Y axis envelop.
///   - This value is **transformed and scaled**.
///   - This value is obtained as follows
///     ```dart
///        _axisValue = labelsGenerator.scaleY(value: transformedDataValue.toDouble());
///        // which does
///        return scaleValue(
///            value: value.toDouble(),
///            fromDomainMin: mergedLabelYsIntervalWithDataYsEnvelop.min.toDouble(),
///            fromDomainMax: mergedLabelYsIntervalWithDataYsEnvelop.max.toDouble(),
///            toDomainMin: _axisYMin,
///            toDomainMax: _axisYMax);
///     ```
/// 4. The [_formattedLabel] : The formatted String-value of [_rawDataValue].
///
/// Note: The **scaled && not-transformed ** value is not maintained.
///
/// Note:  **Data displayed inside the chart use transformed data values, displayed labels show raw data values.**
///
class LabelInfo {
  final DataRangeLabelsGenerator _labelsGenerator;

  /// Not-scaled and not-transformed label value.
  ///
  /// This is only used in labels display, never to calculate or display data values.
  /// All data values calculations are using the [_dataValue].
  late final num _rawDataValue;

  /// The transformed [_rawDataValue].
  final num _dataValue;

  /// Scaled label value.
  ///
  /// [_pixelPositionOnAxis]s are on the scale of y axis length.
  late final num _pixelPositionOnAxis;
  num get pixelPositionOnAxis => _pixelPositionOnAxis;

  /// Label showing on the Y axis; typically a value with unit.
  ///
  /// Formatted label is just formatted [_pixelPositionOnAxis].
  late final String _formattedLabel;
  String get formattedLabel => _formattedLabel;

  /// Constructs from value at the label, holding on the owner [labelsGenerator],
  /// which provides data range corresponding to axis range.
  LabelInfo({
    required num dataValue,
    required DataRangeLabelsGenerator labelsGenerator,
  })  : _dataValue = dataValue,
        _labelsGenerator = labelsGenerator {
    var yInverseTransform = _labelsGenerator._inverseTransform;
    _rawDataValue = yInverseTransform(_dataValue);
  }

  @override
  String toString() {
    return super.toString() +
        ' dataValue=$_rawDataValue,' +
        ' transformedDataValue=$_dataValue,' +
        ' _axisValue=$_pixelPositionOnAxis,' +
        ' _formattedLabel=$_formattedLabel,';
  }
}

/// A wrapper for list of [LabelInfo]s.
///
/// Represents list of label values always in increasing order
/// because of the [DataRangeLabelsGenerator] implementation which creates instances of this class.
///
/// During creation from the `List<LabelInfo>` argument [from] ,
/// formats the labels using each [LabelInfo]'s own formatter.
class FormattedLabelInfos {
  FormattedLabelInfos({
    required List<LabelInfo> from,
    required DataRangeLabelsGenerator labelsGenerator,
  })  : _labelInfoList = from
  {
    // Format labels during creation
    for (int i = 0; i < _labelInfoList.length; i++) {
      LabelInfo labelInfo = _labelInfoList[i];
      // Format labels takes a different form in user labels
      if (labelsGenerator.isUsingUserLabels) {
        labelInfo._formattedLabel = labelsGenerator.userLabels![i];
      } else {
        labelInfo._formattedLabel = labelsGenerator._valueToLabel(labelInfo._rawDataValue);
      }
    }
  }

  /// List that manages the list of labels information for all generated or user labels.
  final List<LabelInfo> _labelInfoList;
  Iterable<LabelInfo> get labelInfoList => List.from(_labelInfoList, growable: false);

  /// For each [LabelInfo] use it's [DataRangeLabelsGenerator] to
  /// lerp it's [_dataValue] and place the result on [_pixelPositionOnAxis].
  ///
  /// Must ONLY be invoked after container layout when the axis pixels range (axisPixelsRange)
  /// is determined.
  void layoutByLerpToPixels({
    required double axisPixelsYMin,
    required double axisPixelsYMax,
  }) {
    for (int i = 0; i < _labelInfoList.length; i++) {
      LabelInfo labelInfo = _labelInfoList[i];
      var generator = labelInfo._labelsGenerator;
      // Scale labels
      // This sets labelInfo._axisValue = LabelsGenerator.scaleY(labelInfo.transformedDataValue)
      labelInfo._pixelPositionOnAxis = generator.lerpValueToPixels(
        value: labelInfo._dataValue.toDouble(),
        axisPixelsYMin: axisPixelsYMin,
        axisPixelsYMax: axisPixelsYMax,
        isAxisAndLabelsSameDirection: !generator.isAxisAndLabelsSameDirection,
      );
    }
  }
  List<double> get dataYsOfLabels => labelInfoList.map((labelInfo) => labelInfo._dataValue.toDouble()).toList();

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

/// Derive the interval of [dataY] values for user defined labels.
///
/// This is simply the closure of the [_dataYs] numeric values.
/// The user defined string labels are then distributed in the returned interval.
util_dart.Interval deriveDataEnvelopeForUserLabels(List<double> allDataValues) {
  return util_dart.Interval(allDataValues.reduce(math.min), allDataValues.reduce(math.max));
}

/// Evenly places [pointsCount] positions in [interval], starting at [interval.min],
/// ending at [interval.max], and returns the positions list.
///
/// The positions include both ends, unless [pointsCount] is one, then the positions at ends
/// are not included, list with center position is returned.
///
/// As this method simply divides the available interval into [pointsCount],
/// it is not relevant whether the interval is translated or scaled or not, as long as it is linear
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
/// transformed but non-scaled values.
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
///   - Labels are encapsulated in the [DataRangeLabelsGenerator],
///     which creates [LabelInfo]s for all generated labels.
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
