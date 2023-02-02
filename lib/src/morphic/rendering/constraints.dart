import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_charts/src/chart/container_edge_padding.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/util/extensions_flutter.dart';
import 'package:tuple/tuple.dart';

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

  // The SINGLE UNNAMED generative non-forwarding constructor
  BoundingBoxesBase({
    required this.minSize,
    required this.maxSize,
  }) {
    assertSizes(
      minWidth: minSize.width,
      minHeight: minSize.height,
      maxWidth: maxSize.width,
      maxHeight: maxSize.height,
    );
  }

  // Named constructors, forwarded to the generative constructor
  BoundingBoxesBase.exactBox({required Size size}) : this(minSize: size, maxSize: size);
  BoundingBoxesBase.insideBox({required Size size}) : this(minSize: Size.zero, maxSize: size);
  BoundingBoxesBase.outsideBox({required Size size}) : this(minSize: size, maxSize: Size.infinite);
  // todo-01-last : Add a singleton member unusedConstraints, initialized with this and set as const. Then this constructor can be private ?
  /// Named constructor for unused expansion
  BoundingBoxesBase.unused() : this.exactBox(size: const Size(0.0, 0.0));
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
  /// Used along with the generative non-forwarding named constructor [BoundingBoxesBase.cloneOther].
  /// In the extensions [clone] returns newly constructed BoundingBoxesBase extensions
  /// using the concrete [cloneOther] named constructor
  /// and passing `this` to it.
  BoundingBoxesBase clone();

  // The cloneOtherWith family is implemented similar to [BoundingBoxesBase.cloneOther] + [clone]
  // BUT the [cloneWith] cannot be abstract, as extensions need more parameters.

  /// Generative non-forwarding named constructor from other [BoundingBoxesBase] and values to change
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

    assertSizes(
      minWidth: minWidth,
      minHeight: minHeight,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );

    minSize = Size(minWidth, minHeight);
    maxSize = Size(maxWidth, maxHeight);
  }

  void assertSizes({
    required double minWidth,
    required double minHeight,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (minWidth < 0.0 || minHeight < 0.0 || maxWidth < 0.0 || maxHeight < 0.0) {
      throw StateError(
          'Negative sizes: minWidth $minWidth, minHeight $minHeight, maxWidth $maxWidth, maxHeight $maxHeight');
    }
    if (minWidth > maxWidth) {
      throw StateError('minWidth > maxWidth : minWidth=$minWidth, maxWidth=$maxWidth');
    }
    if (minWidth > maxWidth) {
      throw StateError('minWidth > maxWidth : minWidth=$minWidth, maxWidth=$maxWidth');
    }
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

  double get width => size.width;

  double get height => size.height;

  bool get isExact => minSize == maxSize;

  bool get isInside => minSize.width <= maxSize.width && minSize.height <= maxSize.height;

  bool containsFully(Size size) {
    return size.width <= maxSize.width &&
        size.height <= maxSize.height &&
        size.width >= minSize.width &&
        size.height >= minSize.height;
  }

  double maxLengthAlongAxis(LayoutAxis layoutAxis) {
    switch (layoutAxis) {
      case LayoutAxis.horizontal:
        return maxSize.width;
      case LayoutAxis.vertical:
        return maxSize.height;
    }
  }

  /// Divide this [BoundingBoxesBase] into a list of 'smaller' [BoundingBoxesBase]s objects,
  /// depending on the dividing strategy [DivideConstraints].
  ///
  /// The sizes of the returned constraint list are smaller along the direction of the passed [layoutAxis];
  /// cross-sizes remain the same as this constraint.
  ///
  /// Extensions use this method to pass smaller constraints to children; use for layout sizes
  /// is unclear atm.
  // List<T> divideUsingStrategy<T extends BoundingBoxesBase>({
  List<BoundingBoxesBase> divideUsingStrategy({
    required int divideIntoCount,
    required DivideConstraints divideStrategy,
    required LayoutAxis layoutAxis,
    List<int>? intWeights,
  }) {
    double minWidth, minHeight, maxWidth, maxHeight;
    late final int sumIntWeights;

    if (divideStrategy == DivideConstraints.intWeights && intWeights == null) {
      throw StateError('intWeights only applicable for DivideConstraints.ratio');
    }

    if ((divideStrategy == DivideConstraints.evenly ||
            divideStrategy == DivideConstraints.evenly) &&
        intWeights != null) {
      throw StateError('intWeights not applicable for DivideConstraints.evenly or noDivide');
    }

    if (intWeights != null) {
      assert(intWeights.length == divideIntoCount);
      sumIntWeights = intWeights.fold<int>(0, (previousValue, element) => previousValue + element);
    }

    switch (divideStrategy) {
      case DivideConstraints.evenly:
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
      case DivideConstraints.intWeights:
        List<BoundingBoxesBase> fractions = [];
        for (int intWeight in intWeights!) {
          switch (layoutAxis) {
            case LayoutAxis.horizontal:
              minWidth = minSize.width * (1.0 * intWeight) / sumIntWeights;
              minHeight = minSize.height;
              maxWidth = maxSize.width * (1.0 * intWeight) / sumIntWeights;
              maxHeight = maxSize.height;
              break;
            case LayoutAxis.vertical:
              minWidth = minSize.width;
              minHeight = minSize.height * (1.0 * intWeight) / sumIntWeights;
              maxWidth = maxSize.width;
              maxHeight = maxSize.height * (1.0 * intWeight) / sumIntWeights;
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
      case DivideConstraints.noDivide:
        return [clone()];
    }
  }

  /// Helper returns Tuple2 of sizes, deflated (smaller) from self [minSize] and [maxSize] with the passed [size].
  ///
  /// The deflation is defined by subtraction (not division).
  Tuple2<Size, Size> _deflateWithSize(Size size) {
    // Smaller constraint, on both min and max portions, with the passed size
    Size min = minSize.deflateWithSize(size);
    Size max = maxSize.deflateWithSize(size);

    return Tuple2(min, max);
  }

  /// Helper returns Tuple2 of sizes, inflated (bigger) from self [minSize] and [maxSize] with the passed [size].
  ///
  /// The deflation is defined by addition (not multiplication).
  Tuple2<Size, Size> _inflateWithSize(Size size) {
    // Smaller constraint, on both min and max portions, with the passed size
    Size min = minSize.inflateWithSize(size);
    Size max = maxSize.inflateWithSize(size);

    return Tuple2(min, max);
  }

  Tuple2<Size, Size> _multiplySidesBy(Size size) {
    Size min = minSize.multiplySidesBy(size);
    Size max = maxSize.multiplySidesBy(size);

    return Tuple2(min, max);
  }

  /// Returns [BoundingBoxesBase], with sizes deflated (smaller) from self [minSize] and [maxSize] with the passed [size].
  ///
  /// The deflation is defined by subtraction (not division).
  BoundingBoxesBase deflateWithSize(Size size) {
    Tuple2<Size, Size> smaller = _deflateWithSize(size);

    return cloneWith(
      minWidth: smaller.item1.width,
      minHeight: smaller.item1.height,
      maxWidth: smaller.item2.width,
      maxHeight: smaller.item2.height,
    );
  }

  /// Returns [BoundingBoxesBase], with sizes inflated (larger) from self [minSize] and [maxSize] with the passed [size].
  ///
  /// The inflation is defined by addition (not multiplication).
  BoundingBoxesBase inflateWithSize(Size size) {
    Tuple2<Size, Size> bigger = _inflateWithSize(size);

    return cloneWith(
      minWidth: bigger.item1.width,
      minHeight: bigger.item1.height,
      maxWidth: bigger.item2.width,
      maxHeight: bigger.item2.height,
    );
  }

  BoundingBoxesBase multiplySidesBy(Size size) {
    Tuple2<Size, Size> bigger = _multiplySidesBy(size);

    return cloneWith(
      minWidth: bigger.item1.width,
      minHeight: bigger.item1.height,
      maxWidth: bigger.item2.width,
      maxHeight: bigger.item2.height,
    );
  }

  BoundingBoxesBase deflateWithPadding(EdgePadding padding) {
    return deflateWithSize(
      Size(
        padding.start + padding.end,
        padding.top + padding.bottom,
      ),
    );
  }

  BoundingBoxesBase inflateWithPadding(EdgePadding padding) {
    return inflateWithSize(
      Size(
        padding.start + padding.end,
        padding.top + padding.bottom,
      ),
    );
  }

  Tuple2<Rect, Rect> _offsetBy(Offset offset) {
    return Tuple2(offset & minSize, offset & maxSize);
  }

  /// Utility method allows to check if this [BoundingBoxesBase], moved by (offset by) [offset]
  /// does contain [other] rectangle.
  ///
  /// Very useful for layout algorithms to check for overflow etc.
  bool whenOffsetContainsFullyOtherRect(Offset offset, Rect other) {
    Tuple2<Rect, Rect> offsetBox = _offsetBy(offset);
    Rect insideRect = offsetBox.item1;
    Rect outsideRect = offsetBox.item2;

    // If other is outside of insideRect and other is inside outsideRect,
    // then other is inside this bounding box
    // Need: Rect.isOutsideOf(other)
    return other.isOutsideOf(insideRect) && other.isInsideOf(outsideRect);
  }

  @override
  String toString() {
    return '${runtimeType.toString()}: minSize=$minSize, maxSize=$maxSize';
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

  @override
  BoundingBoxes deflateWithSize(Size size) {
    Tuple2<Size, Size> smaller = _deflateWithSize(size);

    return cloneWith(
      minWidth: smaller.item1.width,
      minHeight: smaller.item1.height,
      maxWidth: smaller.item2.width,
      maxHeight: smaller.item2.height,
    );
  }

  @override
  BoundingBoxes inflateWithSize(Size size) {
    Tuple2<Size, Size> bigger = _inflateWithSize(size);

    return cloneWith(
      minWidth: bigger.item1.width,
      minHeight: bigger.item1.height,
      maxWidth: bigger.item2.width,
      maxHeight: bigger.item2.height,
    );
  }

  @override
  BoundingBoxes multiplySidesBy(Size size) {
    Tuple2<Size, Size> bigger = _multiplySidesBy(size);

    return cloneWith(
      minWidth: bigger.item1.width,
      minHeight: bigger.item1.height,
      maxWidth: bigger.item2.width,
      maxHeight: bigger.item2.height,
    );
  }

  @override
  BoundingBoxes deflateWithPadding(EdgePadding padding) {
    return deflateWithSize(
      Size(
        padding.start + padding.end,
        padding.top + padding.bottom,
      ),
    );
  }

  @override
  BoundingBoxes inflateWithPadding(EdgePadding padding) {
    return inflateWithSize(
      Size(
        padding.start + padding.end,
        padding.top + padding.bottom,
      ),
    );
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
///   todo-01-document this is not correct at all
class BoxContainerConstraints extends BoundingBoxesBase {

  /// Expresses if it was created for the very top [Row] or [ColumnLayoter].
  ///
  /// It is used to control ability of [Row] or [Column] to set [Align] (alignment) other
  /// then [Align.start]
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
  // todo-01-last : Add a singleton member unused(), initialized with this and set as const. Then this constructor can be private ?
  /// Named constructor for unused expansion
  BoxContainerConstraints.unused() : this.exactBox(size: const Size(0.0, 0.0));
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

  @override
  BoxContainerConstraints deflateWithSize(Size size) {
    Tuple2<Size, Size> smaller = _deflateWithSize(size);

    return cloneWith(
      minWidth: smaller.item1.width,
      minHeight: smaller.item1.height,
      maxWidth: smaller.item2.width,
      maxHeight: smaller.item2.height,
    );
  }

  @override
  BoxContainerConstraints inflateWithSize(Size size) {
    Tuple2<Size, Size> bigger = _inflateWithSize(size);

    return cloneWith(
      minWidth: bigger.item1.width,
      minHeight: bigger.item1.height,
      maxWidth: bigger.item2.width,
      maxHeight: bigger.item2.height,
    );
  }

  @override
  BoxContainerConstraints multiplySidesBy(Size size) {
    Tuple2<Size, Size> bigger = _multiplySidesBy(size);

    return cloneWith(
      minWidth: bigger.item1.width,
      minHeight: bigger.item1.height,
      maxWidth: bigger.item2.width,
      maxHeight: bigger.item2.height,
    );
  }

  @override
  BoxContainerConstraints deflateWithPadding(EdgePadding padding) {
    return deflateWithSize(
      Size(
        padding.start + padding.end,
        padding.top + padding.bottom,
      ),
    );
  }

  @override
  BoxContainerConstraints inflateWithPadding(EdgePadding padding) {
    return inflateWithSize(
      Size(
        padding.start + padding.end,
        padding.top + padding.bottom,
      ),
    );
  }
}

