// Note: import 'package:flutter/foundation.dart'; - this causes bizarre error on dart:ui missing if running
//       as 'dart run example/lib/examples_descriptor.dart'. Running with 'flutter run' sort of works, but needs device.
//       Looks like importing any flutter packages fails when running as dart.

import 'ExamplesChartTypeEnum.dart' show ExamplesChartTypeEnum;
import 'ExamplesEnum.dart' show ExamplesEnum;
import 'package:tuple/tuple.dart' show Tuple2;

// todo-00 : pull ExamplesChartTypeEnum and ExamplesEnum in this package.

/// Represents examples and tests to be shown.
class ExamplesDescriptor {
  List<Tuple2<ExamplesEnum, ExamplesChartTypeEnum>> _allowed = [
    const Tuple2(ExamplesEnum.ex_1_0_RandomData, ExamplesChartTypeEnum.LineChart),
    const Tuple2(ExamplesEnum.ex_1_0_RandomData, ExamplesChartTypeEnum.VerticalBarChart),

    const Tuple2(ExamplesEnum.ex_2_0_AnimalCountBySeason, ExamplesChartTypeEnum.LineChart),
    const Tuple2(ExamplesEnum.ex_2_0_AnimalCountBySeason, ExamplesChartTypeEnum.VerticalBarChart),

    const Tuple2(ExamplesEnum.ex_3_0_RandomData_ExplicitLabelLayoutStrategy, ExamplesChartTypeEnum.LineChart),
    const Tuple2(ExamplesEnum.ex_3_0_RandomData_ExplicitLabelLayoutStrategy, ExamplesChartTypeEnum.VerticalBarChart),

    const Tuple2(
        ExamplesEnum.ex_4_0_LanguagesOrdinarOnYFromData_UserYOrdinarLabels_UserColors, ExamplesChartTypeEnum.LineChart),
    //  const Tuple2(ExamplesEnum.ex_4_0_LanguagesYOrdinarLevelFromData_UserYOrdinarLevelLabels_UserColors, ExamplesChartTypeEnum.VerticalBarChart),

    // const  Tuple2(ExamplesEnum.ex_5_0_StocksRankedOnYWithNegatives_DataYLabels_UserColors, ExamplesChartTypeEnum.LineChart),
    const Tuple2(ExamplesEnum.ex_5_0_StocksRankedOnYWithNegatives_DataYLabels_UserColors,
        ExamplesChartTypeEnum.VerticalBarChart),
  ];

  /// Check if the example described by the passed enums should run in a test.
  ///
  /// Generally examples should run as either [LineChart] or [VerticalBarChart] except a few where only
  ///   one chart type makes sense to be presented.
  bool exampleComboIsAllowed(Tuple2<ExamplesEnum, ExamplesChartTypeEnum> comboToRun) {
    return _allowed.any((tuple) => tuple.item1 == comboToRun.item1 && tuple.item2 == comboToRun.item2);
  }

  /// Present this descriptor is a format suitable to run as a test from command line.
  void asCommandLine() {
    _allowed.forEach((tuple) => print(
        // cli representation
        'flutter run --device-id=\$1 ' +
            '--dart-define=EXAMPLE_TO_RUN=${myDescribeEnum(tuple.item1)} ' +
            '--dart-define=CHART_TYPE_TO_SHOW=${myDescribeEnum(tuple.item2)} ' +
            ' example/lib/main.dart'));
  }
}

String myDescribeEnum(Enum e) {
  return e.toString().split('.')[1];
}

/// Present this descriptor as a command line.
void main() {
  ExamplesDescriptor().asCommandLine();
}