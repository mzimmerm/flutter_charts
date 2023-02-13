import 'dart:math' as math show min, max;
import 'dart:ui' as ui show Color;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/chart/new_data_container.dart';
import 'package:flutter_charts/src/util/util_labels.dart' as util_labels;

// todo-doc-01 document Copied from [ChartData], it is a replacement for both legacy [ChartData], [PointsColumns],
//                   and various holders of Y data values, including some parts of [DataRangeLabelsGenerator]
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
///   - When [NewModel] is constructed, the [ChartRootContainer] is not available.
///     So in constructor, [NewModel] cannot be given access to the root container, and it's needed members
///     such as [ChartRootContainer.yLabelsGenerator].
class NewModel {

  // ================ CONSTRUCTOR NEEDS SOME OLD MEMBERS FOR NOW ====================

  NewModel({
    required dataRows,
    required this.xUserLabels,
    required dataRowsLegends,
    required this.chartOptions,
    this.yUserLabels,
    List<ui.Color>? dataRowsColors,
  })
      :
  // Initializing of non-nullable _dataRowsColors which is a non-required argument
  // must be in the initializer list by a non-member function (member methods only in constructor)
        _dataRows = dataRows,
        _dataRowsLegends = dataRowsLegends,
        _dataRowsColors = dataRowsColors ?? dataRowsDefaultColors(dataRows.length)
  {
    print('Constructing NewModel');
    validate();

    _dataBars = transposeRowsToColumns(_dataRows);

    // Construct the full [NewModel] as well, so we can use it, and also gradually
    // use it's methods and members in OLD DataContainer.
    // Here, create one [NewModelSeries] for each data row, and add to member [barOfPointsList]
    int columnIndex = 0;
    for (List<double> dataBar in _dataBars) {
      barOfPointsList.add(
        NewBarOfPointsModel(
          dataBar: dataBar,
          dataModel: this,
          columnIndex: columnIndex++,
        ),
      );
    }

  }

  // NEW CODE =============================================================

  // [NewModel] is created first. So ViewMaker must be set publicly late.
  late final ChartViewMaker chartViewMaker; // todo-00-remove. I think it is only here to get at options, we we access directly

  /// List of data barOfPoints in the model.
  final List<NewBarOfPointsModel> barOfPointsList = []; // todo-done-last-3 : added for the NewModel

  /// Returns the minimum and maximum non-scaled, transformed data values calculated from [NewModel],
  /// specific for the passed [isStacked].
  ///
  /// The returned value is calculated from [NewModel] by finding maximum and minimum of data values
  /// in [NewPointModel] instances.
  ///
  /// The source data of the returned interval differs in stacked and non-stacked data, determined by argument [isStacked] :
  ///   - For [isStacked] true, the min and max is taken from [NewPointModel._stackedPositiveDataValue] and
  ///     [NewPointModel._stackedNegativeDataValue] is used.
  ///   - For  [isStacked] false, the min and max is taken from [NewPointModel._dataValue] is used.
  ///
  /// Implementation detail: maximum and minimum is calculated column-wise [NewBarOfPointsModel] first, but could go
  /// directly to the flattened list of [NewPointModel] (max and min over partitions is same as over whole set).
  ///
  Interval dataValuesInterval({
    required bool isStacked,
  }) {
    if (isStacked) {
      return Interval(
        // reduce, not fold: barOfPointsList.fold(0.0, ((double previous, NewBarOfPointsModel pointsColumn) => math.min(previous, pointsColumn._stackedNegativeValue))),
        barOfPointsList.map((pointsColumn) => pointsColumn._stackedNegativeValue).toList().reduce(math.min),
        barOfPointsList.map((pointsColumn) => pointsColumn._stackedPositiveValue).toList().reduce(math.max),
      );
    } else {
      return Interval(
        barOfPointsList.map((pointsColumn) => pointsColumn._minPointValue).toList().reduce(math.min),
        barOfPointsList.map((pointsColumn) => pointsColumn._maxPointValue).toList().reduce(math.max),
      );
    }
  }

  /// Returns the interval that envelopes all data values in [NewModel.dataRows], possibly extended to 0.
  ///
  /// The [isStacked] controls whether the interval is created from values in [NewPointModel._dataValue]
  /// or the stacked values [NewPointModel._stackedPositiveDataValue] and
  /// [NewPointModel._stackedNegativeDataValue]
  ///
  /// Whether the resulting Interval is extended from the simple min/max of all data values
  /// is controlled by [extendAxisToOrigin]. If [true] the interval is extended to zero
  /// if all values are positive or all are negative.
  ///
  Interval extendedDataValuesInterval({
    required bool isStacked,
    required bool extendAxisToOrigin,
  }) {
    return util_labels.extendToOrigin(
      dataValuesInterval(isStacked: isStacked),
      extendAxisToOrigin,
    );
  }

  List<NewBarOfPointsContainer> generateViewChildren_Of_NewDataContainer_As_NewBarOfPointsContainer_List(ChartRootContainer chartRootContainer) {
    List<NewBarOfPointsContainer> chartColumns = [];
    // Iterate the dataModel down, creating NewBarOfPointsContainer, then NewPointContainer and return

    for (NewBarOfPointsModel barOfPoints in barOfPointsList) {
      // NewBarOfPointsContainer barOfPointsContainer =
      chartColumns.add(
        NewBarOfPointsContainer(
          chartRootContainer: chartRootContainer,
          backingDataBarOfPointsModel: barOfPoints,
          children: [Column(
              children: barOfPoints.generateViewChildren_Of_NewBarOfPointsContainer_As_NewPointContainer_List(chartRootContainer).reversed.toList(growable: false),
          )],
          // Give all view columns the same weight along main axis -
          //   results in same width of each [NewBarOfPointsContainer] as owner will be Row (main axis is horizontal)
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
  late final List<List<double>> _dataBars;
  List<List<double>> get dataBars => _dataBars;

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

  /// Colors corresponding to each data row (series) in [NewModel].
  final List<ui.Color> _dataRowsColors;
  List<ui.Color> get dataRowsColors => _dataRowsColors;

  /// Chart options which may affect data validation.
  final ChartOptions chartOptions;

  bool get isUsingUserLabels => yUserLabels != null;

  List<double> get flatten => _dataRows.expand((element) => element).toList();
  double get dataYMax => flatten.reduce(math.max);
  double get dataYMin => flatten.reduce(math.min);

  void validate() {
    //                      But that would require ChartOptions available in NewModel.
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

/// todo-done-last-3 : Replaces PointsColumn
/// Represents a list of data values, in the [NewModel].
///
/// As we consider the [NewModel] to represent a 2D array 'rows first', rows oriented
/// 'top-to-bottom', columns oriented left-to-right, then:
/// The list of data values in this object represent one column in the 2D array,
/// oriented 'top-to-bottom'. We can also consider the list of data values represented by
/// this object to be created by diagonal transpose of the [NewModel._dataRows] and
/// looking at one row in the transpose, left-to-right.
class NewBarOfPointsModel extends Object with DoubleLinkedOwner<NewPointModel> {

  /// Constructor. todo-doc-01
  NewBarOfPointsModel({
    required List<double> dataBar,
    required NewModel dataModel,
    required int columnIndex,
  })
      : _dataModel = dataModel,
        _columnIndex = columnIndex {
    // Construct data points from the passed [dataRow] and add each point to member _points
    int rowIndex = 0;
    for (double dataValue in dataBar) {
      var point = NewPointModel(dataValue: dataValue, ownerBarOfPointsList: this, rowIndex: rowIndex);
      _points.add(point);
      rowIndex++;
    }
    // When all points in this barOfPoints are constructed and added to [_points], we can double-link the points.
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
  _stackPoints(NewPointModel point, unused) {
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

  /// Owner [NewModel] to which this [NewBarOfPointsModel] belongs by existence in
  /// [NewModel.barOfPointsList].
  ///
  final NewModel _dataModel;
  NewModel get dataModel => _dataModel;

  /// Index of this column (barOfPoints list) in the [NewModel.barOfPointsList].
  ///
  /// Also indexes one column, top-to-bottom, in the two dimensional [NewModel.dataRows].
  /// Also indexes one row, left-to-right, in the `transpose(NewModel.dataRows)`.
  ///
  /// The data values of this column are stored in the [_points] list,
  /// values and order as in top-to-bottom column in [NewModel.dataRows].
  ///
  /// This is needed to access the legacy arrays such as:
  ///   -  [NewModel.dataRowsLegends]
  ///   -  [NewModel.dataRowsColors]
  final int _columnIndex;

  /// Points of this column (barOfPoints).
  ///
  /// The points are needed to provide the [allElements], the list of all [DoubleLinked] elements
  /// owned by this [DoubleLinkedOwner]. 
  /// At the same time, the points are all [NewPointModel] in this column (barOfPoints list).
  final List<NewPointModel> _points = [];

  /// Implements the [DoubleLinkedOwner] abstract method which provides all elements for
  /// the owned [DoubleLinked] instances of [NewPointModel].
  @override
  Iterable<NewPointModel> allElements() => _points;

  /// Returns height of this column in terms of data values on points, separately for positive and negative.
  ///
  /// Getters always recalculates, should be cached in new member on column
  double get _stackedPositiveValue => __maxOnPoints((NewPointModel point) => point._stackedPositiveDataValue);
  double get _stackedNegativeValue => __minOnPoints((NewPointModel point) => point._stackedNegativeDataValue);

  double get _minPointValue         => __minOnPoints((NewPointModel point) => point._dataValue);
  double get _maxPointValue         => __maxOnPoints((NewPointModel point) => point._dataValue);

  //double __stackedPositive(NewPointModel point) => point._stackedPositiveDataValue;
  //double __stackedNegative(NewPointModel point) => point._stackedNegativeDataValue;

  double __maxOnPoints(double Function(NewPointModel) getNumFromPoint) {
    return __applyFoldableOnPoints(getNumFromPoint, math.max);
  }

  double __minOnPoints(double Function(NewPointModel) getNumFromPoint) {
    return __applyFoldableOnPoints(getNumFromPoint, math.min);
  }

  /// Apply the fold performed by [foldable] (double, double) => double function,
  /// on some double values from the owned [allElements] which are [DoubleLinked] and [NewPointModel]s.
  ///
  /// The double values are pulled from each [NewPointModel]
  /// using the [getNumFromPoint] (NewPointModel) => double function.
  ///
  double __applyFoldableOnPoints(
    double Function(NewPointModel) getNumFromPoint,
    double Function(double, double) foldable,
  ) {
    _DoubleValue result = _DoubleValue();
    applyOnAllElements(
      (NewPointModel point, result) {
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

  /// Generates [NewPointContainer] view from each [NewPointModel]
  /// and collects the views in a list of [NewPointContainer]s which is returned.
  List<NewPointContainer> generateViewChildren_Of_NewBarOfPointsContainer_As_NewPointContainer_List(ChartRootContainer chartRootContainer) {
    List<NewPointContainer> newPointContainerList = [];

    // Generates [NewPointContainer] view from each [NewPointModel]
    // and collect the views in a list which is returned.
    applyOnAllElements(
      (NewPointModel element, dynamic passedList) {
        var newPointContainerList = passedList[0];
        var chartRootContainer = passedList[1];
        newPointContainerList.add(element.generateViewChildLeaf_Of_NewBarOfPointsContainer_As_NewPointContainer(chartRootContainer));
      },
      [newPointContainerList, chartRootContainer],
    );

    return newPointContainerList;
  }
}

class _DoubleValue {
  double value = 0.0;
}

/// Represents one data point. Replaces the legacy [StackableValuePoint].
///
/// Notes:
///   - Has private access to the owner [NewModel] to which it belongs through it's member [ownerBarOfPointsList]
///     which in turn has access to [NewModel] through it's member [NewBarOfPointsModel._dataModel].
///     THIS ACCESS IS CURRENTLY UNUSED
///
class NewPointModel extends Object with DoubleLinked {

  // ===================== CONSTRUCTOR ============================================
  // todo-doc-01
  NewPointModel({
    required double dataValue,
    required this.ownerBarOfPointsList,
    required int rowIndex,
  })  : _dataValue = ownerBarOfPointsList._dataModel.chartOptions.dataContainerOptions.yTransform(dataValue).toDouble(),
        _rowIndex = rowIndex {
    // The ownerSeries is NewModelSeries which is DoubleLinkedOwner
    // of all [NewPointModel]s, managed by [DoubleLinkedOwner.allElements]
    doubleLinkedOwner = ownerBarOfPointsList;
    // By the time a NewPointModel is constructed, DataModel and it's ownerBarOfPointsList INDEXES are configured
    assertDoubleResultsSame(
      ownerBarOfPointsList._dataModel.chartOptions.dataContainerOptions
          .yTransform(ownerBarOfPointsList.dataModel._dataRows[_rowIndex][ownerBarOfPointsList._columnIndex])
          .toDouble(),
      _dataValue,
    );
  }

  // ===================== NEW CODE ============================================

  /// The original (transformed, not-scaled) data value from one data item
  /// in the two dimensional, rows first, [NewModel.dataRows].
  ///
  /// This [_dataValue] point is created from the [NewModel.dataRows] using the indexes:
  ///   - row at index [_rowIndex]
  ///   - column at the [ownerBarOfPointsList] index [NewBarOfPointsModel._columnIndex].
  ///  Those indexes are also a way to access the original for comparisons and asserts in the algorithms.
  final double _dataValue;

  double get dataValue => _dataValue;

  late final double _stackedPositiveDataValue;
  late final double _stackedNegativeDataValue;

  /// Refers to the row index in [NewModel.dataRows] from which this point was created.
  ///
  /// Also, this point object is kept in [NewBarOfPointsModel._points] index [_rowIndex].
  ///
  /// See [_dataValue] for details of the column index from which this point was created.
  final int _rowIndex;

  /// References the data column (barOfPoints list) this point belongs to
  NewBarOfPointsModel ownerBarOfPointsList;

  /// Generate view for this single leaf [NewPointModel] - a single [NewHBarPointContainer].
  ///
  /// Note: On the leaf, we return single element by agreement, higher ups return lists.
  NewPointContainer generateViewChildLeaf_Of_NewBarOfPointsContainer_As_NewPointContainer(ChartRootContainer chartRootContainer) {
    return NewHBarPointContainer(
        newPointModel: this,
        chartRootContainer: chartRootContainer,
    );
  }

  ui.Color get color => ownerBarOfPointsList._dataModel._dataRowsColors[_rowIndex];

  // ====================== LEGACY CODE ====================================

  /* removed legacy code completely

  // ### 1. Group 1, initial values, but also includes [dataY] in group 2
  String xLabel;

  /// The transformed but NOT stacked Y data value.
  /// **ANY [dataYs] are 1. transformed, then 2. potentially stacked IN PLACE, then 3. potentially scaled IN A COPY!!**
  double dataY;

  /// The index of this point in the [PointsColumn] containing this point in it's
  /// [PointsColumn.newPointModels] list.
  int dataRowIndex; // series index

  /// The predecessor point in the [PointsColumn] containing this point in it's
  /// [PointsColumn.newPointModels] list.
  NewPointModel? predecessorPoint;

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
  NewPointModel({
    required this.xLabel,
    required this.dataY,
    required this.dataRowIndex,
    this.predecessorPoint,
  })  : isStacked = false,
        fromY = 0.0,
        toY = dataY;

  /// Initial instance of a [NewPointModel].
  /// Forwarded to the generative constructor.
  /// This should fail if it undergoes any processing such as layout
  NewPointModel.initial()
      : this(
    xLabel: 'initial',
    dataY: -1,
    dataRowIndex: -1,
    predecessorPoint: null,
  );

  NewPointModel stack() {
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
  NewPointModel stackOnAnother(NewPointModel? predecessorPoint) {
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
  NewPointModel scale({
    required double scaledX,
    required DataRangeLabelsGenerator yLabelsGenerator,
  }) {
    scaledFrom = ui.Offset(scaledX, yLabelsGenerator.scaleY(value: fromY));
    scaledTo = ui.Offset(scaledX, yLabelsGenerator.scaleY(value: toY));

    return this;
  }

  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    // only apply  offset on scaled values, those have chart coordinates that are painted.

    // not needed to offset : NewPointModel predecessorPoint;

    /// Scaled values represent screen coordinates, apply offset to all.
    scaledFrom += offset;
    scaledTo += offset;
  }


  /// Copy - clone of this object unstacked. Does not allow to clone if
  /// already stacked.
  ///
  /// Returns a new [NewPointModel] which is a full deep copy of this
  /// object. This includes cloning of [double] type members and [ui.Offset]
  /// type members.
  NewPointModel unstackedClone() {
    if (isStacked) {
      throw Exception('Cannot clone if already stacked');
    }

    NewPointModel clone = NewPointModel(
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

