import 'dart:math' as math show min, max;
// import 'package:flutter_charts/flutter_charts.dart';
// import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/model/new_data_model.dart';

import 'util_dart.dart' as util_dart;
import 'test/generate_test_data_from_app_runs.dart';
import '../chart/container.dart' show ChartBehavior;

// todo-00 : not specific to Y labels, although only used there. Generalize.
/// Creates, transforms (e.g. to log values), scales to Y axis pixels, and formats the Y labels.
///
/// During it's construction, decides how many Y labels will be created, and generates points on which the Y labels
/// will be placed (these points are also values of the labels).
///
/// All values are calculated using [NewDataModel].
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
/// - [yUserLabels] may be set by user.
/// - [labelInfos] are labels calculated to represent numeric Y values, ONLY in their highest order.
///   1. Ex1. [labelInfos] ==> [-1000, 0, 1000, 2000] (NOT ending at 2200)
///   2. Ex2. [labelInfos] ==> [0, 1000, 2000]
/// From the members [dataYsEnvelope] and [labelInfos], the [_mergedLabelYsIntervalWithDataYsEnvelope]
/// are calculated. The result serves as the '(transformed) data range'.
/// All (transformed) data and labels are located inside the [_mergedLabelYsIntervalWithDataYsEnvelope]
/// 1. Ex1. for [dataYsEnvelope]=[-600.0, 2200.0] and [labelInfos]=[-1000, 0, 1000, 2000] ==> merged=[-1000, 0, 1000, 2200]
/// 2. Ex2. for [dataYsEnvelope]= [0.0, 1800.0]   and [labelInfos]=[0, 1000, 2000]        ==> merged=[0, 1000, 2000]
class YLabelsCreatorAndPositioner {

  // todo-done-last : hack to get code access to ChartRootContainer, but can be null in tests
  late final NewDataModel? _newDataModelForFunction;
  bool? _isStacked;

  // Stores the merged outer interval from generated labels and point values.
  // Before storing, all calculated from NewDataModelPoints.
  late final util_dart.Interval mergedIntervalsFromLabelsAndValues;

  List<String>? yUserLabels;

  /// Keeps the transformed, non-scaled data values at which labels are shown.
  /// [YContainer.labelInfos] are created from them first, and scaled to pixel values during [ChartRootContainer.layout].
  late final List<double> _yLabelPositions;
  // On Y axis, label values go up, but axis down. true scale inverses that.
  final bool isAxisAndLabelsSameDirection = false;

  /// The function converts value to label.
  ///
  /// Assigned from a corresponding function [ChartOptions.yContainerOptions.valueToLabel].
  final Function _valueToLabel;

  /// The function for data inverse transform.
  ///
  /// Assigned from a corresponding function [ChartOptions.dataContainerOptions.yInverseTransform].
  final Function _yInverseTransform;

  /// Generative constructor allows to create labels.
  ///
  /// If [yUserLabels] list of user labels is passed, user labels will be used and distributed linearly between the
  /// passed [dataYs] minimum and maximum.
  /// Otherwise, new labels are automatically generated with values of
  /// highest order of numeric values in the passed [dataYs].
  /// See the class comment for examples of how auto labels are created.
  YLabelsCreatorAndPositioner({
    required bool startYAxisAtDataMinAllowed,
    required Function valueToLabel,
    required Function yInverseTransform,
    this.yUserLabels,
    NewDataModel? newDataModelForFunction,
    bool? isStacked,
  })  :
        _valueToLabel = valueToLabel,
        _yInverseTransform = yInverseTransform,
        _newDataModelForFunction = newDataModelForFunction,
        _isStacked = isStacked {
    // hack for tests to not have to change. todo-00 : fix in tests
    _isStacked ??= false;

    // List<double> yLabelPositions;
    util_dart.Interval dataYsEnvelope;

    // Find the interval for Y values (may be an envelop around values, for example if we want Y to always start at 0),
    //   then create labels evenly distributed in the Y values interval.
    // Both [dataYsEnvelope] and member [_yLabelPositions] ,
    // are  not-scaled && transformed data from [NewDataModelPoint].
    if (isUsingUserLabels) {
      dataYsEnvelope = _newDataModelForFunction!.dataValuesInterval(isStacked: _isStacked!);
      _yLabelPositions = util_dart.evenlySpacedValuesIn(interval: dataYsEnvelope, pointsCount: yUserLabels!.length);
    } else {
      dataYsEnvelope = _newDataModelForFunction!.extendedDataValuesInterval(startYAxisAtDataMinAllowed: startYAxisAtDataMinAllowed, isStacked: _isStacked!);
      _yLabelPositions = util_dart.generateValuesForLabelsIn(interval: dataYsEnvelope, startYAxisAtDataMinAllowed: startYAxisAtDataMinAllowed);
    }

    // Store the merged interval of values and label envelope for [LabelInfos] creation
    // that can be created immediately after by invoking [createLabelInfos].
    mergedIntervalsFromLabelsAndValues = util_dart.Interval(
      _yLabelPositions.reduce(math.min),
      _yLabelPositions.reduce(math.max),
    ).merge(dataYsEnvelope);

  }

  // todo-00-document
  // Format and scale the labels we just created should be done in layout, where we know Y axis pixel size.
  LabelInfos createLabelInfos() {
    List<LabelInfo> labelInfos = _yLabelPositions // this is the label/DataYs enveloper - all values after transform
        .map((transformedLabelValue) => LabelInfo(
              dataValue: transformedLabelValue,
              parentYScaler: this,
            ))
        .toList();
    return LabelInfos(
      from: labelInfos,
      yLabelsCreatorAndPositioner: this,
    );
  }

  bool get isUsingUserLabels => yUserLabels != null;

  /// Scales [value]
  /// - From own scale, given be the merged data and label intervals
  ///   calculated in [_mergedLabelYsIntervalWithDataYsEnvelope]
  /// - To the Y axis scale defined by [_axisYMin], [_axisYMax].
  double scaleY({ // todo-00-last-last : remove method, call the called extrapolation in place
    required double value,
    required double axisPixelsYMin,
    required double axisPixelsYMax,
    required bool isAxisAndLabelsSameDirection,
  }) {
    // Use linear scaling utility to scale from data Y interval to axis Y interval
    // todo-00-last : Use the new scaling utility
/*
    return util_dart.scaleValue(
      value: value.toDouble(),
      fromDomainMin: mergedIntervalsFromLabelsAndValues.min,
      fromDomainMax: mergedIntervalsFromLabelsAndValues.max,
      toDomainNewMin: isAxisAndLabelsSameDirection ? axisPixelsYMax : axisPixelsYMin,
      toDomainNewMax: isAxisAndLabelsSameDirection ? axisPixelsYMin : axisPixelsYMax,
    );
*/
    return util_dart.ToPixelsExtrapolation1D(
            fromValuesMin: mergedIntervalsFromLabelsAndValues.min,
            fromValuesMax: mergedIntervalsFromLabelsAndValues.max,
            toPixelsMin: axisPixelsYMin,
            toPixelsMax: axisPixelsYMax,
            doInvertToDomain: !isAxisAndLabelsSameDirection)
        .apply(value);
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
///    [_dataValue]    -- using parentYScaler.scaleY(value: _dataValue)   --> [_pixelPositionOnAxis] (transformed AND scaled)
///    [_rawDataValue] -- using formatted String-value of [_rawDataValue] --> [_formattedLabel]
/// The last mapping is using either `toString` if [YLabelsCreatorAndPositioner.yUserLabels] are used,
/// or [YLabelsCreatorAndPositioner._valueToLabel] for chart-generated labels.
///
/// There are four values each [LabelInfo] manages:
/// 1. The [_rawDataValue] : The value of dependent (y) variable in data, given by
///   the [YLabelsCreatorAndPositioner._mergedLabelYsIntervalWithDataYsEnvelope].
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
///    _axisValue = parentYScaler.scaleY(value: transformedDataValue.toDouble());
///   ```
///   It is created as scaled [_dataValue], in the [PointsColumns]
///   where the scaling is from the Y data and labels envelop to the Y axis envelop.
///   - This value is **transformed and scaled**.
///   - This value is obtained as follows
///     ```dart
///        _axisValue = parentYScaler.scaleY(value: transformedDataValue.toDouble());
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
  // todo-00-last : review places and names of YLabelsCreatorAndPositioner _parentYScaler and organize better
  final YLabelsCreatorAndPositioner _parentYScaler;

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

  /// Constructs from value at the label, using scaler which keeps dataRange
  /// and axisRange (min, max).
  LabelInfo({
    required num dataValue,
    required YLabelsCreatorAndPositioner parentYScaler,
  })  : _dataValue = dataValue,
        _parentYScaler = parentYScaler {
    var yInverseTransform = _parentYScaler._yInverseTransform;
    _rawDataValue = yInverseTransform(_dataValue);
  }

  /// Scales this [LabelInfo] to the position on the Y axis.
  void _scaleLabelValue({ // todo-00-last-last-last : remove, just place the called scaleY in place
    required double axisPixelsYMin,
    required double axisPixelsYMax,
    required bool isAxisAndLabelsSameDirection,
  }) {
    _pixelPositionOnAxis = _parentYScaler.scaleY(
        value: _dataValue.toDouble(),
        axisPixelsYMin: axisPixelsYMin,
        axisPixelsYMax: axisPixelsYMax,
      isAxisAndLabelsSameDirection: isAxisAndLabelsSameDirection,
    );
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
/// because of the [YLabelsCreatorAndPositioner] implementation which creates instances of this class.
///
/// During creation, formats the labels using each [LabelInfo]'s own formatter.
class LabelInfos {
  LabelInfos({
    required List<LabelInfo> from,
    required YLabelsCreatorAndPositioner yLabelsCreatorAndPositioner,
  })  : _labelInfoList = from,
        _yLabelsCreatorAndPositioner = yLabelsCreatorAndPositioner {
    // Format labels during creation
    for (int i = 0; i < _labelInfoList.length; i++) {
      LabelInfo labelInfo = _labelInfoList[i];
      // Format labels takes a different form in user labels
      if (yLabelsCreatorAndPositioner.isUsingUserLabels) {
        labelInfo._formattedLabel = yLabelsCreatorAndPositioner.yUserLabels![i];
      } else {
        labelInfo._formattedLabel = yLabelsCreatorAndPositioner._valueToLabel(labelInfo._rawDataValue);
      }
    }
  }

  late final YLabelsCreatorAndPositioner _yLabelsCreatorAndPositioner;
  final List<LabelInfo> _labelInfoList;
  Iterable<LabelInfo> get labelInfoList => List.from(_labelInfoList, growable: false);

  // todo-00-document
  // cannot invoke this until we know Y axis pixels!!!
  void layoutByScalingToPixels({
    required double axisPixelsYMin,
    required double axisPixelsYMax,
  }) {
    for (int i = 0; i < _labelInfoList.length; i++) {
      LabelInfo labelInfo = _labelInfoList[i];
      // Scale labels
      // This sets labelInfo._axisValue = YScaler.scaleY(labelInfo.transformedDataValue)
      labelInfo._scaleLabelValue(
        axisPixelsYMin: axisPixelsYMin,
        axisPixelsYMax: axisPixelsYMax,
        isAxisAndLabelsSameDirection: _yLabelsCreatorAndPositioner.isAxisAndLabelsSameDirection,
      );
    }
  }
  List<double> get dataYsOfLabels => labelInfoList.map((labelInfo) => labelInfo._dataValue.toDouble()).toList();

}