import 'chart_support/chart_style.dart';

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

/// On behalf of [CrossPointsModel], represents the sign of the values of [PointModel] points
/// which should be added to the [CrossPointsModel].
///
/// Motivation: In order to display both negative and positive values on the bar chart or line chart,
///             the [ChartModel] manages the positive and negative values separately in
///             [ChartModel.crossPointsModelPositiveList] and [ChartModel.crossPointsModelNegativeList].
///             This enum supports creating and later using (processing, view making) the positive and negative
///             bars separately.
enum Sign {
  positiveOr0,
  negative,
  any;

  /// Checks if the sign of a the passed [value] is the sign required by this enum instance.
  ///
  /// Motivation: In the context of a charting framework, any series positive and negative
  ///             values are split and kept separate in model and in view containers.
  ///             Example:
  ///               - There are separate instances of positive and negative [CrossPointsModel]s,
  ///                 in [ChartModel.crossPointsModelPositiveList] and [ChartModel.crossPointsModelNegativeList].
  ///             This method is a helper to performs the separation based on [pointsSign].
  bool isValueMySign({
    required double value,
  }) {
    switch (this) {
      case Sign.positiveOr0:
        return (value >= 0.0);
      case Sign.negative:
        return (value < 0.0);
      case Sign.any:
        return true;
    }
  }
}
