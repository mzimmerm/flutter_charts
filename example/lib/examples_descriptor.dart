import 'ExamplesChartTypeEnum.dart' show ExamplesChartTypeEnum;
import 'ExamplesEnum.dart' show ExamplesEnum;
import 'package:tuple/tuple.dart' show Tuple2;

/// Represents examples and tests to be shown.
class ExamplesDescriptor {
  
  List<Tuple2<ExamplesEnum, ExamplesChartTypeEnum>> _allowed = [
    const Tuple2(ExamplesEnum.ex_1_0_RandomData, ExamplesChartTypeEnum.LineChart),
    const Tuple2(ExamplesEnum.ex_1_0_RandomData, ExamplesChartTypeEnum.VerticalBarChart),
    
    const Tuple2(ExamplesEnum.ex_2_0_AnimalCountBySeason, ExamplesChartTypeEnum.LineChart),
    const Tuple2(ExamplesEnum.ex_2_0_AnimalCountBySeason, ExamplesChartTypeEnum.VerticalBarChart),
    
    const Tuple2(ExamplesEnum.ex_3_0_RandomData_ExplicitLabelLayoutStrategy, ExamplesChartTypeEnum.LineChart),
    const Tuple2(ExamplesEnum.ex_3_0_RandomData_ExplicitLabelLayoutStrategy, ExamplesChartTypeEnum.VerticalBarChart),
   
    const Tuple2(ExamplesEnum.ex_4_0_LanguagesOrdinarOnYFromData_UserYOrdinarLabels_UserColors, ExamplesChartTypeEnum.LineChart),
    //  const Tuple2(ExamplesEnum.ex_4_0_LanguagesYOrdinarLevelFromData_UserYOrdinarLevelLabels_UserColors, ExamplesChartTypeEnum.VerticalBarChart),
    
    // const  Tuple2(ExamplesEnum.ex_5_0_StocksRankedOnYWithNegatives_DataYLabels_UserColors, ExamplesChartTypeEnum.LineChart),
    const Tuple2(ExamplesEnum.ex_5_0_StocksRankedOnYWithNegatives_DataYLabels_UserColors, ExamplesChartTypeEnum.VerticalBarChart),
  ];
  
  bool isAllowed(Tuple2<ExamplesEnum, ExamplesChartTypeEnum> comboToRun) {
    return _allowed.any((tuple) => tuple.item1 == comboToRun.item1 && tuple.item2 == comboToRun.item2);
  }
}