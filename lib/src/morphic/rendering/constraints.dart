import 'dart:ui' show Size;
import 'dart:math' show Rectangle;

import 'package:flutter_charts/src/chart/container_layouter_base.dart';

import '../../chart/layouter_one_dimensional.dart';

class ContainerConstraints {}

/// Represents sizes of two centered boxes.
///
/// 
/// Objects of this class's extensions allow two core roles:
///   - Role of a constraint that a parent in a layout hierarchy requires of it's children.
///     This is used in the current one-pass layout.
///   - Role of a layout size 'wiggle room' a child offers to it's parent when laying out using a two pass layout.
///     This could be used it a future two pass layout.
abstract class BoundingBoxesBase {
  late final Size minSize;
  late final Size maxSize;

  // The SINGLE UNNAMED generative constructor
  BoundingBoxesBase({
    required this.minSize,
    required this.maxSize,
  });

  // Named constructors, forwarded to the generative constructor
  BoundingBoxesBase.exactBox({required Size size}) : this(minSize: size, maxSize: size);
  BoundingBoxesBase.insideBox({required Size size}) : this(minSize: Size.zero, maxSize: size);
  BoundingBoxesBase.outsideBox({required Size size}) : this(minSize: size, maxSize: Size.infinite);
  // todo-01-last : Add a singleton member unusedConstraints, initialized with this and set as const. Then this constructor can be private ?
  /// Named constructor for unused expansion
  BoundingBoxesBase.unused() : this.exactBox(size: const Size(-1.0, -1.0));
  BoundingBoxesBase.infinity() : this.insideBox(size: const Size(double.infinity, double.infinity));

  // ### Prototype design pattern for cloning - cloneOther constructor used in clone extensions

  /// Generative named constructor from the passed other [BoundingBoxesBase], for cloning
  /// using the Prototype pattern.
  BoundingBoxesBase.cloneOther({required BoundingBoxesBase other}) {
    // set members of the newly created instance from the passed other BoundingBoxesBase
    minSize = other.minSize;
    maxSize = other.maxSize;
  }

  /// Abstract method for cloning, using the prototype pattern to share
  /// cloning implementation with superclasses.
  ///
  /// Used along with the generative named constructor [BoundingBoxesBase.cloneOther].
  /// In the extensions [clone] returns newly constructed BoundingBoxesBase extensions
  /// using the concrete [cloneOther] named constructor
  /// and passing `this` to it.
  BoundingBoxesBase clone();

  // The cloneOtherWith family is implemented similar to [BoundingBoxesBase.cloneOther] + [clone]
  // BUT the [cloneWith] cannot be abstract, as extensions need more parameters.

  /// Generative named constructor from other [BoundingBoxesBase] and values to change
  /// on the clone.
  BoundingBoxesBase.cloneOtherWith({
    required BoundingBoxesBase other,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
  }) {
    // set members of the newly created instance from parameters, if null,
    // from the passed [other] box
    minWidth ??= other.minSize.width;
    minHeight ??= other.minSize.height;
    maxWidth ??= other.maxSize.width;
    maxHeight ??= other.maxSize.height;

    minSize = Size(minWidth, minHeight);
    maxSize = Size(maxWidth, maxHeight);
  }

  /// [cloneWith] method implementation.
  /// Returns instance created by the [BoxContainerConstraints.cloneOtherWith] constructor
  BoundingBoxesBase cloneWith({
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
  });

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
    return size.width <= maxSize.width &&
        size.height <= maxSize.height &&
        size.width >= minSize.width &&
        size.height >= minSize.height;
  }

  /* todo-00-last : I am making assumption the greedy processing needs to be replaced,
                             so ignore what is called here. Does that simplify move to non-offsetting?
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
  */

  double maxLengthAlongAxis(LayoutAxis layoutAxis) {
    switch (layoutAxis) {
      case LayoutAxis.horizontal:
        return maxSize.width;
      case LayoutAxis.vertical:
        return maxSize.height;
    }
  }

  /// Divide this [BoundingBoxesBase] into a list of 'smaller' [BoundingBoxesBase]s objects,
  /// depending on the dividing strategy [DivideConstraintsToChildren].
  ///
  /// The sizes of the returned constraint list are smaller along the direction of the passed [layoutAxis];
  /// cross-sizes remain the same as this constraint.
  ///
  /// Extensions use this method to pass smaller constraints to children; use for layout sizes
  /// is unclear atm.
  List<BoundingBoxesBase> divideUsingStrategy({
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
      assert(ratios.length == divideIntoCount);
      double sumRatios = ratios.fold<double>(0.0, (previousValue, element) => previousValue + element);
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
        List<BoundingBoxesBase> fractions = [];
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
        List<BoundingBoxesBase> fractions = [];
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

  @override
  String toString() {
    return '${runtimeType.toString()}: minSize=$minSize, maxSize=$maxSize';
  }
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

class BoxContainerConstraints extends BoundingBoxesBase {

  /// Expresses if it was created for the very top [RowLayouter] or [ColumnLayoter].
  ///
  /// It is used to control ability of [RowLayouter] or [ColumnLayouter] to set [Lineup] (alignment) other
  /// then [Lineup.start]
  bool isOnTop = false;

  /// The SINGLE UNNAMED generative constructor.
  /// must call super, super initializes fields in BoundingBoxesBase
  BoxContainerConstraints({
    required minSize,
    required maxSize,
  }) : super(minSize: minSize, maxSize: maxSize);

  // Named constructors, forwarded to the generative constructor
  BoxContainerConstraints.exactBox({required Size size}) : this(minSize: size, maxSize: size);
  BoxContainerConstraints.insideBox({required Size size}) : this(minSize: Size.zero, maxSize: size);
  BoxContainerConstraints.outsideBox({required Size size}) : this(minSize: size, maxSize: Size.infinite);
  // todo-01-last : Add a singleton member unusedConstraints, initialized with this and set as const. Then this constructor can be private ?
  /// Named constructor for unused expansion
  BoxContainerConstraints.unused() : this.exactBox(size: const Size(-1.0, -1.0));
  BoxContainerConstraints.infinity() : this.insideBox(size: const Size(double.infinity, double.infinity));

  // ### Prototype design pattern for cloning - cloneOther constructor used in clone extensions

  /// Generative named constructor, from other constraint.
  ///
  /// The initializer list initializes the added field [isOnTop],
  ///   followed by a call to super which initializes the common fields,
  BoxContainerConstraints.cloneOther(BoxContainerConstraints other)
      : isOnTop = other.isOnTop, super.cloneOther(other: other);

  /// [clone] method implementation.
  /// Returns instance created by the [BoxContainerConstraints.cloneOther] constructor.
  @override
  BoxContainerConstraints clone() {
    return BoxContainerConstraints.cloneOther(this);
  }

  // The [cloneOtherWith] family is implemented similar to [BoundingBoxesBase.cloneOther] + [clone]
  // BUT the [cloneWith] cannot be abstract, as extensions need more parameters.

  /// Generative named constructor, from the passed [BoxContainerConstraints] [other].
  /// Call super to initialize common fields, then initialize the added field
  BoxContainerConstraints.cloneOtherWith({
    required BoxContainerConstraints other,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
    bool? isOnTop,
  }) : super.cloneOtherWith(
          other: other,
          minWidth: minWidth,
          minHeight: minHeight,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ) {
    isOnTop ??= other.isOnTop;
  }

  /// [cloneWith] method implementation.
  /// Returns instance created by the [BoxContainerConstraints.cloneOtherWith] constructor
  @override
  BoxContainerConstraints cloneWith({
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
  }) {
    return BoxContainerConstraints.cloneOtherWith(
      other: this,
      minWidth: minWidth,
      minHeight: minHeight,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }
}

class BoundingBoxes extends BoundingBoxesBase {
  /// The SINGLE UNNAMED generative constructor.
  /// must call super, super initializes fields in BoundingBoxesBase
  BoundingBoxes({required minSize, required maxSize})
      : super(minSize: minSize, maxSize: maxSize);

  // ### Prototype design pattern for cloning - cloneOther constructor used in clone extensions

  /// Generative named constructor, from the passed [BoundingBoxes] object [other].
  /// Call super to initialize common fields, then initialize the added field
  BoundingBoxes.cloneOther(BoundingBoxes other) : super.cloneOther(other: other) {
    // no new fields compared to BoundingBoxesBase
  }

  /// [clone] method implementation.
  /// Returns instance created by the [BoundingBoxes.cloneOther] constructor
  @override
  BoundingBoxes clone() {
    return BoundingBoxes.cloneOther(this);
  }


  /// Generative named constructor, from the passed other [BoundingBoxes] object.
  /// Call super to initialize common fields, then initialize the added field
  BoundingBoxes.cloneOtherWith({
    required BoundingBoxes other,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
  }) : super.cloneOtherWith(
          other: other,
          minWidth: minWidth,
          minHeight: minHeight,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );

  /// [cloneWith] method implementation.
  /// Returns instance created by the [BoundingBoxes.cloneOtherWith] constructor
  @override
  BoundingBoxes cloneWith({
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
  }) {
    return BoundingBoxes.cloneOtherWith(
      other: this,
      minWidth: minWidth,
      minHeight: minHeight,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }
}
