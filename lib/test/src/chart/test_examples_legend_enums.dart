
// todo-00-last : this should NOT be options. It is some kind of LegendAndItemLayoutEnumTesting
// todo-00-done : moved legend enum to this package here (lib/test/src)
enum LegendAndItemLayoutEnum  {

  legendIsRowStartTightItemIsRowStartTightDefault, // LegendOptions default: children created as [LegendItem]s in row which is start tight
  legendIsWrappingRowItemIsRowStartTight, // legend items wrap in row

  legendIsColumnStartLooseItemIsRowStartLoose , // See comment on legendIsColumnStartTightItemIsRowStartTight
  legendIsColumnStartTightItemIsRowStartTight, // legend items in column
  legendIsRowCenterLooseItemIsRowEndLoose, // Item row is not top = LegendAndItemLayoutEnum(XX), forced to 'start' = LegendAndItemLayoutEnum(XX), 'tight'  = LegendAndItemLayoutEnum(XX), so noop
  legendIsRowStartTightItemIsRowStartTightSecondGreedy, // second Item is greedy wrapped
  legendIsRowStartTightItemIsRowStartTightItemChildrenPadded,
  legendIsRowStartTightItemIsRowStartTightItemChildrenAligned,
}
