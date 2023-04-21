import '../container_layouter_base_dart_support.dart' show LayoutAxis, DataDependency;

/// Describes display orientation of axes and data on a chart.
///
/// Motivation:
///   For almost all chart types (at least for line chart and bar chart),
///   the same data can be presented using two equivalent views:
///   1. View where the independent axis (x axis, input axis) is shown horizontally,
///      and values across series are shown vertically, in columns, potentially 'vertically stacked'.
///   2. A 'inverted' view where the independent axis (x axis, input axis) is shown vertically,
///      and values across series are shown horizontally, in rows, potentially 'horizontally stacked'.
///
/// This enum can be used as a single parameter which controls the orientation of the chart view
/// as 1. or 2. above. The name is taken from the 'stacking' or 'data showing' orientation, the [mainLayoutAxis].
///
/// The names [column] and [row] are taken from the 'across series stacking orientation'.
///
/// In all 'regular' situations, there are only two allowed combination of mainLayoutAxis and inputDataAxisOrientation
///      - column: mainLayoutAxis = vertical (column) ; inputDataAxisOrientation = horizontal (horizontal bar chart, line chart)
///      - row:    mainLayoutAxis = horizontal (row)  ; inputDataAxisOrientation = vertical  (vertical bar chart, inverted line chart)
enum ChartSeriesOrientation {
  // todo-001-refactoring : rename to ChartOrientation, or ChartCrossSeriesOrientation
  column(
    mainLayoutAxis: LayoutAxis.vertical,
    inputDataAxisOrientation: LayoutAxis.horizontal,
  ),
  row(
    mainLayoutAxis: LayoutAxis.horizontal,
    inputDataAxisOrientation: LayoutAxis.vertical,
  );

  const ChartSeriesOrientation({
    required this.mainLayoutAxis, // orientation along which outputValues (across series values) are displayed
    required this.inputDataAxisOrientation, // orientation of axis where inputValues (independent values, x values) are displayed
  });

  /// Describes how the data series is oriented in view - horizontally or vertically.
  ///
  /// This equivalently represents the main layout axis of the layouter which lays out points on the chart:
  ///   - If `mainLayoutAxis == container_base.LayoutAxis.vertical`, then the points are layed out in
  ///     a [container_base.Column] layouter.
  ///   - Horizontal assumes the [container_base.Row] layouter is used.
  ///
  /// This also equivalently represents the main layout axis of the layouter which splits the positive
  /// and negative areas of the chart:
  ///   - If `mainLayoutAxis == container_base.LayoutAxis.vertical`, then the positive/negative sections of chart data
  ///     are layed out in a [container_base.Column] layouter.
  final LayoutAxis mainLayoutAxis;

  /// Describes how the input axis (other terms: x axis, input data axis, axis with independent data)
  /// is oriented in view - horizontally or vertically.
  final LayoutAxis inputDataAxisOrientation;

  factory ChartSeriesOrientation.fromString(
    String orientation,
  ) {
    switch (orientation) {
      case 'column':
        return ChartSeriesOrientation.column;
      case 'row':
        return ChartSeriesOrientation.row;
      default:
        throw StateError('Invalid orientation \'$orientation\' for converting String to ChartSeriesOrientation.');
    }
  }

  factory ChartSeriesOrientation.fromStringOrDefault(
    String orientation,
    ChartSeriesOrientation defaultOrientation,
  ) {
    try {
      return ChartSeriesOrientation.fromString(orientation);
    } on StateError {
      return defaultOrientation;
    }
  }

  factory ChartSeriesOrientation.fromStringDefaultOnEmpty(
    String orientation,
    ChartSeriesOrientation defaultOrientation,
  ) {
    if (orientation == '') {
      return defaultOrientation;
    }
    return ChartSeriesOrientation.fromString(orientation);
  }

  /// For a chart orientation represented by this instance, return whether pixels and values are same orientation
  /// on an axis which displays [DataDependency] in the passed [inputOrOutputData]
  /// 
  /// Motivation: For any chart orientation, and any axis on the chart, we need to know if the data values axis
  ///   and the pixel axis which displays them, run in the same direction; this knowledge is equivalent to the knowledge whether
  ///   displayed pixels are on the horizontal or vertical axis. This information is used to extrapolate data values
  ///   to pixels, on either axis, to answer this question: should the value to pixels lextr invert sign?
  bool isOnHorizontalAxis({required DataDependency inputOrOutputData}) {
    // for ChartSeriesOrientation.column, and inputOrOutputData DataDependency.inputData,   return true
    // for ChartSeriesOrientation.column, and inputOrOutputData DataDependency.outputData,  return false
    // for ChartSeriesOrientation.row,    and inputOrOutputData DataDependency.inputData,   return false
    // for ChartSeriesOrientation.row,    and inputOrOutputData DataDependency.outputData,  return true
    switch(this) {
      case ChartSeriesOrientation.column:
        switch (inputOrOutputData) {
          case DataDependency.inputData:
            return true;
          case DataDependency.outputData:
            return false;
        }
      case ChartSeriesOrientation.row:
        switch (inputOrOutputData) {
          case DataDependency.inputData:
            return false;
          case DataDependency.outputData:
            return true;
        }
    }
  }
}

// todo-00-refactoring : move to the same dart file with enums. Also review all enums in flutter_charts and organize them
// todo-00-refactoring : rename to ChartTypeEnum,
/// Describes chart types shown in examples or integration tests.
enum ExamplesChartTypeEnum {
  lineChart,
  // todo-00-refactoring: rename verticalBarChart to barChart everywhere. ChartSeriesOrientation column, row, defines horizontal, vertical.
  //
  verticalBarChart,
}

/// Describes how cross-series data are shown: Either stacked, or side by side.
///
/// Side by side in only applicable to Bar chart.
enum ChartStackingEnum {
  stacked,
  sideBySide, // todo-00-last : rename to nonStacked - this is side by side on Bar, regular for line chart
}
