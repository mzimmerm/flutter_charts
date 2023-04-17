import 'package:logger/logger.dart' as logger;

import 'container_common.dart' as container_common;
import 'legend_container.dart';
import 'axis_container.dart';
import 'data_container.dart';
import '../../morphic/container/container_layouter_base.dart';
import '../container/axis_corner_container.dart';
import '../view_maker.dart';
import '../model/data_model.dart';
import '../iterative_layout_strategy.dart' as strategy;
// import '../../morphic/container/layouter_one_dimensional.dart';

class ChartRootContainer extends container_common.ChartAreaContainer {

  ChartRootContainer({
    required this.legendContainer,
    required this.horizontalAxisContainer,
    required this.verticalAxisContainer,
    required this.verticalAxisContainerFirst,
    required this.dataContainer,
    required ChartViewMaker   chartViewMaker,
    required ChartModel         chartModel,
    required bool             isStacked,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super(chartViewMaker: chartViewMaker) {
    logger.Logger().d('    Constructing ChartRootContainer');
    // Attach children passed in constructor, previously created in Maker, to self

    // Create YDEX_cellDefinersTable, with definers arranged the same way as cells,
    //   - with 4 cells, in 2x2 arrangement
    //   - layoutSequence,  on each cell as we want

    // [vertAxisDefiner] : Definer for vertical axis container. Vertical axis determines the width
    //   of the first table column, and also the width left for the remainder of the table.
    // todo-01-doc : is it true that everything pre-layout goes by the sequence, actual layout by the table positions?
    TableLayoutCellDefiner vertAxisDefiner = TableLayoutCellDefiner(
      layoutSequence: 2,
      cellMinSizer: TableLayoutCellMinSizer.fromMinima(
        cellWidthMinimum: 65.0, // todo-01 will go away when we use VerticalAxisContainerFirst pre-layout
        cellHeightMinimum: 0.0,
      ),
    );

    // [YDEX_cellDefinersTable] is table with the following order of containers (left to right, top to bottom):
    //   VerticalAxisContainer, DataContainer, EmptyAxisCornerContainer, HorizontalAxisContainer
    List<List<TableLayoutCellDefiner>> YDEX_cellDefinersTable = [
      [vertAxisDefiner, TableLayoutCellDefiner(layoutSequence: 3)],
      [TableLayoutCellDefiner(layoutSequence: 1), TableLayoutCellDefiner(layoutSequence: 0)],
    ];

    TableLayoutDefiner tableLayoutDefiner = TableLayoutDefiner(
      cellDefinersTable: YDEX_cellDefinersTable,
      cellsAlignerDefiner: ChartTableLayoutCellsAlignerDefiner.sizeOf( // or just 2x2
        cellDefinersTable: YDEX_cellDefinersTable,
      ),
    );

    BoxContainer axisCornerContainer = AxisCornerContainer(chartViewMaker: chartViewMaker);

    // verticalAxisContainer and horizontalAxisContainer are already transposed during creation.
    TableLayouter chartBody = TableLayouter(
      tableLayoutDefiner: tableLayoutDefiner,
      cellsTable: [
        [verticalAxisContainer, dataContainer],
        [axisCornerContainer, horizontalAxisContainer],
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

  /// todo-01-last The members are only needed during layout of deeper children (e.g., NewVBarPointContainer) to access the members' sizes or constraints
  ///           Maybe we can remove the members and access them inside children by key??? LIKELY NOT BY KEY, BECAUSE, DUE TO SURRONDING MEMBERS IN
  ///           LAYOUT OBJECTS, THEY ARE NOT AMONG CHILDREN.
  /// Members that display the Areas of chart.
  late LegendContainer legendContainer;
  covariant late TransposingAxisContainer horizontalAxisContainer;
  covariant late TransposingAxisContainer verticalAxisContainer;
  covariant late TransposingAxisContainer verticalAxisContainerFirst;
  covariant late DataContainer dataContainer;

  /// Override [BoxContainerHierarchy.isRoot] to prevent checking this root container on parent,
  /// which is never set on instances of this [ChartRootContainer].
  @override
  bool get isRoot => true;
}
