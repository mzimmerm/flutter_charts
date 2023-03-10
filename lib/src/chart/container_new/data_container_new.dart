import 'dart:ui' as ui show Size, Rect, Paint, Canvas;

// this level base libraries or equivalent
import '../../coded_layout/chart/presenter.dart'; // todo-00-last-last-last

import 'container_common_new.dart' as container_common_new;
import '../../coded_layout/chart/container.dart' as container;
import '../container_layouter_base.dart';
import '../model/data_model_new.dart' as model;
import '../view_maker.dart';
import '../container_edge_padding.dart';
import '../layouter_one_dimensional.dart';
import '../options.dart';
import '../../container/container_key.dart';
import '../../util/util_dart.dart';

class NewDataContainer extends container_common_new.ChartAreaContainer implements container.DataContainer {

  NewDataContainer({
    required ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker,
  );

  // todo-00-last-01 : why do we construct in buildAndReplaceChildre here, but in constuctor in NewYContainer???
  @override
  void buildAndReplaceChildren() {

    var options = chartViewMaker.chartOptions;
    var padGroup = ChartPaddingGroup(fromChartOptions: options);

    // Generate list of containers, each container represents one bar (chartViewMaker defines if horizontal or vertical)
    // This is the entry point where this container's [chartViewMaker] starts to generate this container (view).
    // todo-00!! move this up when higher containers converted to new.
    addChildren([
      Padder(
        edgePadding: EdgePadding.withSides(
          top: padGroup.heightPadTopOfYAndData(),
          bottom: padGroup.heightPadBottomOfYAndData(),
        ),
        child: Row(
          crossAxisAlign: Align.end, // cross axis is default matrjoska, non-default end aligned.
          children: chartViewMaker.makeViewsForDataAreaBars_As_CrossSeriesPoints_List(
            chartViewMaker,
            chartViewMaker.chartData.crossSeriesPointsList,
          ),
        ),
      ),
    ]);
  }

  // --------------- overrides to implement legacy vvvvv
  @override
  PointPresentersColumns get pointPresentersColumns => throw UnimplementedError();
  @override
  set pointPresentersColumns(PointPresentersColumns _) => throw UnimplementedError();
  @override
  List<PointPresenter> optionalPaintOrderReverse(List<PointPresenter> pointPresenters) => throw UnimplementedError();
  // --------------- overrides to implement legacy ^^^^^

  /* KEEP : comment out to allow ChartRootContainer.isUseOldDataContainer
  @override
  _NewSourceYContainerAndYContainerToSinkDataContainer findSourceContainersReturnLayoutResultsToBuildSelf() {
    return _NewSourceYContainerAndYContainerToSinkDataContainer(
      dataBarsCount: chartRootContainer.chartViewMaker.chartDataBarsCount,
    );
  }
  */

// void layout() - default
// void applyParentConstraints - default
// void applyParentOffset - default
// void paint(Canvas convas) - default
}

class NewCrossSeriesPointsContainer extends container_common_new.ChartAreaContainer {
  model.NewCrossSeriesPointsModel backingDataCrossSeriesPointsModel;

  NewCrossSeriesPointsContainer({
    required ChartViewMaker chartViewMaker,
    required this.backingDataCrossSeriesPointsModel,
    List<BoxContainer>? children,
    ContainerKey? key,
    // We want to proportionally (evenly) layout if wrapped in Column, so make weight available.
    required ConstraintsWeight constraintsWeight,
  }) : super(
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
    constraintsWeight: constraintsWeight,
  );
}

class NewPointContainer extends container_common_new.ChartAreaContainer {
  model.NewPointModel newPointModel;

  NewPointContainer({
    required this.newPointModel,
    required ChartViewMaker chartViewMaker,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );
}

/// See [LegendIndicatorRectContainer] for similar implementation.
///
/// todo-00-last-00 : For some new containers (those that need to be sized from values to pixels),
///                          add an interface that expresses: This is the provided of 'toPixelsMax', 'toPixelsMin' - basically the domain (scope) to which we extrapolate
///                          Maybe the interface should provide: direction (vertical, horizontal), boolean verticalProvided, horizontal provided, and Size - valued object for each direction (if boolean says so)
///                          For children of NewDataContainer, it will be NewDataContainer.constraints.
///                          For children of YContainer, it will be YContainer.constraints (???)
///                          Generally it must be an object that is known at layout time, and will not change - for example last cell in table,
class NewHBarPointContainer extends NewPointContainer {

  /// The rectangle representing the value.
  ///
  /// It's height represents [newPointModel.dataValue] extrapolated from the value range to the
  /// pixel height available for data in the vertical direction.
  ///
  /// It's size should be calculated in [layout], and used in [paint];
  late final ui.Size _rectangleSize;

  NewHBarPointContainer({
    required model.NewPointModel newPointModel,
    required ChartViewMaker chartViewMaker,
    // todo-00!! Do we need children and key? LineSegmentContainer does not have it.
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    newPointModel: newPointModel,
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  @override
  void layout() {
    buildAndReplaceChildren();
    // Calculate [_indicatorSize], the width and height of the Rectangle that represents data:

    // Rectangle width is from constraints
    double width = constraints.width;

    // Rectangle height is Y extrapolated from newPointModel.dataValue using chartRootContainer.yLabelsGenerator
    Interval yDataRange = chartViewMaker.yLabelsGenerator.dataRange;

    // todo-00-last-00 : Using the ownerDataContainerConstraints, and the padGroup this deep is VERY SUSPECT.
    //                   WE NEED TO USE A KIND OF 'CONSTRAINTS-TO-WHICH-DATA-EXPAND,
    //                   ON NewXContainer, NewYContainer and NewDataContainer.
    //                   BASICALLY WE NEED TO KNOW THE EXACT CONTAINER IN THE HIERARCHY,
    //                   TO WHICH DATA WILL EXPAND, SO WE CAN ENSURE THEY ARE THE SAME SIZE
    //                   BUT HOW TO DO THIS ??? PERHAPS WE NEED AN ARTIFICIAL MARKER ON ALL LAYOUTERS, WHICH
    //                   IF SET, RUN A HOOK IN THEIR LAYOUT - ONCE CONSTRAINT IS SET ON SUCH CONTAINER,
    //                   IT WILL SET A SPECIAL MEMBER ON ROOT FOR DATA CONTAINER DATA AVAILABLE HEIGHT AND WIDTH,
    //                   WHICH ALSO DRIVE X AND YCONTAINER DATA AVAILABLE HEIGHT AND WIDTH ???
    //
    //                   ANOTHER OPTION IS TO USE THE EXTERNAL TICKS **RANGE** FOR X AND Y; AND SAME FOR DATA CONTAINER
    //                   BUT AGAin, details ???
    //
    // Decided on solution: - Add a 'void' extension to BoxContainer, called DataPixelsScope (enum: height, width, heightAndWidth)
    //                      - This extension will override applyParentConstraint, where it will take the height, width, or both
    //                        and set it on root of container hierarchy on member Size pixelsScope.
    //                      - todo-00-last-00 : finish this thought and implementation
    var ownerDataContainerConstraints = chartViewMaker.chartRootContainer.dataContainer.constraints;

    var padGroup = ChartPaddingGroup(fromChartOptions: chartViewMaker.chartOptions);

    var lextr = ToPixelsExtrapolation1D(
      fromValuesMin: yDataRange.min,
      fromValuesMax: yDataRange.max,
      // HERE WE USE THE KNOWLEDGE THAT THE TOP OF DATA CONTAINER IS A PADDER WITH THIS EXACT PADDING.
      // SEE COMMENTS ABOVE.
      toPixelsMax: ownerDataContainerConstraints.size.height - padGroup.heightPadBottomOfYAndData(),
      toPixelsMin: padGroup.heightPadTopOfYAndData(),
    );

    // Extrapolate the absolute value of data to height of the rectangle, representing the value in pixels.
    // We convert data to positive positive size, the direction above/below axis is determined by layouters.
    double height = lextr.applyAsLength(newPointModel.dataValue.abs());

    // print('height=$height, value=${newPointModel.dataValue.abs()}, '
    //     'dataRange.min=${yLabelsGenerator.dataRange.min}, dataRange.max=${yLabelsGenerator.dataRange.max}'
    //     'yContainer.axisPixelsRange.min=${yContainer.axisPixelsRange.min}, yContainer.axisPixelsRange.max=${yContainer.axisPixelsRange.max}');

    _rectangleSize = ui.Size(width, height);

    layoutSize = _rectangleSize;
  }

  @override paint(ui.Canvas canvas) {

    ui.Rect rect = offset & _rectangleSize;

    // Rectangle color should be from newPointModel's color.
    ui.Paint paint = ui.Paint();
    paint.color = newPointModel.color;

    canvas.drawRect(rect, paint);
  }
}

/* KEEP : comment out to allow ChartRootContainer.isUseOldDataContainer
class _NewSourceYContainerAndYContainerToSinkDataContainer {
  final int dataBarsCount;

  _NewSourceYContainerAndYContainerToSinkDataContainer({
    required this.dataBarsCount,
  });
}
*/
