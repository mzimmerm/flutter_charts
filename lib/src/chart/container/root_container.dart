import 'package:logger/logger.dart' as logger;

import 'container_common.dart' as container_common_new;
import 'legend_container.dart';
import 'axis_container.dart';
import 'data_container.dart';
import '../../morphic/container/container_layouter_base.dart';
import '../container/axis_corner_container.dart';

import '../view_maker.dart';
import '../model/data_model.dart';
import '../iterative_layout_strategy.dart' as strategy;

class ChartRootContainer extends container_common_new.ChartAreaContainer {

  ChartRootContainer({
    required this.legendContainer,
    required this.xContainer,
    required this.yContainer,
    required this.yContainerFirst,
    required this.dataContainer,
    required ChartViewMaker   chartViewMaker,
    required ChartModel         chartModel,
    required bool             isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(chartViewMaker: chartViewMaker) {
    logger.Logger().d('    Constructing ChartRootContainer');
    // Attach children passed in constructor, previously created in Maker, to self

    // Create YDEX_cellDefinersTable, with definers arranged the same way as cells,
    //   - with 4 cells, in 2x2 arrangement
    //   - layoutSequence,  on each cell as we want
    // todo-00-doc : is it true that everything pre-layout goes by the sequence, actual layout by the table positions?
    TableLayoutCellDefiner yDefiner = TableLayoutCellDefiner(
      layoutSequence: 2,
      cellMinSizer: TableLayoutCellMinSizer.fromMinima(
        cellWidthMinimum: 65.0, // todo-00-last-02 will go away when we use YContainerFirst pre-layout
        cellHeightMinimum: 0.0,
      ),
    );

    List<List<TableLayoutCellDefiner>> YDEX_cellDefinersTable = [
      [yDefiner, TableLayoutCellDefiner(layoutSequence: 3)],
      [TableLayoutCellDefiner(layoutSequence: 1), TableLayoutCellDefiner(layoutSequence: 0)],
    ];

    TableLayoutDefiner tableLayoutDefiner = TableLayoutDefiner(
      cellDefinersTable: YDEX_cellDefinersTable,
      cellsAlignerDefiner: ChartTableLayoutCellsAlignerDefiner.sizeOf( // or just 2x2
        cellDefinersTable: YDEX_cellDefinersTable,
      ),
    );

    BoxContainer axisCornerContainer = AxisCornerContainer(chartViewMaker: chartViewMaker);

    TableLayouter chartBody = TableLayouter(
      tableLayoutDefiner: tableLayoutDefiner,
      cellsTable: [
        [yContainer, dataContainer],
        [axisCornerContainer, xContainer],
      ],
    );

    // Configure children, Legend on top, Table Layouter with X, Y, DataContainer below.
    addChildren(
      [
        TableLayouter(
          tableLayoutDefiner: TableLayoutDefiner.defaultRowWiseForTableSize(
            numRows: 2,
            numColumns: 1,
          ),
          cellsTable: [
            [legendContainer],
            [chartBody],
          ],
        ),
      ],
    );
  }

  /// todo-00-! The members are only needed during layout of deeper children (e.g., NewHBarPointContainer) to access the members' sizes or constraints
  ///           Maybe we can remove the members and access them inside children by key??? LIKELY NOT BY KEY, BECAUSE, DUE TO SURRONDING MEMBERS IN
  ///           LAYOUT OBJECTS, THEY ARE NOT AMONG CHILDREN.
  /// Members that display the Areas of chart.
  late LegendContainer legendContainer;
  covariant late XContainer xContainer;
  covariant late YContainer yContainer;
  covariant late YContainer yContainerFirst;
  covariant late DataContainer dataContainer;

  /// Override [BoxContainerHierarchy.isRoot] to prevent checking this root container on parent,
  /// which is never set on instances of this [ChartRootContainer].
  @override
  bool get isRoot => true;
}
