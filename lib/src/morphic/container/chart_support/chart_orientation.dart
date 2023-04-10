import '../container_layouter_base.dart' as container_base;

/// Describes display orientation of axes and data on a chart.
///
/// Motivation:
///   For almost all chart types (at least for line chart and bar chart),
///   the same data can be presented using two equivalent views:
///   1. View where the independent axis (x axis, input axis) is shown horizontally,
///      and values across series are shown vertically, in columns, potentially stacked;
///   2. A 'inverted' view where the independent axis (x axis, input axis) is shown vertically,
///      and values across series are shown horizontally, in rows, potentially 'horizontally stacked'.
///
/// This enum can be used as a single parameter which controls the orientation of the chart view
/// as 1. or 2. above. The name is taken from the 'stacking' or 'data showing' orientation, the [mainLayoutAxis].
///
/// The names [column] and [row] are taken from the 'across series stacking orientation'.
///
/// In all 'regular' situations, there are only two allowed combination of mainLayoutAxis and inputAxis
///      - column: mainLayoutAxis = vertical (column) ; inputAxis = horizontal (horizontal bar chart, line chart)
///      - row:    mainLayoutAxis = horizontal (row)  ; inputAxis = vertical  (vertical bar chart, inverted line chart)
enum ChartSeriesOrientation {
  // todo-00-refactoring : rename to ChartOrientation, or ChartCrossSeriesOrientation
  column(
    mainLayoutAxis: container_base.LayoutAxis.vertical,
    inputAxis: container_base.LayoutAxis.horizontal,
  ),
  row(
    mainLayoutAxis: container_base.LayoutAxis.horizontal,
    inputAxis: container_base.LayoutAxis.vertical,
  );

  const ChartSeriesOrientation({
    required this.mainLayoutAxis, // orientation along which outputValues (across series values) are displayed
    required this.inputAxis, // orientation of axis where inputValues (independent values, x values) are displayed
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
  final container_base.LayoutAxis mainLayoutAxis;

  /// Describes how the input axis (other terms: x axis, axis with independent data)
  /// is oriented in view - horizontally or vertically.
  final container_base.LayoutAxis inputAxis;

  /// For this chart orientation, we can look at the axis on which we extrapolate data values
  /// to pixels, call in [lextrToRangeOrientation] and ask: on the [lextrToRangeOrientation],
  /// should the lextr invert sign?
  ///
  /// This is where this method comes handy.
  bool isPixelsAndValuesSameDirectionFor({required container_base.LayoutAxis lextrToRangeOrientation}) {
    // for column, and pixels axis horizontal, return true
    // for column, and pixels axis vertical,   return false
    // for row,    and pixels axis horizontal, return false
    // for row,    and pixels axis vertical,   return true
    return (inputAxis == lextrToRangeOrientation);
  }
}

