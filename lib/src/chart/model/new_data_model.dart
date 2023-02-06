import 'dart:math' as math show min, max;
import 'dart:ui' as ui show Color;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/chart/new_data_container.dart';
import 'package:flutter_charts/src/util/util_dart.dart' as util_dart;

// todo-done-last-2  Copied from [ChartData], it is a replacement for both legacy [ChartData], [PointsColumns],
//                   and various holders of Y data values, including some parts of [YLabelsCreatorAndPositioner]
/// Notes:
///   - DATA MODEL SHOULD NOT HAVE ACCESS TO ANY OBJECTS THAT HAVE TO DO WITH
///     - SCALING OF MODEL VALUES (does not)
///     - COLORS   (currently does)
///     - LABELS   (currently does)
///     - LEGENDS  (currently does)
///     - OPTIONS  (currently does)
///     THOSE OBJECTS SHOULD BE ACCESSED FROM CONTAINER EXTENSIONS FOR SCALING, OFFSET AND PAINTING.
///
/// Important lifecycle notes:
///   - When [NewDataModel] is constructed, the [ChartRootContainer] is not available.
///     So in constructor, [NewDataModel] cannot be given access to the root container, and it's needed members
///     such as [ChartRootContainer.yLabelsCreator].
// todo-011 make immutable, probably impossible to make const.
class NewDataModel {

  // ================ CONSTRUCTOR NEEDS SOME OLD MEMBERS FOR NOW ====================

  /// todo-011 : Default constructor only assumes [_dataRows] is set,
  /// and assigns default values of [_dataRowsLegends], [_dataRowsColors], [xUserLabels], [yUserLabels].
  ///
  NewDataModel({
    required dataRows,
    required this.xUserLabels,
    required dataRowsLegends,
    required this.chartOptions,
    this.yUserLabels,
    List<ui.Color>? dataRowsColors,
    this.startYAxisAtDataMinAllowedNeededForTesting,
  })
      :
  // Initializing of non-nullable _dataRowsColors which is a non-required argument
  // must be in the initializer list by a non-member function (member methods only in constructor)
        _dataRows = dataRows,
        _dataRowsLegends = dataRowsLegends,
        _dataRowsColors = dataRowsColors ?? dataRowsDefaultColors(dataRows.length)
  {
    validate();

    _dataColumns = _transposeRowsToColumns();

    // Construct one [NewDataModelSeries] for each data row, and add to member [sameXValuesList]
    int columnIndex = 0;
    for (List<double> dataColumn in _dataColumns) {
      sameXValuesList.add(
        NewDataModelSameXValues(
          dataColumn: dataColumn,
          dataModel: this,
          columnIndex: columnIndex++,
        ),
      );
    }
  }

  // NEW CODE =============================================================

  // todo-done-last-1 : added NewDataModel.chartRootContainer and : this is needed because model constructs containers, and containers need the root container.
  // Must be public, as it must be set after creation of this [NewDataModel],
  //   in the root container constructor which is in turn, constructed from this model.
  late ChartRootContainer chartRootContainer; // todo-00 : this cannot be final. By hitting + this was already initialized. Why??? I think we need to always reconstruct everything in chart
  late bool? startYAxisAtDataMinAllowedNeededForTesting;
  // todo-00 move to util and generacise
  /// Transposes, as if across it's top-to-bottom / left-to-right diagonal,
  /// the [_dataRows] 2D array List<List<Object>>, so that
  /// for each row and column index in valid range,
  /// ```dart
  ///   _dataRows[row][column] = transposed[column][row];
  /// ```
  /// The original and transposed example
  /// ```
  ///  // original
  ///  [
  ///    [ 1, A ],
  ///    [ 2, B ],
  ///    [ 3, C ],
  ///  ]
  ///  // transposed
  ///  [
  ///    [ 1, 2, 3 ],
  ///    [ A, B, C ],
  ///  ]
  /// ```
  List<List<double>> _transposeRowsToColumns() {
    List<List<double>> dataColumns = [];
    // Walk length of first row (if exists) and fill all dataColumns assuming fixed size of _dataRows
    if (_dataRows.isNotEmpty) {
      for (int column = 0; column < _dataRows[0].length; column++) {
        List<double> dataColumn = [];
        for (int row = 0; row < _dataRows.length; row++) {
          // Add a row value on the row where dataColumn stands
          dataColumn.add(_dataRows[row][column]);
        }
        dataColumns.add(dataColumn);
      }
    }
    return dataColumns;
  }

  /// List of data sameXValues in the model.
  final List<NewDataModelSameXValues> sameXValuesList = []; // todo-done-last-2 : added for the NewDataModel

  // todo-00-last-last-progress
  //       - after, add on NewDataModel method _newMergedLabelYsIntervalWithDataYsEnvelope:
  //          - for stacked, returns (still legacy) interval LabelYsInterval merged with envelope of columnStackedDataValue
  //       - then the _newMergedLabelYsIntervalWithDataYsEnvelope will be used to set fromDomainMin and fromDomainMax for extrapolation

  /// Returns the minimum and maximum non-scaled, non-transformed (todo-01 : this may be needed) values min and max
  Interval _dataValuesInterval(bool isStacked) {
    if (isStacked) {
      return Interval(
        // reduce, not fold: sameXValuesList.fold(0.0, ((double previous, NewDataModelSameXValues pointsColumn) => math.min(previous, pointsColumn._stackedNegativeValue))),
        sameXValuesList.map((pointsColumn) => pointsColumn._stackedNegativeValue).toList().reduce(math.min),
        sameXValuesList.map((pointsColumn) => pointsColumn._stackedPositiveValue).toList().reduce(math.max),
      );
    } else {
      return Interval(
        sameXValuesList.map((pointsColumn) => pointsColumn._minPointValue).toList().reduce(math.min),
        sameXValuesList.map((pointsColumn) => pointsColumn._maxPointValue).toList().reduce(math.max),
      );
    }
  }

  /// Returns the interval that envelopes all data values in [NewDataModel.dataRows], possibly extended to 0.
  ///
  /// Whether the resulting Interval is extended from the simple min/max of [NewDataModel.dataRows],
  /// is controlled by [NewDataModel.chartRootContainer] getter
  /// mixed to [ChartRootContainer] from [ChartBehavior.startYAxisAtDataMinAllowed],
  Interval dataValuesEnvelope({
    required bool isStacked,
    required bool startYAxisAtDataMinAllowed,
  }) {
    return util_dart.extendToOrigin(
      _dataValuesInterval(isStacked),
      // todo-00-last  : chartRootContainer.startYAxisAtDataMinAllowed,
      startYAxisAtDataMinAllowed,
    );
  }

  // todo-00-last-last-progress
  Interval _newMergedLabelYsIntervalWithDataYsEnvelope(bool startYAxisAtDataMinAllowed) {
    bool _isUsingUserLabels = false;
    if (_isUsingUserLabels) {
      //  dataYsEnvelope = util_dart.deriveDataEnvelopeForUserLabels(_dataYs);
      //  distributedLabelYs = _distributeUserLabelsIn(dataYsEnvelope);
      throw StateError('not implemented');
    } else {
      // dataYsEnvelope = util_dart.deriveDataEnvelopeForAutoLabels(_dataYs, _chartBehavior.startYAxisAtDataMinAllowed);
      // distributedLabelYs = _distributeAutoLabelsIn(dataYsEnvelope);
      return dataValuesEnvelope(
          startYAxisAtDataMinAllowed: startYAxisAtDataMinAllowed,
          isStacked: true,
      );
    }
  }

  List<NewValuesColumnContainer> generateViewChildrenAsNewValuesColumnContainerList() {
    List<NewValuesColumnContainer> chartColumns = [];
    // Iterate the dataModel down, creating NewValuesColumnContainer, then NewValueContainer and return

    for (NewDataModelSameXValues sameXValues in sameXValuesList) {
      // NewValuesColumnContainer valuesColumnContainer =
      chartColumns.add(
        NewValuesColumnContainer(
          chartRootContainer: chartRootContainer,
          backingDataModelSameXValues: sameXValues,
          children: [Column(
              children: sameXValues.generateViewChildrenAsNewValueContainersList().reversed.toList(growable: false),
          )],
          // Give all view columns the same weight - same width if owner will be Row (main axis is horizontal)
          constraintsWeight: const ConstraintsWeight(weight: 1),
        ),
      );
    }
    return chartColumns;
  }



  // OLD CODE =============================================================
  // Legacy stuff below

  // _dataRows[columnIndex][rowIndex]
  /// Data in rows.
  ///
  /// Each row of data represents one data series.
  /// Legends per row are managed by [_dataRowsLegends].
  ///
  final List<List<double>> _dataRows;
  List<List<double>> get dataRows => _dataRows;

  /// Data reorganized from rows to columns.
  late final List<List<double>> _dataColumns;
  List<List<double>> get dataColumns => _dataColumns;

  /// Labels on independent (X) axis.
  ///
  /// It is assumed labels are defined, by the client
  /// and their number is the same as number of points
  /// in each row in [_dataRows].
  final List<String> xUserLabels;

  /// The legends for each row in [_dataRows].
  ///
  /// One Legend String per row.
  /// Alternative name would be "series names".
  final List<String> _dataRowsLegends;
  List<String> get dataRowsLegends => _dataRowsLegends;

  /// User defined labels to be used by the chart, instead of labels auto-generated from data.
  ///
  /// Can be Strings or numbers.
  /// If not null, a "manual" layout is used in the [YContainer].
  /// If null, a "auto" layout is used in the [YContainer].
  ///
  final List<String>? yUserLabels;

  /// Colors corresponding to each data row (series) in [NewDataModel].
  final List<ui.Color> _dataRowsColors;
  List<ui.Color> get dataRowsColors => _dataRowsColors;

  /// Chart options which may affect data validation.
  final ChartOptions chartOptions;

  bool get isUsingUserLabels => yUserLabels != null;

  List<double> get flatten => _dataRows.expand((element) => element).toList();
  double get dataYMax => flatten.reduce(math.max);
  double get dataYMin => flatten.reduce(math.min);

  void validate() {
    //                      But that would require ChartOptions available in NewDataModel.
    if (!(_dataRows.length == _dataRowsLegends.length && _dataRows.length == _dataRowsColors.length)) {
      throw StateError('If row legends are defined, their '
          'number must be the same as number of data rows. '
          ' [_dataRows length: ${_dataRows.length}] '
          '!= [_dataRowsLegends length: ${_dataRowsLegends.length}]. ');
    }
    for (List<double> dataRow in _dataRows) {
      if (!(dataRow.length == xUserLabels.length)) {
        throw StateError('If xUserLabels are defined, their '
            'length must be the same as length of each dataRow'
            ' [dataRow length: ${dataRow.length}] '
            '!= [xUserLabels length: ${xUserLabels.length}]. ');
      }
    }
    // Check explicit log10 used in options. This test does not cover user's explicitly declared transforms.
    if (log10 == chartOptions.dataContainerOptions.yTransform) {
      if (!(dataYMin > 0.0)) {
        throw StateError('Using logarithmic Y scale requires only positive Y data');
      }
    }
  }

}

/// todo-done-last-2 : Replaces PointsColumn
/// Represents a list of data values, in the [NewDataModel].
///
/// As we consider the [NewDataModel] to represent a 2D array 'rows first', rows oriented
/// 'top-to-bottom', columns oriented left-to-right, then:
/// The list of data values in this object represent one column in the 2D array,
/// oriented 'top-to-bottom'. We can also consider the list of data values represented by
/// this object to be created by diagonal transpose of the [NewDataModel._dataRows] and
/// looking at one row in the transpose, left-to-right.
class NewDataModelSameXValues extends Object with DoubleLinkedOwner<NewDataModelPoint> {

  /// Constructor. todo-011 document
  NewDataModelSameXValues({
    required List<double> dataColumn,
    required NewDataModel dataModel,
    required int columnIndex,
  })
      : _dataModel = dataModel,
        _columnIndex = columnIndex {
    // Construct data points from the passed [dataRow] and add each point to member _points
    int rowIndex = 0;
    for (double dataValue in dataColumn) {
      var point = NewDataModelPoint(dataValue: dataValue, ownerSameXValuesList: this, rowIndex: rowIndex);
      _points.add(point);
      rowIndex++;
    }
    // When all points in this sameXValues are constructed and added to [_points], we can double-link the points.
    // We just need one point to start - provided by [DoubleLinkedOwner.firstLinked].
    if (_points.isNotEmpty) {
      firstLinked().linkAll();
    }
    // Once the owned DoubleLinked data points are linked, we can do iteration operations of them, such as stacking.

    // Calculate and initialize stacked point values of this column of points.
    applyOnAllElements(
      _stackPoints,
      this,
    );
  }

  /// Calculates and initializes the final stacked positive and negative values on points.
  _stackPoints(NewDataModelPoint point, unused) {
      if (point.hasPrevious) {
        if (point._dataValue < 0.0) {
          point._stackedNegativeDataValue = point.previous._stackedNegativeDataValue + point._dataValue;
          point._stackedPositiveDataValue = point.previous._stackedPositiveDataValue;
        } else {
          point._stackedPositiveDataValue = point.previous._stackedPositiveDataValue + point._dataValue;
          point._stackedNegativeDataValue = point.previous._stackedNegativeDataValue;
        }
      } else {
        // first element
        if (point._dataValue < 0.0) {
          point._stackedNegativeDataValue = point._dataValue;
          point._stackedPositiveDataValue = 0.0;
        } else {
          point._stackedNegativeDataValue = 0.0;
          point._stackedPositiveDataValue = point._dataValue;
        }
      }
    }

  /// Get the stacked value of this column of points - the sum of all

  /// Owner [NewDataModel] to which this [NewDataModelSameXValues] belongs by existence in
  /// [NewDataModel.sameXValuesList].
  ///
  final NewDataModel _dataModel;
  NewDataModel get dataModel => _dataModel;

  /// Index of this column (sameXValues list) in the [NewDataModel.sameXValuesList].
  ///
  /// Also indexes one column, top-to-bottom, in the two dimensional [NewDataModel.dataRows].
  /// Also indexes one row, left-to-right, in the `transpose(NewDataModel.dataRows)`.
  ///
  /// The data values of this column are stored in the [_points] list,
  /// values and order as in top-to-bottom column in [NewDataModel.dataRows].
  ///
  /// This is needed to access the legacy arrays such as:
  ///   -  [NewDataModel.dataRowsLegends]
  ///   -  [NewDataModel.dataRowsColors]
  final int _columnIndex;

  /// Points of this column (sameXValues.
  ///
  /// The points are needed to provide the [allElements], the list of all [DoubleLinked] elements
  /// owned by this [DoubleLinkedOwner]. 
  /// At the same time, the points are all [NewDataModelPoint] in this column (sameXValues list).
  final List<NewDataModelPoint> _points = [];

  /// Implements the [DoubleLinkedOwner] abstract method which provides all elements for
  /// the owned [DoubleLinked] instances of [NewDataModelPoint].
  @override
  Iterable<NewDataModelPoint> allElements() => _points;

  /// Returns height of this column in terms of data values on points, separately for positive and negative.
  ///
  /// Getters always recalculates, should be cached in new member on column
  double get _stackedPositiveValue => __maxOnPoints((NewDataModelPoint point) => point._stackedPositiveDataValue);
  double get _stackedNegativeValue => __minOnPoints((NewDataModelPoint point) => point._stackedNegativeDataValue);

  double get _minPointValue         => __minOnPoints((NewDataModelPoint point) => point._dataValue);
  double get _maxPointValue         => __maxOnPoints((NewDataModelPoint point) => point._dataValue);

  //double __stackedPositive(NewDataModelPoint point) => point._stackedPositiveDataValue;
  //double __stackedNegative(NewDataModelPoint point) => point._stackedNegativeDataValue;

  double __maxOnPoints(double Function(NewDataModelPoint) getNumFromPoint) {
    return __applyFoldableOnPoints(getNumFromPoint, math.max);
  }

  double __minOnPoints(double Function(NewDataModelPoint) getNumFromPoint) {
    return __applyFoldableOnPoints(getNumFromPoint, math.min);
  }

  /// Apply the fold performed by [foldable] (double, double) => double function,
  /// on some double values from the owned [allElements] which are [DoubleLinked] and [NewDataModelPoint]s.
  ///
  /// The double values are pulled from each [NewDataModelPoint]
  /// using the [getNumFromPoint] (NewDataModelPoint) => double function.
  ///
  double __applyFoldableOnPoints(
    double Function(NewDataModelPoint) getNumFromPoint,
    double Function(double, double) foldable,
  ) {
    _DoubleValue result = _DoubleValue();
    applyOnAllElements(
      (NewDataModelPoint point, result) {
        if (!point.hasPrevious) {
          result.value = getNumFromPoint(point);
        } else {
          result.value = foldable(result.value as double, getNumFromPoint(point));
        }
        // print('result = ${result.value}');
      },
      result,
    );
    return result.value;
  }

  /// Generates [NewValueContainer] view from each [NewDataModelPoint]
  /// and collects the views in a list which is returned.
  List<NewValueContainer> generateViewChildrenAsNewValueContainersList() {
    List<NewValueContainer> columnPointContainers = [];

    // Generates [NewValueContainer] view from each [NewDataModelPoint]
    // and collect the views in a list which is returned.
    applyOnAllElements(
      (NewDataModelPoint element, dynamic columnPointContainers) =>
          columnPointContainers.add(element.generateViewChildrenAsNewValueContainer()),
      columnPointContainers,
    );

    return columnPointContainers;
  }
}

class _DoubleValue {
  double value = 0.0;
}

/// Represents one data point. Replaces the legacy [StackableValuePoint].
///
/// Notes:
///   - Has private access to the owner [NewDataModel] to which it belongs through it's member [ownerSameXValuesList]
///     which in turn has access to [NewDataModel] through it's member [NewDataModelSameXValues._dataModel].
///     THIS ACCESS IS CURRENTLY UNUSED
///
class NewDataModelPoint extends Object with DoubleLinked {

  // ===================== CONSTRUCTOR ============================================
  // todo-011 document
  NewDataModelPoint({
    required double dataValue,
    required this.ownerSameXValuesList,
    required int rowIndex,
  })  : _dataValue = ownerSameXValuesList._dataModel.chartOptions.dataContainerOptions.yTransform(dataValue).toDouble(),
        _rowIndex = rowIndex {
    // The ownerSeries is NewDataModelSeries which is DoubleLinkedOwner
    // of all [NewDataModelPoint]s, managed by [DoubleLinkedOwner.allElements]
    doubleLinkedOwner = ownerSameXValuesList;
    // By the time a NewDataModelPoint is constructed, DataModel and it's ownerSameXValuesList INDEXES are configured
    assertDoubleResultsSame(
      ownerSameXValuesList._dataModel.chartOptions.dataContainerOptions
          .yTransform(ownerSameXValuesList.dataModel._dataRows[_rowIndex][ownerSameXValuesList._columnIndex])
          .toDouble(),
      _dataValue,
    );
  }

  // ===================== NEW CODE ============================================

  /// The original (transformed, not-scaled) data value from one data item
  /// in the two dimensional, rows first, [NewDataModel.dataRows].
  ///
  /// This [_dataValue] point is created from the [NewDataModel.dataRows] using the indexes:
  ///   - row at index [_rowIndex]
  ///   - column at the [ownerSameXValuesList] index [NewDataModelSameXValues._columnIndex].
  ///  Those indexes are also a way to access the original for comparisons and asserts in the algorithms.
  final double _dataValue;

  double get dataValue => _dataValue;

  late final double _stackedPositiveDataValue;
  late final double _stackedNegativeDataValue;

  /// Refers to the row index in [NewDataModel.dataRows] from which this point was created.
  ///
  /// Also, this point object is kept in [NewDataModelSameXValues._points] index [_rowIndex].
  ///
  /// See [_dataValue] for details of the column index from which this point was created.
  final int _rowIndex;

  /// References the data column (sameXValues list) this point belongs to
  NewDataModelSameXValues ownerSameXValuesList;

  NewValueContainer generateViewChildrenAsNewValueContainer() {
    return NewValueHBarContainer(
        dataModelPoint: this,
        chartRootContainer: ownerSameXValuesList._dataModel.chartRootContainer);
  }

  ui.Color get color => ownerSameXValuesList._dataModel._dataRowsColors[_rowIndex];

  // ====================== LEGACY CODE ====================================

  /* removed legacy code completely

  // ### 1. Group 1, initial values, but also includes [dataY] in group 2
  String xLabel;

  /// The transformed but NOT stacked Y data value.
  /// **ANY [dataYs] are 1. transformed, then 2. potentially stacked IN PLACE, then 3. potentially scaled IN A COPY!!**
  double dataY;

  /// The index of this point in the [PointsColumn] containing this point in it's
  /// [PointsColumn.newDataModelPoints] list.
  int dataRowIndex; // series index

  /// The predecessor point in the [PointsColumn] containing this point in it's
  /// [PointsColumn.newDataModelPoints] list.
  NewDataModelPoint? predecessorPoint;

  /// True if data are stacked.
  bool isStacked = false;

  // ### 2. Group 2, are data-values representing this point's numeric value.

  /// The stacked-data-value where this point's Y value starts.
  /// [fromY] and [toY] receive their value as follows:
  /// ```dart
  ///    fromY = predecessorPoint != null ? predecessorPoint!.toY : 0.0;
  ///    toY = fromY + dataY;
  /// ```
  /// This value is NOT coordinate based, so [applyParentOffset] is never applied to it.
  double fromY;

  /// The stacked-data-value where this point's Y value ends.
  /// See [fromY] for details.
  double toY;

  // ### 3. Group 3, are the scaled-coordinates - copy-converted from members from group 2,
  //        by scaling group 2 members to the container coordinates (display coordinates)

  /// The [scaledFrom] and [scaledTo] are the pixel (scaled) coordinates
  /// of (possibly stacked) data values in the [ChartRootContainer] coordinates.
  /// They are positions used by [PointPresenter] to paint the 'widget'
  /// that represents the (possibly stacked) data value.
  ///
  /// Initially scaled to available pixels on the Y axis,
  /// then moved by positioning by [applyParentOffset].
  ///
  /// In other words, they hold offsets of the bottom and top of the [PointPresenter] of this
  /// data value point.
  ///
  /// For example, for VerticalBar, [scaledFrom] is the bottom left and
  /// [scaledTo] is the top right of each bar representing this value point (data point).
  ui.Offset scaledFrom = ui.Offset.zero;

  /// See [scaledFrom].
  ui.Offset scaledTo = ui.Offset.zero;

  /// The generative constructor of objects for this class.
  NewDataModelPoint({
    required this.xLabel,
    required this.dataY,
    required this.dataRowIndex,
    this.predecessorPoint,
  })  : isStacked = false,
        fromY = 0.0,
        toY = dataY;

  /// Initial instance of a [NewDataModelPoint].
  /// Forwarded to the generative constructor.
  /// This should fail if it undergoes any processing such as layout
  NewDataModelPoint.initial()
      : this(
    xLabel: 'initial',
    dataY: -1,
    dataRowIndex: -1,
    predecessorPoint: null,
  );

  NewDataModelPoint stack() {
    isStacked = true;

    // todo-1 validate: check if both points y have the same sign or both zero
    fromY = predecessorPoint != null ? predecessorPoint!.toY : 0.0;
    toY = fromY + dataY;

    return this;
  }

  /// Stacks this point on top of the passed [predecessorPoint].
  ///
  /// Points are constructed unstacked. Depending on chart type,
  /// a later processing can stack points using this method
  /// (if chart type is [ChartRootContainer.isStacked].
  NewDataModelPoint stackOnAnother(NewDataModelPoint? predecessorPoint) {
    this.predecessorPoint = predecessorPoint;
    return stack();
  }

  /// Scales this point to the container coordinates (display coordinates).
  ///
  /// More explicitly, scales the data-members of this point to the said coordinates.
  ///
  /// See class documentation for which members are data-members and which are scaled-members.
  ///
  /// Note that the x values are not really scaled, as object does not
  /// manage the not-scaled [x] (it manages the corresponding label only).
  /// For this reason, the [scaledX] value must be *already scaled*!
  /// The provided [scaledX] value should be the
  /// "within [ChartPainter] absolute" x coordinate (generally the center
  /// of the corresponding x label).
  ///
  NewDataModelPoint scale({
    required double scaledX,
    required YLabelsCreatorAndPositioner yLabelsCreator,
  }) {
    scaledFrom = ui.Offset(scaledX, yLabelsCreator.scaleY(value: fromY));
    scaledTo = ui.Offset(scaledX, yLabelsCreator.scaleY(value: toY));

    return this;
  }

  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    // only apply  offset on scaled values, those have chart coordinates that are painted.

    // not needed to offset : NewDataModelPoint predecessorPoint;

    /// Scaled values represent screen coordinates, apply offset to all.
    scaledFrom += offset;
    scaledTo += offset;
  }


  /// Copy - clone of this object unstacked. Does not allow to clone if
  /// already stacked.
  ///
  /// Returns a new [NewDataModelPoint] which is a full deep copy of this
  /// object. This includes cloning of [double] type members and [ui.Offset]
  /// type members.
  NewDataModelPoint unstackedClone() {
    if (isStacked) {
      throw Exception('Cannot clone if already stacked');
    }

    NewDataModelPoint clone = NewDataModelPoint(
        xLabel: xLabel, dataY: dataY, dataRowIndex: dataRowIndex, predecessorPoint: predecessorPoint);

    // numbers and Strings, being immutable, can be just assigned.
    // rest of objects (ui.Offset) must be constructed from immutable leafs.
    clone.xLabel = xLabel;
    clone.dataY = dataY;
    clone.predecessorPoint = null;
    clone.dataRowIndex = dataRowIndex;
    clone.isStacked = false;
    clone.fromY = fromY;
    clone.toY = toY;
    clone.scaledFrom = ui.Offset(scaledFrom.dx, scaledFrom.dy);
    clone.scaledTo = ui.Offset(scaledTo.dx, scaledTo.dy);

    return clone;
  }
  */
}

// -------------------- Functions

/*
// To initialize default colors with dynamic list that allows the colors NOT null, initialization must be done in
//  initializer list (it is too late in constructor, by then, the colors list would have to be NULLABLE).
/// Sets up colors for legends, first several explicitly, rest randomly.
///
/// This is used if user does not set colors.
List<ui.Color> _dataRowsDefaultColors(int _dataRowsCount) {
  List<ui.Color> _rowsColors = List.empty(growable: true);

  if (_dataRowsCount >= 1) {
    _rowsColors.add(material.Colors.yellow);
  }
  if (_dataRowsCount >= 2) {
    _rowsColors.add(material.Colors.green);
  }
  if (_dataRowsCount >= 3) {
    _rowsColors.add(material.Colors.blue);
  }
  if (_dataRowsCount >= 4) {
    _rowsColors.add(material.Colors.black);
  }
  if (_dataRowsCount >= 5) {
    _rowsColors.add(material.Colors.grey);
  }
  if (_dataRowsCount >= 6) {
    _rowsColors.add(material.Colors.orange);
  }
  if (_dataRowsCount > 6) {
    for (int i = 3; i < _dataRowsCount; i++) {
      int colorHex = math.Random().nextInt(0xFFFFFF);
      int opacityHex = 0xFF;
      _rowsColors.add(ui.Color(colorHex + (opacityHex * math.pow(16, 6)).toInt()));
    }
  }
  return _rowsColors;
}
*/

