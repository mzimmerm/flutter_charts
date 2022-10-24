import 'dart:ui' show Size;

import 'package:flutter_charts/src/chart/container_layouter_base.dart';

import '../../chart/layouter_one_dimensional.dart';

class ContainerConstraints {
}

/// Defines how a container [layout] should expand the container in a direction.
///
/// Direction can be "width" or "height".
/// Generally,
/// - If direction style is [TryFill], the container should use all
///   available length in the direction (that is, [width] or [height].
///   This is intended to fill a predefined
///   available length, such as when showing X axis labels
/// - If direction style is [GrowDoNotFill], container should use as much space
///   as needed in the direction, but stop "well before" the available length.
///   The "well before" is not really defined here.
///   This is intended to for example layout Y axis in X direction,
///   where we want to put the data container to the right of the Y labels.
/// - If direction style is [Unused], the [layout] should fail on attempted
///   looking at such
///   todo-01-document

class BoxContainerConstraints extends ContainerConstraints {
  final Size minSize;
  final Size maxSize;

  // Named constructors
  BoxContainerConstraints({required this.minSize, required this.maxSize,});
  BoxContainerConstraints.exactBox({required Size size}) : this(minSize: size, maxSize: size,);
  BoxContainerConstraints.insideBox({required Size size}) : this(minSize: Size.zero, maxSize: size,);
  BoxContainerConstraints.outsideBox({required Size size}) : this(minSize: size, maxSize: Size.infinite,);

  // todo-01-last : Add a singleton member unusedConstraints, initialized with this and set as const. Then this constructor can be private ?
  /// Named constructor for unused expansion
  BoxContainerConstraints.unused()
      : this.exactBox(size: const Size(
    -1.0,
    -1.0,
  ));
  BoxContainerConstraints.infinity()
      : this.insideBox(size: const Size(
    double.infinity,
    double.infinity,
  ));

  Size get size {
    if (isInside) {
      return maxSize;
    } else {
      throw StateError('not implemented other boxes, minSize = $minSize, maxSize = $maxSize');
      }
  }
  
  bool get isExact => minSize == maxSize;

  bool get isInside => minSize.width < maxSize.width && minSize.height < maxSize.height;

  bool containsFully(Size size) {
    return size.width <= maxSize.width && size.height <= maxSize.height
        && size.width >= minSize.width && size.height >= minSize.height;
  }

  Size maxSizeLeftAfterTakenFromAxisDirection(Size takenSize, LayoutAxis layoutAxis) {
    if (!containsFully(takenSize)) {
      throw StateError('This constraints $toString() does not fully contain takenSize=$takenSize');
    }
    Size size;
    switch (layoutAxis) {
      case LayoutAxis.horizontal:
        // Make place right from takenSize. This should be layout specific, maybe
        size = Size(maxSize.width - takenSize.width, maxSize.height);
        assert(containsFully(size));
        break;
      case LayoutAxis.vertical:
      // Make place below from takenSize. This should be layout specific, maybe
        size = Size(maxSize.width, maxSize.height - takenSize.height);
        assert(containsFully(size));
        break;
    }
    return size;
  }

  double maxLengthAlongAxis(LayoutAxis layoutAxis) {
    switch (layoutAxis) {
      case LayoutAxis.horizontal:
        return maxSize.width;
      case LayoutAxis.vertical:
        return maxSize.height;
    }
  }

  // todo-00-done
  /// Divide this constraint into 'smaller' constraints depending on strategy.
  ///
  /// The sizes of the returned constraint list are smaller along the direction of the passed [layoutAxis];
  /// cross-sizes remain the same as this constraint.
  ///
  /// Used to pass smaller constraints to children.
  List<BoxContainerConstraints> divideUsingStrategy({
    required int divideIntoCount,
    required DivideConstraintsToChildren divideStrategy,
    required LayoutAxis layoutAxis,
    List<double>? ratios,
  }) {
    double minWidth, minHeight, maxWidth, maxHeight;

    if (divideStrategy == DivideConstraintsToChildren.ratios && ratios == null) {
      throw StateError('ratios only applicable for DivideConstraintsToChildren.ratio');
    }

    if ((divideStrategy == DivideConstraintsToChildren.evenly ||
            divideStrategy == DivideConstraintsToChildren.evenly) &&
        ratios != null) {
      throw StateError('ratios not applicable for DivideConstraintsToChildren.evenly or noDivide');
    }

    if (ratios != null) {
      assert(ratios!.length == divideIntoCount);
      double sumRatios = ratios!.fold<double>(0.0, (previousValue, element) => previousValue + element);
      assert(0.99 <= sumRatios && sumRatios <= 1.01);
    }

    switch (divideStrategy) {
      case DivideConstraintsToChildren.evenly:
        switch (layoutAxis) {
          case LayoutAxis.horizontal:
            minWidth = minSize.width / divideIntoCount;
            minHeight = minSize.height;
            maxWidth = maxSize.width / divideIntoCount;
            maxHeight = maxSize.height;
            break;
          case LayoutAxis.vertical:
            minWidth = minSize.width;
            minHeight = minSize.height / divideIntoCount;
            maxWidth = maxSize.width;
            maxHeight = maxSize.height / divideIntoCount;
            break;
        }
        List<BoxContainerConstraints> fractions = [];
        for (int i = 0; i < divideIntoCount; i++) {
          var fraction = cloneWith(
            minWidth: minWidth,
            minHeight: minHeight,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          );
          fractions.add(fraction);
        }
        return fractions;
      case DivideConstraintsToChildren.ratios:
        List<BoxContainerConstraints> fractions = [];
        for (double ratio in ratios!) {
          switch (layoutAxis) {
            case LayoutAxis.horizontal:
              minWidth = minSize.width * ratio;
              minHeight = minSize.height;
              maxWidth = maxSize.width * ratio;
              maxHeight = maxSize.height;
              break;
            case LayoutAxis.vertical:
              minWidth = minSize.width;
              minHeight = minSize.height * ratio;
              maxWidth = maxSize.width;
              maxHeight = maxSize.height * ratio;
              break;
          }
          var fraction = cloneWith(
            minWidth: minWidth,
            minHeight: minHeight,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          );
          fractions.add(fraction);
        }
        return fractions;
      case DivideConstraintsToChildren.noDivide:
        return [clone()];
    }
  }

  /// Clone of this object with different size.
  BoxContainerConstraints cloneWith({
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
  }) {
    minWidth ??= minSize.width;
    minHeight ??= minSize.height;
    maxWidth ??= maxSize.width;
    maxHeight ??= maxSize.height;

    return BoxContainerConstraints(
      minSize: Size(minWidth, minHeight),
      maxSize: Size(maxWidth, maxHeight),
    );
  }

  BoxContainerConstraints clone() {
    return cloneWith();
  }

  @override
  String toString() {
    return '${runtimeType.toString()}: minSize=$minSize, maxSize=$maxSize';
  } 
}
