import 'dart:math' as math show min, max;
// import 'package:flutter_charts/flutter_charts.dart';
// import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/model/new_data_model.dart';

import 'util_dart.dart' as util_dart;
import 'test/generate_test_data_from_app_runs.dart';
import '../chart/container.dart' show ChartBehavior;

// todo-00-last-last-last-last : move to NewDataModel

/// Creates, transforms (e.g. to log values), scales to Y axis pixels, and formats the Y labels.
///
/// The Y labels are kept in the [labelInfos] member in all forms - raw, transformed, scaled, and raw formatted.
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

  /// Coordinates of the Y axis.
  /// todo-00-last-last-last REMOVE THIS, AND PASS TO SCALING ONLY. MAKES THIS INDEPENDENT OF ANY PIXEL VALUES.
  // todo-00-last-last-last : final util_dart.Interval _axisY;

  /// Keeps the transformed, non-scaled data values at which labels are shown.
  /// [YContainer.labelInfos] are created from them first, and scaled to pixel values during [ChartRootContainer.layout].
  /// todo-00-last-last-last : make private
  late final List<double> yLabelPositions;
  final bool isAxisAndLabelsInverse = false; // On Y axis, positions go up, but axis down. Will scale inverse.

  /// The function converts value to label.
  ///
  /// Assigned from a corresponding function [ChartOptions.yContainerOptions.valueToLabel].
  final Function _valueToLabel;

  /// The function for data inverse transform.
  ///
  /// Assigned from a corresponding function [ChartOptions.dataContainerOptions.yInverseTransform].
  final Function _yInverseTransform;

  /// Maintains values of labels.
  // todo-00-last-last-last : moved to YContainer, as this contains layout pixel positions. late List<LabelInfo> labelInfos;

  /// Generative constructor allows to create labels.
  ///
  /// If [yUserLabels] list of user labels is passed, user labels will be used and distributed linearly between the
  /// passed [dataYs] minimum and maximum.
  /// Otherwise, new labels are automatically generated with values of
  /// highest order of numeric values in the passed [dataYs].
  /// See the class comment for examples of how auto labels are created.
  YLabelsCreatorAndPositioner({
    // todo-00-last-last-last : required util_dart.Interval axisY,
    required bool startYAxisAtDataMinAllowed,
    required Function valueToLabel,
    required Function yInverseTransform,
    this.yUserLabels,
    NewDataModel? newDataModelForFunction,
    bool? isStacked,
  })  : // todo-00-last-last-last : _axisY = axisY,
        _valueToLabel = valueToLabel,
        _yInverseTransform = yInverseTransform,
        _newDataModelForFunction = newDataModelForFunction,
        _isStacked = isStacked {
    // hack for tests to not have to change. todo-011 : fix in tests
    _isStacked ??= false;

    // List<double> yLabelPositions;
    util_dart.Interval dataYsEnvelope;

    // Find the interval for Y values (may be an envelop around values, for example if we want Y to always start at 0),
    //   then create labels evenly distributed in the Y values interval.
    if (isUsingUserLabels) {
      dataYsEnvelope = _newDataModelForFunction!.dataValuesInterval(isStacked: _isStacked!);
      yLabelPositions = util_dart.evenlySpacedValuesIn(interval: dataYsEnvelope, pointsCount: yUserLabels!.length);
    } else {
      dataYsEnvelope = _newDataModelForFunction!.extendedDataValuesInterval(startYAxisAtDataMinAllowed: startYAxisAtDataMinAllowed, isStacked: _isStacked!);
      yLabelPositions = util_dart.generateValuesForLabelsIn(interval: dataYsEnvelope, startYAxisAtDataMinAllowed: startYAxisAtDataMinAllowed);
    }
    // Create LabelInfos for all labels and point each to this scaler
    // todo-00-last-last : move creation from model to when YContainer is created. createLabelInfos(yLabelPositions);

    // Once LabelInfos are prepared, we can store the merged interval
    // All values are calculated using the [NewDataModel] methods! That proves sameness nicely
    // dataYsOfLabels : not-scaled && transformed data from labelInfo.transformedDataValue
    mergedIntervalsFromLabelsAndValues = util_dart.Interval(
      yLabelPositions.reduce(math.min),
      yLabelPositions.reduce(math.max),
    ).merge(dataYsEnvelope);

    // Format and scale the labels we just created
    // todo-00-last-last-last : must be moved in layout or build, as we need pixels for scaling
    // formatAndScaleLabels();
  }

  // todo-00-last : document
  LabelInfos createLabelInfos() {
    List<LabelInfo> labelInfos = yLabelPositions // this is the label/DataYs enveloper - all values after transform
        .map((transformedLabelValue) => LabelInfo(
              dataValue: transformedLabelValue,
              parentYScaler: this,
            ))
        .toList();
    return LabelInfos(
      from: labelInfos,
      isAxisAndLabelsInverse: isAxisAndLabelsInverse,
    );
  }

/*
  // todo-00-last-last-last rename to : layoutGeneratedLabelPointsAndFormatLabels
  void formatAndScaleLabels({
    required double axisPixelsYMin,
    required double axisPixelsYMax,
  }) {
    for (int i = 0; i < labelInfos.length; i++) {
      LabelInfo labelInfo = labelInfos[i];
      // Scale labels
      // todo-00-last-last-last-last : We cannot do this until we know Y axis pixels!!! 
      labelInfo._scaleLabelValue(axisPixelsYMin: axisPixelsYMin, axisPixelsYMax: axisPixelsYMax, ); // This sets labelInfo._axisValue = YScaler.scaleY(labelInfo.transformedDataValue)
    
      // Format labels takes a different form in user labels
      if (isUsingUserLabels) {
        labelInfo._formattedLabel = yUserLabels![i];
      } else {
        labelInfo._formattedLabel = _valueToLabel(labelInfo._rawDataValue);
      }
    }
  }
*/

  bool get isUsingUserLabels => yUserLabels != null;

  /// Scales [value]
  /// - From own scale, given be the merged data and label intervals
  ///   calculated in [_mergedLabelYsIntervalWithDataYsEnvelope]
  /// - To the Y axis scale defined by [_axisYMin], [_axisYMax].
  /// todo-00-last-last-last : added the axis pixels to which to scale
  double scaleY({
    required double value,
    required double axisPixelsYMin,
    required double axisPixelsYMax,
    required bool isInverse,
  }) {
    // Use linear scaling utility to scale from data Y interval to axis Y interval
    // todo-00-last-last-last : pull out of this class
    return util_dart.scaleValue(
      value: value.toDouble(),
      fromDomainMin: mergedIntervalsFromLabelsAndValues.min,
      fromDomainMax: mergedIntervalsFromLabelsAndValues.max,
      // todo-00-last-last-last toDomainNewMax: _axisY.max,
      // todo-00-last-last-last toDomainNewMin: _axisY.min,
      toDomainNewMin: isInverse ? axisPixelsYMax : axisPixelsYMin,
      toDomainNewMax: isInverse ? axisPixelsYMin : axisPixelsYMax,
    );
  }

  // ### Helper accessors to collection of LabelInfos

  /// Extracts not-scaled && transformed values where labels from [labelInfos] are positioned.
  // todo-00-last-last : moved : List<double> get dataYsOfLabels => labelInfos.map((labelInfo) => labelInfo._dataValue.toDouble()).toList();

  // todo-00-last-last-last : added the 4 getters for a quick access by the new scaler
  double get fromDomainMin => mergedIntervalsFromLabelsAndValues.min;
  double get fromDomainMax => mergedIntervalsFromLabelsAndValues.max;
  // used in new scaling within NewDataContainer coordinates!! So make sure it starts with 0.0 and
  // length is same as constraint size given to NewDataContainer.
   // todo-00-last-last-last double get toDomainMin => 0.0;
   // todo-00-last-last-last double get toDomainMax => _axisY.max - _axisY.min;
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
  void _scaleLabelValue({
    required double axisPixelsYMin,
    required double axisPixelsYMax,
    required bool isInverse,
  }) {
    // todo-02 consider what to do about the toDouble() - ensure higher up so if parent scaler not set by now, scaledLabelValue remains null.
    // todo-00-last-last
    // todo-00-last-last-last : _axisValue = _parentYScaler.scaleY(value: _dataValue.toDouble());
    _pixelPositionOnAxis = _parentYScaler.scaleY(
        value: _dataValue.toDouble(),
        axisPixelsYMin: axisPixelsYMin,
        axisPixelsYMax: axisPixelsYMax,
        isInverse: isInverse,
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
class LabelInfos {
  LabelInfos({
    required List<LabelInfo> from,
    required bool isAxisAndLabelsInverse,
  })  : _labelInfoList = from,
        _isAxisAndLabelsInverse = isAxisAndLabelsInverse;

  final List<LabelInfo> _labelInfoList;
  Iterable<LabelInfo> get labelInfoList => List.from(_labelInfoList, growable: false);
  final bool _isAxisAndLabelsInverse;

  // todo-00-last-last-last rename to : layoutGeneratedLabelPointsAndFormatLabels
  // todo-00-last-last : merge to constructor
  void formatLabels({
    required YLabelsCreatorAndPositioner yLabelsCreatorAndPositioner
  }) {
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

  void scaleLabels({
    required double axisPixelsYMin,
    required double axisPixelsYMax,
  }) {
    for (int i = 0; i < _labelInfoList.length; i++) {
      LabelInfo labelInfo = _labelInfoList[i];
      // Scale labels
      // todo-00-last-last-last-last : We cannot do this until we know Y axis pixels!!!
      // This sets labelInfo._axisValue = YScaler.scaleY(labelInfo.transformedDataValue)
      labelInfo._scaleLabelValue(
        axisPixelsYMin: axisPixelsYMin,
        axisPixelsYMax: axisPixelsYMax,
        isInverse: _isAxisAndLabelsInverse,
      );
    }
  }
  List<double> get dataYsOfLabels => labelInfoList.map((labelInfo) => labelInfo._dataValue.toDouble()).toList();

}