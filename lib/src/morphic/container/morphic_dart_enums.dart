import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';

/// Library defines enums which belong to Flutter-dependent [container_layouter_base.dart]
/// but packaged here for testability in dart testing.


/// Position in label on which the axis tick, defining the label's data position, is placed.
enum ExternalTickAtPosition {
  childStart,
  childCenter,
  childEnd,
}

/// Describes axis orientation in culture-neutral, and data dependent/independent neutral terms.
///
enum LayoutAxis {
  horizontal,
  vertical,
}

/// Describes the type of data shown on a [LayoutAxis], for a [ChartOrientation].
///
/// Given a [ChartOrientation], the [LayoutAxis] on which a given [DataDependency]
/// is shown, is defined by [ChartOrientation.layoutAxisForDataDependency].
enum DataDependency {
  inputData,
  outputData,
}

