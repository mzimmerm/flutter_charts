
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:logger/logger.dart' as logger;

import '../container.dart' as old_container;

import 'container_common_new.dart' as container_common_new;
import 'axis_container_new.dart';
import 'data_container_new.dart';
import 'legend_container_new.dart';

import '../view_maker.dart';
import '../model/data_model_new.dart';
import '../iterative_layout_strategy.dart' as strategy;

class NewChartRootContainer extends container_common_new.ChartAreaContainer implements old_container.ChartRootContainer {

  NewChartRootContainer({
    required LegendContainer  legendContainer,
    required NewXContainer    xContainer,
    required NewYContainer    yContainer,
    required NewYContainer    yContainerFirst,
    required NewDataContainer dataContainer,
    required ChartViewMaker   chartViewMaker,
    required NewModel         chartData,
    required bool             isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(chartViewMaker: chartViewMaker) {
    logger.Logger().d('    Constructing NewChartRootContainer');
    // Attach children passed in constructor, previously created in Maker, to self


    // Create YDEX_cellDefinersRows, with definers arranged the same way as cells,
    //   - with 4 cells, in 2x2 arrangement
    //   - layoutSequence,  on each cell as we want
    List<List<TableLayoutCellDefiner>> YDEX_cellDefinersRows = [
      [TableLayoutCellDefiner(layoutSequence: 0), TableLayoutCellDefiner(layoutSequence: 3)],
      [TableLayoutCellDefiner(layoutSequence: 2), TableLayoutCellDefiner(layoutSequence: 1)],
    ];

    TableLayoutDefiner tableLayoutDefiner = TableLayoutDefiner(cellDefinersRows: YDEX_cellDefinersRows);

    // todo-00-last-last : create emptyContainer class and implementation - just a simple extension of ChartAreaContainer.
    // when done, put back use of ensureKeyedMembersHaveUniqueKeys.
    BoxContainer emptyContainer = xContainer;

    TableLayouter tableLayouter = TableLayouter(
        cellsTable: [
          [yContainer, dataContainer],
          [emptyContainer, xContainer],
        ],
        tableLayoutDefiner: tableLayoutDefiner);

    // Configure children, Legend on top, Table Layouter with X, Y, DataContainer below.
    addChildren([
      Column(
        children: [
          legendContainer,
          tableLayouter,
        ],
      )
    ]);
  }

/*
    super(
    legendContainer:                 legendContainer,
    xContainer:                      xContainer,
    yContainer:                      yContainer,
    yContainerFirst:                 yContainerFirst,
    dataContainer:                   dataContainer,
    ChartViewMaker chartViewMaker:   chartViewMaker,
    NewModel chartData:              chartData,
    isStacked:                       isStacked,
    xContainerLabelLayoutStrategy:   xContainerLabelLayoutStrategy,
    )
   */


/*
      : super(chartViewMaker: chartViewMaker) {
    logger.Logger().d('    Constructing ChartRootContainer');
    // Attach children passed in constructor, previously created in Maker, to self
    addChildren([legendContainer, xContainer, yContainer, dataContainer]);
  }
*/

  /// Override [BoxContainerHierarchy.isRoot] to prevent checking this root container on parent,
  /// which is never set on instances of this [ChartRootContainer].
  @override
  bool get isRoot => true;

  /// Number of columns in the [DataContainer].

  /// Base Areas of chart.
  /// todo-00!!!! All below declare the old containers. remove when completely separated, make this NewXContainer etc
  @override
  late LegendContainer legendContainer;
  @override
  late old_container.XContainer xContainer;
  @override
  late old_container.YContainer yContainer;
  @override
  late old_container.YContainer yContainerFirst;
  @override
  late old_container.DataContainer dataContainer;

  /// ##### Subclasses - aware members.

  @override
  late bool isStacked;


}
