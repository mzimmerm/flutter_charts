import '../morphic_dart_enums.dart' show LayoutAxis, DataDependency;

/// Describes display orientation of axes and data on a chart.
///
/// Motivation:
///   For almost all chart types (at least for line chart and bar chart),
///   the same data can be presented using two equivalent views:
///   1. View where the independent axis (x axis, input axis) is shown horizontally,
///      and values across series are shown vertically, in columns, potentially 'vertically stacked'.
///   2. A 'transposed' view where the independent axis (x axis, input axis) is shown vertically,
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
enum ChartOrientation {
  // todo-011: consider rename:
  //    column                   -> inputAxisHorizontal
  //    row                      -> inputAxisVertical
  //    inputDataAxisOrientation -> inputAxis  ; also change this to getter: cross to outputAxis
  //    mainLayoutAxis           -> outputAxis ; also change this to getter: if this == inputAxisHorizontal => vertical, and the other way around

  column(
    mainLayoutAxis: LayoutAxis.vertical,
    inputDataAxisOrientation: LayoutAxis.horizontal,
  ),
  row(
    mainLayoutAxis: LayoutAxis.horizontal,
    inputDataAxisOrientation: LayoutAxis.vertical,
  );

  const ChartOrientation({
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

  factory ChartOrientation.fromString(
    String orientation,
  ) {
    switch (orientation) {
      case 'column':
        return ChartOrientation.column;
      case 'row':
        return ChartOrientation.row;
      default:
        throw StateError('Invalid orientation \'$orientation\' for converting String to ChartOrientation.');
    }
  }

  factory ChartOrientation.fromStringOrDefault(
    String orientation,
    ChartOrientation defaultOrientation,
  ) {
    try {
      return ChartOrientation.fromString(orientation);
    } on StateError {
      return defaultOrientation;
    }
  }

  factory ChartOrientation.fromStringDefaultOnEmpty(
    String orientation,
    ChartOrientation defaultOrientation,
  ) {
    if (orientation == '') {
      return defaultOrientation;
    }
    return ChartOrientation.fromString(orientation);
  }

  /// For a chart orientation represented by this instance, describes orientation of the axis
  /// which displays [DataDependency] described in the passed [dataDependency]
  /// 
  /// Motivation: For any chart orientation, and any axis on the chart, we need to know if the data values axis
  ///   and the pixel axis which displays them, run in the same direction; this knowledge is equivalent to the knowledge whether
  ///   displayed pixels are on the horizontal or vertical axis. This information is used to extrapolate data values
  ///   to pixels, on either axis, to answer this question: should the value to pixels affmap invert sign?
  LayoutAxis layoutAxisForDataDependency({required DataDependency dataDependency}) {
    // for ChartOrientation.column, and inputOrOutputData DataDependency.inputData,   return LayoutAxis.horizontal
    // for ChartOrientation.column, and inputOrOutputData DataDependency.outputData,  return LayoutAxis.vertical
    // for ChartOrientation.row,    and inputOrOutputData DataDependency.inputData,   return LayoutAxis.vertical
    // for ChartOrientation.row,    and inputOrOutputData DataDependency.outputData,  return LayoutAxis.horizontal
    switch(this) {
      case ChartOrientation.column:
        switch (dataDependency) {
          case DataDependency.inputData:
            return LayoutAxis.horizontal;
          case DataDependency.outputData:
            return LayoutAxis.vertical;
        }
      case ChartOrientation.row:
        switch (dataDependency) {
          case DataDependency.inputData:
            return LayoutAxis.vertical;
          case DataDependency.outputData:
            return LayoutAxis.horizontal;
        }
    }
  }

}

/// Describes chart types shown in examples or integration tests.
enum ChartType {
  lineChart,
  barChart,
}

/// Describes how cross-series data are shown: Either stacked, or nonStacked (side by side on horizontal bar chart,
/// all starting at zero on line chart).
enum ChartStacking {
  stacked,
  nonStacked;

  bool get isStacked {
    return this == stacked;
  }
}

/// Identifies a diagonal for transpose transfer.
///
/// [leftToRightUp] identifies the diagonal around which a coordinate system would
/// rotate to get from a vertical bar chart to a horizontal bar chart.
enum Diagonal {
  leftToRightDown,
  leftToRightUp,
}

