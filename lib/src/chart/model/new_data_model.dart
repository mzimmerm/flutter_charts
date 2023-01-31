import 'dart:math' as math show min, max;
import 'dart:ui' as ui show Color;
import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart' as material show Colors;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/chart/new_data_container.dart';

/// todo-done-last  Copied from [ChartData], it is a replacement for both legacy [ChartData], and [PointsColumns].
@immutable
class NewDataModel {

  // NEW CODE =============================================================
  /// List of data series in the model.
  final List<NewDataModelSeries> seriesList = []; // todo-done-last : added for the NewDataModel

  List<NewValuesColumnContainer> createNewValuesColumnContainerList() {
    List<NewValuesColumnContainer> columns = [];
    // Iterate the dataModel down, creating NewValuesColumnContainer, then NewValueContainer and return

    for (NewDataModelSeries series in seriesList) {
      // NewValuesColumnContainer valuesColumnContainer =
      columns.add(NewValuesColumnContainer(
        backingDataModelSeries: series,
        children: series.buildNewValueContainersList(),
      ));
    }
    return columns;
  }

  // OLD CODE =============================================================
  // Legacy stuff below

  /// Data in rows.
  ///
  /// Each row of data represents one data series.
  /// Legends per row are managed by [_dataRowsLegends].
  ///
  /// Each element of the outer list represents one row.
  /// Alternative name would be "data series".
  final List<List<double>> _dataRows;
  List<List<double>> get dataRows => _dataRows;

  /// Labels on independent (X) axis.
  ///
  /// It is assumed labels are defined, by the client
  /// and their number is the same as number of points
  /// in each row in [_dataRows].
  final List<String> xUserLabels;

  /// The legends for the [_dataRows] (data series).
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

  /// Default constructor only assumes [_dataRows] are set,
  /// and assigns default values of [_dataRowsLegends], [_dataRowsColors], [xUserLabels], [yUserLabels].
  ///
  NewDataModel({
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
    validate();

    // Create one [NewDataModelSeries] for each data row, and add to member [seriesList]
    for (List<double> dataRow in _dataRows) {
      seriesList.add(NewDataModelSeries(
        dataRow: dataRow,
      ));
    }
  }

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

/// todo-done-last : Replaces PointsColumn
class NewDataModelSeries extends Object with DoubleLinkedOwner<NewDataModelPoint> {

  /// Points of this series.
  ///
  /// Only needed to provide [DoubleLinked.allElements] for the
  /// [NewDataModelPoint] in this series.
  final List<NewDataModelPoint> _points = [];

  /// Implements the [DoubleLinkedOwner] abstract method which provides all elements for
  /// the [DoubleLinked] instances of [NewDataModelPoint].
  ///
  /// When all points in this series are created, we create links between the points.
  /// We just need one point to start - provided by [DoubleLinkedOwner.firstLinked].
  @override
  Iterable<NewDataModelPoint> allElements() => _points;

  NewDataModelSeries({
    required List<double> dataRow,
  }) {
    // Create points from the passed [dataRow] and add each point to member _points
    for (double dataValue in dataRow) {
      var point = NewDataModelPoint(dataValue: dataValue, ownerSeries: this,);
      _points.add(point);
    }
    // When all points in this series are created, we can create links between the points.
    // We just need one point to start - provided by [DoubleLinkedOwner.firstLinked].
    if (_points.isNotEmpty) {
      firstLinked().linkAll();
    }
  }

  List<NewValueContainer> buildNewValueContainersList() {
    List<NewValueContainer> columnPointContainers = [];
    if (hasLinkedElements) {
      for (var current = firstLinked(); current.hasNext; current = current.next) {
        current.buildNewValueContainer();
      }
    }
    return columnPointContainers;
  }
}

// Represents one data point. Replaces the legacy [StackableValuePoint].
class NewDataModelPoint extends Object with DoubleLinked {

  // ===================== CONSTRUCTOR ============================================
  NewDataModelPoint({
    required double dataValue,
    required this.ownerSeries,
  }) : _dataValue = dataValue {
    // Place self as the DoubleLinkedOwner of it's children
    doubleLinkedOwner = ownerSeries;
  }

  // ===================== NEW CODE ============================================

  /// References the data series this point belongs to
  NewDataModelSeries ownerSeries;

  final double _dataValue;

  double get dataValue => _dataValue;

  NewValueContainer buildNewValueContainer() {
    return NewValueContainer(dataModelPoint: this);
  }

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
  /// Created, along with [toY] as follows:
  /// ```dart
  ///    fromY = predecessorPoint != null ? predecessorPoint!.toY : 0.0;
  ///     toY = fromY + dataY;
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
  /// manage the unscaled [x] (it manages the corresponding label only).
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
    // rest of objects (ui.Offset) must be created from immutable leafs.
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

