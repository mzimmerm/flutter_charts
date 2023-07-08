import 'package:flutter_charts/src/chart/options.dart' as chart_options;

class LegendAndItemLayoutEnum extends chart_options.LegendAndItemLayoutEnum {
  
  const LegendAndItemLayoutEnum(super.i);
  
  static const legendIsColumnStartLooseItemIsRowStartLoose = chart_options.LegendAndItemLayoutEnum(1001); // See comment on legendIsColumnStartTightItemIsRowStartTight
  static const legendIsColumnStartTightItemIsRowStartTight = chart_options.LegendAndItemLayoutEnum(1002); // legend items in column
  static const legendIsRowCenterLooseItemIsRowEndLoose = chart_options.LegendAndItemLayoutEnum(1003); // Item row is not top = chart_options.LegendAndItemLayoutEnum(XX); forced to 'start' = chart_options.LegendAndItemLayoutEnum(XX); 'tight'  = chart_options.LegendAndItemLayoutEnum(XX); so noop
  static const legendIsRowStartTightItemIsRowStartTightSecondGreedy = chart_options.LegendAndItemLayoutEnum(1005); // second Item is greedy wrapped
  static const legendIsRowStartTightItemIsRowStartTightItemChildrenPadded = chart_options.LegendAndItemLayoutEnum(1006);
  static const legendIsRowStartTightItemIsRowStartTightItemChildrenAligned = chart_options.LegendAndItemLayoutEnum(1007);
}