import 'dart:math' as math show min, max, pow;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/util/test/generate_test_data_from_app_runs.dart';
import 'util_dart.dart' as util_dart;

// todo-00-later-document
/// Creates, scales, and formats the Y labels, all the way
/// from the transformed data to their positions and displayed strings on the Y axis.
///
/// Objects of this class are created in [Range.makeAutoLayoutYScalerWithLabelInfosFromDataYsOnScale].
///
///    - There are two members relevant in the creating and formatting labels
///       - [dataYsEnvelop]
///          Required to be passed in constructor, is the envelope of data, possibly extended to 0.
///            e.g. dataRange= [-600.0, 1800.0]  from data [-600.0 ....  1800.0]
///       - [labelInfos]
///         A list of labels with additional info.
///         This list is created in the constructor to cover the interval [dataYsEnvelop]
///         deduced from [labelYsInDataYsEnvelope] passed in constructor, previously
///         created by [Range.distributeLabelsIn()] method
///           The labelInfos may contain e.g. four labels: [-1000, 0, 1000, 2000]
///    - From the two members, the [mergedLabelYsIntervalWithDataYsEnvelop] can be calculated as a merge
///      of the [labelInfos] envelop and the [dataYsEnvelop]. The [mergedLabelYsIntervalWithDataYsEnvelop]
///      serves as the '(transformed) data range' - all (transformed) data are located in this range;
///      from this range, the data values and label positions are scaled to the Y axis scale.
///            e.g. [-1000, 2000]
class YScalerAndLabelFormatter {
  List<String>? yUserLabels;
  
  // todo-00-later-document
  final List<double> _dataYs;

  /// [dataYsEnvelop] are created from the [StackableValuePoint.toY] by the [PointsColumns.flattenPointsValues()].
  /// The [StackableValuePoint]s are located on [PointsColumns], then [PointsColumn.stackableValuePoints].
  /// Pseudocode of the [dataYsEnvelop] creation:
  ///   ```
  ///   - YContainer.layout
  ///     - YContainer.layoutAutomatically
  ///       - YContainer._layoutCreateYScalerFromPointsColumnsData(axisYMin, axisYMax)
  ///         - dataYs = _chartTopContainer.pointsColumns.flattenPointsValues()
  ///         - new Range(values: dataYs, options)
  ///         - yScaler = Range.makeYScalerWithLabelInfosFromDataYsOnScale(axisYMin: axisYMin, axisYMax: axisYMax,)
  ///           - This creates the distributed labels as follows:
  ///             - distributedLabelYs = Range.distributeLabelsIn(Interval(dataYsMinExtendedTo0, dataYsMaxExtendedTo0,))
  ///               - So the labels are distributed in the TRANSFORMED dataYMin, dataYMax (maybe extended)
  ///             - yScaler = YScalerAndLabelFormatter(
  ///                 dataYsEnvelop: Interval(dataYsMinExtendedTo0, dataYsMaxExtendedTo0),
  ///                 labelYsInDataYsEnvelope: distributedLabelYs,
  ///                 axisYMin: axisYMin,
  ///                 axisYMax: axisYMax,
  ///                 chartOptions: _options);
  ///           - In the end, the yScaler scales from the (extended) dataYMin - dataYMax to the axisYMin - axisYMax. So, given a label's raw value, it will display the raw value, which is what we want.
  // todo-00-later-document
  late Interval dataYsEnvelop;
  
  /// Maintains labels created from data values, scaled and unscaled.
  late List<LabelInfo> labelInfos;
  
  final Interval _axisY;
  
  final ChartOptions _options;

  // TODO-00-LAST : MAKE ALL METHODS PRIVATE.
  YScalerAndLabelFormatter({
    required List<double> dataYs,
    required Interval axisY,
    required ChartOptions chartOptions,
    this.yUserLabels,
  })  : _dataYs = dataYs,
        _axisY = axisY,
        _options = chartOptions {
    
    List<double> distributedLabelYs;
    // Find the interval for Y values (may be an envelop around values, for example if we want Y to always start at 0),
    //   then create labels evenly distributed in the Y values interval.
    if (isUsingUserLabels) {
      dataYsEnvelop = _deriveDataYsEnvelopForUserLabels() ;
      distributedLabelYs = _distributeUserLabelsIn(dataYsEnvelop);
    } else {
      dataYsEnvelop = _deriveDataYsEnvelopForAutoLabels();
      distributedLabelYs = _distributeAutoLabelsIn(dataYsEnvelop);
    }
    // Create LabelInfos for all labels and point each to this scaler
    labelInfos = distributedLabelYs  // this is the label/DataYs enveloper - all values after transform
        .map((transformedLabelValue) => LabelInfo(
      transformedDataValue: transformedLabelValue,
      parentYScaler: this,
    )).toList();

    // Format and scale the labels we just created
    for (int i = 0; i < labelInfos.length; i++) {
      LabelInfo labelInfo = labelInfos[i];
      // Scale labels
      labelInfo._scaleLabelValue(); // This sets labelInfo.axisValue = YScaler.scaleY(labelInfo.transformedDataValue)

      // Format labels takes a different form in user labels
      if (isUsingUserLabels) {
        labelInfo.formattedLabel = yUserLabels![i];
      } else {
        labelInfo.formattedLabel = _options.yContainerOptions.valueToLabel(labelInfo.dataValue);
      }
    }
    
    // This test is always true. Should address in the bigger context
    if (_axisY.min > _axisY.max) {
      // we are inverting scales, so invert labels.
      labelInfos = labelInfos.reversed.toList();
    }
    
    // Collect data for testing. Disabled in production
    collectTestData(
        'for_Range.makeYScalerWithLabelInfosFromDataYsOnScale_test',
        [
          _dataYs,
          axisY.min,
          axisY.max,
          distributedLabelYs,
          dataYsEnvelop.min,
          dataYsEnvelop.max,
        ],
        this);
  }
  
  bool get isUsingUserLabels => yUserLabels != null;

  /// Scales [value]
  ///   - from own scale, given be the merged data and label intervals
  ///   calculated in [mergedLabelYsIntervalWithDataYsEnvelop]
  ///   - to the Y axis scale defined by [_axisYMin], [_axisYMax].
  double scaleY({
    required double value,
  }) {
    // Use linear scaling utility to scale from data Y interval to axis Y interval
    return util_dart.scaleValue(
        value: value.toDouble(),
        fromDomainMin: mergedLabelYsIntervalWithDataYsEnvelop.min.toDouble(),
        fromDomainMax: mergedLabelYsIntervalWithDataYsEnvelop.max.toDouble(),
        toDomainMin: _axisY.min,
        toDomainMax: _axisY.max);
  }
  
  // ### Helper accessors to collection of LabelInfos

  /// Extracts not-scaled && transformed values where labels from [labelInfos] are positioned.
  List<double> get dataYsOfLabels => labelInfos.map((labelInfo) => labelInfo.transformedDataValue.toDouble()).toList();

  /// Constructs interval which is a merge (outer bound) of
  /// two ranges: the labels range [dataYsOfLabels] (calculated from [YScalerAndLabelFormatter] [LabelInfo.transformedDataValue.])
  /// and the [dataYsEnvelop] which is also transformed data. Both are not-scaled && transformed.
  ///
  // TODO-00-LAST : IS THIS ACTUALLY NEEDED? MAYBE THE SCALING IS RIGHT WITHOUT THIS? 
  Interval get mergedLabelYsIntervalWithDataYsEnvelop => Interval(
        dataYsOfLabels.reduce(math.min), // not-scaled && transformed data from  labelInfo.transformedDataValue
        dataYsOfLabels.reduce(math.max),
      ).merge(dataYsEnvelop); // dataY from PointsColumns, which is also not-scaled && transformed, data

  /// Derive the interval of dataY values, by default extended to start at 0 (all positive values),
  /// or end at 0 (all negative values).
  Interval _deriveDataYsEnvelopForAutoLabels() {
    
    double dataYsMin = _dataYs.reduce(math.min);
    double dataYsMax = _dataYs.reduce(math.max);

    Poly polyMin = Poly(from: dataYsMin);
    Poly polyMax = Poly(from: dataYsMax);

    int signMin = polyMin.signum;
    int signMax = polyMax.signum;

    // Minimum and maximum for all y values, by DEFAULT EXTENDED TO 0.
    // More precisely, "extended to 0" means that
    //   if all y values are positive,
    //     the range start at 0 (that is, dataYsMinExt is 0);
    //   else if all y values are negative,
    //     the range ends at 0 (that is, dataYsMaxExt is 0);
    //   otherwise [there are both positive and negative y values]
    //     the dataYsMinExt is the minimum of data, the dataYsMaxExt is the maximum of data.
    double dataYsMinExt, dataYsMaxExt;

    if (signMax <= 0 && signMin <= 0 || signMax >= 0 && signMin >= 0) {
      if (_options.startYAxisAtDataMinAllowed) {
        if (signMax <= 0) {
          dataYsMinExt = dataYsMin;
          dataYsMaxExt = dataYsMax;
        } else {
          dataYsMinExt = dataYsMin;
          dataYsMaxExt = dataYsMax;
        }
      } else {
        // both negative or positive, extend the range to start or end at zero
        if (signMax <= 0) {
          dataYsMinExt = dataYsMin;
          dataYsMaxExt = 0.0;
        } else {
          dataYsMinExt = 0.0;
          dataYsMaxExt = dataYsMax;
        }
      }
    } else {
      dataYsMinExt = dataYsMin;
      dataYsMaxExt = dataYsMax;
    }

    // Now create distributedLabelYs, evenly distributed in
    //   the dataYsMinExt, dataYsMaxExt interval.
    // Make distributedLabelYs only in polyMax steps (e.g. 100, 200 - not 100, 110 .. 200).
    // Label values are (obviously) unscaled, that is, on the scale of transformed data.
    return Interval(dataYsMinExt, dataYsMaxExt);
  }

  // todo-00-later document
  Interval _deriveDataYsEnvelopForUserLabels() {
      return Interval(_dataYs.reduce(math.min), _dataYs.reduce(math.max));
  }

  /// Automatically generates labels from data.
  ///
  /// Labels are encapsulated in the created and returned [YScalerAndLabelFormatter],
  /// which manages [LabelInfo]s for all generated labels.
  ///
  /// The [axisYMin] and [axisYMax] define the top and the bottom of the Y axis in the canvas coordinate system.
  
  /// Makes anywhere from zero to nine label values, of greatest power of
  /// the passed [dataYsEnvelop.max].
  ///
  /// Precision is 1 (that is, only leading digit, rest 0s).
  ///
  /// Examples:
  ///   1. [Interval] is <0, 123> then labels=[0, 100]
  ///   2. [Interval] is <0, 299> then labels=[0, 100, 200]
  ///   3. [Interval] is <0, 999> then labels=[0, 100, 200 ... 900]
  ///
  List<double> _distributeAutoLabelsIn(Interval dataYsEnvelop) {
    Poly polyMin = Poly(from: dataYsEnvelop.min);
    Poly polyMax = Poly(from: dataYsEnvelop.max);

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
        if (_options.startYAxisAtDataMinAllowed) {
          endCoeff = signMax * coeffMax;
        }
        for (double l = startCoeff; l <= endCoeff; l++) {
          labels.add(l * math.pow(10, power));
        }
      } else {
        // signMax >= 0
        double startCoeff = 1.0 * 0;
        int endCoeff = signMax * coeffMax;
        if (_options.startYAxisAtDataMinAllowed) {
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

    return labels;
  }

  // todo-00-later-document
  List<double> _distributeUserLabelsIn(Interval dataYsEnvelop) {
    double dataStepHeight = (dataYsEnvelop.max - dataYsEnvelop.min) / (yUserLabels!.length - 1);

    // Evenly distribute labels in [dataYsEnvelop]
    List<double> yLabelsInDataYsEnvelop = List.empty(growable: true);
    for (int yIndex = 0; yIndex < yUserLabels!.length; yIndex++) {
      yLabelsInDataYsEnvelop.add(dataYsEnvelop.min + dataStepHeight * yIndex);
    }
    return yLabelsInDataYsEnvelop;    
  }
}

/// The [LabelInfo] is a holder for one label, it's numeric value and the displayed label.
///
/// There are four values each [LabelInfo] manages:
///   - [dataValue] : The value of dependent (y) variable in data,
///       given by [YScalerAndLabelFormatter.mergedLabelYsIntervalWithDataYsEnvelop].
///       - This value is **not-scaled && not-transformed**.
///       - This value is in the interval extended from the interval of minimum and maximum y in data
///         to the interval of the displayed labels. The reason is the chart may show axis lines and labels
///         beyond the strict interval between minimum and maximum y in data.
///       - This value is created in the generative constructor's [LabelInfo()]
///         initializer list from the [transformedDataValue].
///   - [transformedDataValue] : The [dataValue] after transformation by the [DataContainerOptions.yTransform]
///       function.
///       - This value is **not-scaled && transformed**
///       - This value is same as [dataValue] if the [DataContainerOptions.yTransform]
///         is an [identity()] (this is the default behavior). See [lib/chart/options.dart].
///       - This value is passed in the primary generative constructor [LabelInfo()].
///   - [axisValue] :  Equals to the **scaled && transformed** dataValue, in other words
///       ```dart
///        axisValue = parentYScaler.scaleY(value: transformedDataValue.toDouble());
///       ```
///       It is created as scaled [transformedDataValue], in the [PointsColumns]
///        where the scaling is from the Y data and labels envelop to the Y axis envelop.
///       - This value is **transformed and scaled**.
///       - This value is obtained as follows
///         ```dart
///             axisValue = parentYScaler.scaleY(value: transformedDataValue.toDouble());
///             // which does
///             return util_dart.scaleValue(
///                 value: value.toDouble(),
///                 fromDomainMin: mergedLabelYsIntervalWithDataYsEnvelop.min.toDouble(),
///                 fromDomainMax: mergedLabelYsIntervalWithDataYsEnvelop.max.toDouble(),
///                 toDomainMin: _axisYMin,
///                 toDomainMax: _axisYMax);
///         ```
///
///   - [formattedLabel] : The formatted String-value of [dataValue].
///
/// Note: The **scaled && not-transformed ** value is not maintained.
///
/// Note:  **Data displayed inside the chart use transformed data values, displayed labels show raw data values.**
///
class LabelInfo {
  YScalerAndLabelFormatter parentYScaler;

  /// Not-scaled and not-transformed label value.
  ///
  /// This is only used in labels display, never to calculate or display data values.
  /// All data values calculations are using the [transformedDataValue].
  late num dataValue;

  /// The transformed [dataValue].
  num transformedDataValue;

  /// Scaled label value.
  ///
  /// [axisValue]s are on the scale of y axis length.
  late num axisValue;

  /// Label showing on the Y axis; typically a value with unit.
  ///
  /// Formatted label is just formatted [axisValue].
  late String formattedLabel;

  /// Constructs from value at the label, using scaler which keeps dataRange
  /// and axisRange (min, max).
  LabelInfo({
    required this.transformedDataValue,
    required this.parentYScaler,
  }) {
    var yInverseTransform = parentYScaler._options.dataContainerOptions.yInverseTransform;
    dataValue = yInverseTransform(transformedDataValue);
  }

  /// Scales this [LabelInfo] to the position on the Y axis.
  void _scaleLabelValue() {
    // todo-13 consider what to do about the toDouble() - ensure higher up so if parent scaler not set by now, scaledLabelValue remains null.
    axisValue = parentYScaler.scaleY(value: transformedDataValue.toDouble());
  }

  @override
  String toString() {
    return super.toString() +
        ' dataValue=$dataValue,' +
        ' transformedDataValue=$transformedDataValue,' +
        ' axisValue=$axisValue,' +
        ' formattedLabel=$formattedLabel,';
  }
}

