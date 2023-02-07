import 'dart:ui' as ui show Size, Rect, Paint, Canvas;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart';
import 'package:flutter_charts/src/chart/model/new_data_model.dart';

import '../container/container_key.dart';

// todo-01-switch-from-command-arg class NewDataContainer extends ChartAreaContainer with BuilderOfChildrenDuringParentLayout {
class NewDataContainer extends DataContainer {
  // constructor:
  // create with all children: List<NewValuesColumnContainer> + ChartRootContainer

  NewDataContainer({
    required ChartRootContainer chartRootContainer,
    // required List<BoxContainer> children,
  }) : super(
    chartRootContainer: chartRootContainer,
    //children: children,
  );

  @override
  void buildAndAddChildren_DuringParentLayout() {

   NewDataModel dataModel = chartRootContainer.data;

   List<NewValuesColumnContainer>  viewColumnList = dataModel.generateViewChildrenAsNewValuesColumnContainerList(chartRootContainer);

    addChildren([
      Row(
        children: viewColumnList,
        crossAxisAlign: Align.end, // cross axis is default matrjoska, non-default end aligned.
      )
    ]);
  }

  /* KEEP : comment out to allow ChartRootContainer.isUseOldDataContainer
  @override
  _NewSourceYContainerAndYContainerToSinkDataContainer findSourceContainersReturnLayoutResultsToBuildSelf() {
    return _NewSourceYContainerAndYContainerToSinkDataContainer(
      dataColumnsCount: chartRootContainer.dataColumnsCount,
    );
  }
  */

// void layout() - default
// void applyParentConstraints - default
// void applyParentOffset - default
// void paint(Canvas convas) - default
}

class NewValuesColumnContainer extends ChartAreaContainer {
  NewDataModelSameXValues backingDataModelSameXValues;

  NewValuesColumnContainer({
    required ChartRootContainer chartRootContainer,
    required this.backingDataModelSameXValues,
    List<BoxContainer>? children,
    ContainerKey? key,
    // We want to proportionally (evenly) layout if wrapped in Column, so make weight available.
    required ConstraintsWeight constraintsWeight,
  }) : super(
    chartRootContainer: chartRootContainer,
    children: children,
    key: key,
    constraintsWeight: constraintsWeight,
  );
}

class NewValueContainer extends ChartAreaContainer {
  NewDataModelPoint dataModelPoint;

  NewValueContainer({
    required ChartRootContainer chartRootContainer,
    required this.dataModelPoint,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartRootContainer: chartRootContainer,
    children: children,
    key: key,
  );
}

/// See [LegendIndicatorRectContainer] for similar implementaion
class NewValueHBarContainer extends NewValueContainer {

  /// The rectangle representing the value.
  ///
  /// It's height represents [dataModelPoint.dataValue] scaled from the value range to the
  /// pixel height available for data in the vertical direction.
  ///
  /// It's size should be calculated in [layout], and used in [paint];
  late final ui.Size _rectangleSize;

  NewValueHBarContainer({
    required ChartRootContainer chartRootContainer,
    required NewDataModelPoint dataModelPoint,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    dataModelPoint: dataModelPoint,
    chartRootContainer: chartRootContainer,
    children: children,
    key: key,
  );

  @override
  void layout() {
    // Calculate [_indicatorSize], the width and height of the Rectangle that represents data:

    // Rectangle width is from constraints
    double width = constraints.width;

    // Rectangle height is Y scaled from dataModelPoint.dataValue using chartRootContainer.yLabelsCreator
    YLabelsCreatorAndPositioner scaler = chartRootContainer.yContainer.yLabelsCreator; // todo-00-last-last-last-last : dataModelPoint.ownerSameXValuesList.dataModel.yLabelsCreator;
    // double height = scaler.scaleY(value: dataModelPoint.dataValue);

    // todo-00-last-last : in new layout,
    //    - don't use scaler to get fromDomainMin, fromDomainMax, because it uses the full machinery of StackableValuePoint
    //       - d instead, use NewDataModelPoint : add stackedDataValue, build it in NewDataModelSameXValues.
    //       - d then, add on NewDataModelSameXValues instances, method columnStackedDataValue that will get it from children.
    //       - todo after, add on NewDataModel method _newMergedLabelYsIntervalWithDataYsEnvelope:
    //          - todo for stacked, returns (still legacy) interval LabelYsInterval merged with envelope of columnStackedDataValue
    //       - todo then the _newMergedLabelYsIntervalWithDataYsEnvelope will be used to set fromDomainMin and fromDomainMax for extrapolation
    //
    //   - todo dont use scaler to get toDomainMin, toDomainMax, because that links to yContainer.
    //     - Instead, use toDomainMin=0.0 as that is in NewDataContainer coordinates
    //     -          use toDomainMax=NewDataContainer.constraints.height to tie it to local 0-based pixels, for extrapolation on the TO domain!
    //
    //   ?????? data envelope should be calculated from midpoint of min/max labels after laying out Y axis, and scaled to Y axis constraint height.
    //   For example, if all positive: If smallest label is 0M at pixel 1000, largest label is 10M at pixel 100, and Y axis constraint.height = 1200,
    //   the result should be to scale (1200 - (1000 - 100)) (free length of pixels) using scaleBy = (1000 - 100) / (10M - 0M) - this is the corresponding
    //     free length of data values, which should be added to the 0M - 10M domain - actually, this should be done separately on bottom and top, taking into account if values go across zero!!

    //  double get fromDomainMin => _mergedLabelYsIntervalWithDataYsEnvelope.min;
    //   double get fromDomainMax => _mergedLabelYsIntervalWithDataYsEnvelope.max;
    //   double get toDomainMin => 0.0;
    //   double get toDomainMax => _axisY.max - _axisY.min;

    YContainer yContainer = chartRootContainer.yContainer;

    // todo-00-last-last : remove dependence on pixels (toDomain)
    var transform = DomainExtrapolation1D.valuesToPixels(
      fromValuesStart: scaler.mergedIntervalsFromLabelsAndValues.min, // scaler.fromDomainMin,
      fromValuesEnd: scaler.mergedIntervalsFromLabelsAndValues.max, // scaler.fromDomainMax,
      toPixelsStart: yContainer.yContainerAxisPixelsYMin, // scaler.toDomainMin,
      toPixelsEnd: yContainer.yContainerAxisPixelsYMin,
    ); // scaler.toDomainMax,);
    double height = transform.apply(dataModelPoint.dataValue);

    _rectangleSize = ui.Size(width, height);

    layoutSize = _rectangleSize;
  }

  @override paint(ui.Canvas canvas) {

    ui.Rect rect = offset & _rectangleSize;

    // Rectangle color should be from dataModelPoint's color.
    ui.Paint paint = ui.Paint();
    paint.color = dataModelPoint.color;

    canvas.drawRect(rect, paint);
  }
}

/* KEEP : comment out to allow ChartRootContainer.isUseOldDataContainer
class _NewSourceYContainerAndYContainerToSinkDataContainer {
  final int dataColumnsCount;

  _NewSourceYContainerAndYContainerToSinkDataContainer({
    required this.dataColumnsCount,
  });
}
*/
