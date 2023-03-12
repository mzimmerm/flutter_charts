import 'package:logger/logger.dart' as logger;

import 'container_common_new.dart' as container_common_new;
import 'legend_container_new.dart';
import 'axis_container_new.dart';
import 'data_container_new.dart';
import '../container_layouter_base.dart';
import '../container_new/axis_corner_container.dart';

import '../view_maker.dart';
import '../model/data_model_new.dart';
import '../iterative_layout_strategy.dart' as strategy;

// todo-00-last-last-done : class NewChartRootContainer extends container_common_new.ChartAreaContainer implements old_container.ChartRootContainerCL {
class NewChartRootContainer extends container_common_new.ChartAreaContainer {

  NewChartRootContainer({
    required this.legendContainer,
    required this.xContainer,
    required this.yContainer,
    required this.yContainerFirst,
    required this.dataContainer,
    required ChartViewMaker   chartViewMaker,
    required NewModel         chartData,
    required bool             isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(chartViewMaker: chartViewMaker) {
    logger.Logger().d('    Constructing NewChartRootContainer');
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

  /// Override [BoxContainerHierarchy.isRoot] to prevent checking this root container on parent,
  /// which is never set on instances of this [ChartRootContainer].
  @override
  bool get isRoot => true;

  /// Number of columns in the [DataContainer].

  /// todo-00-! The members are only needed during layout of deeper children (e.g., NewHBarPointContainer) to access the members' sizes or constraints
  ///           Maybe we can remove the members and access them inside children by key??? LIKELY NOT BY KEY, BECAUSE, DUE TO SURRONDING MEMBERS IN
  ///           LAYOUT OBJECTS, THEY ARE NOT AMONG CHILDREN.
  /// Members that display the Areas of chart.
  /// todo-00-later : change those to new containers - or remove them entirely :  All below declare the old containers. remove when completely separated, make this NewXContainer etc
  /// todo-00-later : these containers are never used in the NEW NewChartRootContainer. Maybe comment them out??
/* todo-00-last-last-done : converted members to new auto layout
  late LegendContainer legendContainer;
  late old_container.XContainerCL xContainer;
  late old_container.YContainerCL yContainer;
  late old_container.YContainerCL yContainerFirst;
  late old_container.DataContainerCL dataContainer;
*/
  late LegendContainer legendContainer;
  covariant late NewXContainer xContainer;
  covariant late NewYContainer yContainer;
  covariant late NewYContainer yContainerFirst;
  covariant late NewDataContainer dataContainer;

  /// ##### Subclasses - aware members.

/* todo-00-last-last-done :
  // --------------- overrides to implement legacy vvvvv
  @override
  late bool isStacked;
  @override
  double get xGridStep => throw UnimplementedError();
  @override
  List<double> get xTickXs => throw UnimplementedError();
  @override
  List<double> get yTickYs => throw UnimplementedError();
  // --------------- overrides to implement legacy ^^^^^
 */

}
