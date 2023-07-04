import 'package:logger/logger.dart' as logger;

// This level
import 'package:flutter_charts/src/chart/cartesian/container/container_common.dart';
import 'package:flutter_charts/src/chart/cartesian/container/legend_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/axislabels_axislines_gridlines_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/data_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/axis_corner_container.dart';
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';

import 'package:flutter_charts/src/chart/view_model/view_model.dart';

// comments
import 'package:flutter_charts/src/chart/painter.dart';

/// The root [BoxContainer] of the whole chart.
///
/// Concrete [ChartRootContainer] instance is created new on every [FlutterChartPainter.paint] invocation
/// in the [ChartViewModel.chartRootContainerCreateBuildLayoutPaint]. Note that [ChartViewModel]
/// instance is created only once per chart, NOT recreated on every [FlutterChartPainter.paint] invocation.
///
/// Child containers calculate coordinates of chart points used for painting grid, labels, chart points etc.
///
class ChartRootContainer extends ChartAreaContainer {

  ChartRootContainer({
    required this.legendContainer,
    required this.horizontalAxisContainer,
    required this.verticalAxisContainer,
    required this.verticalAxisContainerFirst,
    required this.dataContainer,
    required ChartViewModel   chartViewModel,
  }) : super(chartViewModel: chartViewModel) {
    logger.Logger().d('    Constructing ChartRootContainer');
    // Attach children passed in constructor, previously created in ViewModel, to self

    // Create YDEX_cellDefinersTable, with definers arranged the same way as cells,
    //   - with 4 cells, in 2x2 arrangement
    //   - layoutSequence,  on each cell as we want

    // [vertAxisDefiner] : Definer for vertical axis container. Vertical axis determines the width
    //   of the first table column, and also the width left for the remainder of the table.
    // Note: Everything pre-layout is ordered by the sequence, actual layout by the cell positions in table
    TableLayoutCellDefiner vertAxisDefiner = TableLayoutCellDefiner(
      layoutSequence: 2,
      cellMinSizer: TableLayoutCellMinSizer.fromMinima(
        cellWidthMinimum: 65.0, // todo-012 will go away when we use VerticalAxisContainerFirst pre-layout
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

    BoxContainer axisCornerContainer = AxisCornerContainer(chartViewModel: chartViewModel);

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

  /// todo-012 The members are only needed during layout of deeper children (e.g., BarPointContainer) to access the members' sizes or constraints
  ///           Maybe we can remove the members and access them inside children by key??? LIKELY NOT BY KEY, BECAUSE, DUE TO SURRONDING MEMBERS IN
  ///           LAYOUT OBJECTS, THEY ARE NOT AMONG CHILDREN.
  /// Members that display the Areas of chart.
  late LegendContainer legendContainer;
  // covariant needed on some, probably not all
  covariant late TransposingAxisLabels horizontalAxisContainer;
  covariant late TransposingAxisLabels verticalAxisContainer;
  covariant late TransposingAxisLabels verticalAxisContainerFirst;
  covariant late DataContainer dataContainer;

  /// Override [BoxContainerHierarchy.isRoot] to prevent checking this root container on parent,
  /// which is never set on instances of this [ChartRootContainer].
  @override
  bool get isRoot => true;
}
