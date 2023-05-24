import 'dart:ui' show Offset, Rect, Size;
import 'package:tuple/tuple.dart';

import 'container_edge_padding.dart';
import 'morphic_dart_enums.dart';
import '../../util/extensions_flutter.dart';
import 'layouter_one_dimensional.dart';
import 'container_layouter_base.dart' show BoxContainer;

class ContainerConstraints {}

/// Represents sizes of two boxes without specifying positions.
///
/// Objects of this class's extensions allow two core roles:
///   - Role of a constraint that a parent in a layout hierarchy requires existence of children.
///     This role is used in the current one-pass layout, implemented by [BoxContainerConstraints].
///   - Role of a layout size 'wiggle room' a child offers to it's parent when laying out using a two pass layout.
///     This could be used it a future two pass layout.
abstract class BoundingBoxesBase {
  // ### The SINGLE UNNAMED generative not-forwarding constructor
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

  // ### Named constructors, forwarded to the generative constructor
  BoundingBoxesBase.exactBox({required Size size}) : this(minSize: size, maxSize: size);
  BoundingBoxesBase.insideBox({required Size size}) : this(minSize: Size.zero, maxSize: size);
  BoundingBoxesBase.outsideBox({required Size size}) : this(minSize: size, maxSize: Size.infinite);
  /// Named constructor for unused expansion
  BoundingBoxesBase.unused() : this.exactBox(size: const Size(0.0, 0.0));
  BoundingBoxesBase.infinity() : this.insideBox(size: const Size(double.infinity, double.infinity));

  // ### Members
  late final Size minSize;
  late final Size maxSize;
  /// Set to not-null value of [LayoutAxis] if this bounding box was divided from a 'parent'.
  ///
  /// Motivation and assumption:
  ///   - Used to mark that this bounding box was divided from parent, see [divideUsingMethod].
  ///   - Mostly for the benefit of divided [BoxContainerConstraints].
  ///   - If set, it is assumed that all the divided constraints are managed
  ///     in a list (e.g. list of constraint children), and the division was a kind to tiling
  ///     (so that children sizes along this [divideAlongAxis] added up, do not exceed the parent size.
  LayoutAxis? divideAlongAxis;

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
  /// Used along with the generative not-forwarding named constructor [BoundingBoxesBase.cloneOther].
  /// In the extensions [clone] returns newly constructed BoundingBoxesBase extensions
  /// using the concrete [cloneOther] named constructor
  /// and passing `this` to it.
  BoundingBoxesBase clone();

  // The cloneOtherWith family is implemented similar to [BoundingBoxesBase.cloneOther] + [clone]
  // BUT the [cloneWith] cannot be abstract, as extensions need more parameters.

  /// Generative not-forwarding named constructor from other [BoundingBoxesBase] and values to change
  /// on the clone.
  BoundingBoxesBase.cloneOtherWith({
    required BoundingBoxesBase other,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
    this.divideAlongAxis,
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
    if (minHeight > maxHeight) {
      throw StateError('minHeight > minHeight : minHeight=$minHeight, minHeight=$minHeight');
    }
  }

  /// [cloneWith] method implementation.
  /// Returns instance created by the [BoxContainerConstraints.cloneOtherWith] constructor
  BoundingBoxesBase cloneWith({
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
    LayoutAxis? divideAlongAxis,
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

  /// Returns [true] if the set all points of a left-top origin-positioned rectangle representing the passed [size]
  /// is a subset of the set of points in the area between the embedded rectangles of this [BoundingBoxesBase] - that is,
  /// [size] is between [minSize] and [maxSize], inclusive the borders of all sizes.
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

  /// Creates a list of 'smaller' [BoundingBoxesBase]s objects, based on this [BoundingBoxesBase].
  ///
  /// The created [BoundingBoxesBase]s and their sizes depend on the dividing strategy [constraintsDivideMethod].
  ///
  /// The sizes of the returned constraint list are smaller along the orientation of the passed [divideAlongAxis];
  /// the cross-sizes remain the same as the size of this instance in that orientation.
  ///
  /// Extensions use this method to pass smaller constraints to children; use for layout sizes
  /// is unclear atm.
  ///
  /// The parameters description:
  ///   -
  ///   - [divideIntoCount] Count to divide evenly to
  ///   - [constraintsDivideMethod] value of [ConstraintsDivideMethod]
  ///   - [divideAlongAxis] Defines the axis along which this constraint is divided.
  ///      In the cross-axis to [divideAlongAxis], the sizes are taken from this constraint.
  ///   - [childrenWeights] Defines the weights by which this instance is divided. The
  ///     name refers to the usual use of this method, where this instance is a constraint on a parent [BoxContainer],
  ///     and client asks to divide the constraint into smaller constraints given the parent's children weight.
  ///     Each weight acts along the axis orientation given by [divideAlongAxis].
  ///
  // todo-04 : separate into methods:
  //    - divideEvenlyIntoCount: params : divideIntoCount, divideAlongAxis
  //    - divideByChildrenWeights: params : childrenWeights, divideAlongAxis
  //    - copyIntoCount: params: copyCount, divideAlongAxis
  //    and call them in code based on given method
  // List<T> divideUsingStrategy<T extends BoundingBoxesBase>({
  List<BoundingBoxesBase> divideUsingMethod({
    required int divideIntoCount,
    required ConstraintsDivideMethod constraintsDivideMethod,
    required LayoutAxis divideAlongAxis,
    List<double>? childrenWeights,
  }) {
    double minWidth, minHeight, maxWidth, maxHeight;
    late final double sumChildrenWeights;

    if (constraintsDivideMethod == ConstraintsDivideMethod.byChildrenWeights && childrenWeights == null) {
      throw StateError('For constraintsDivideMethod "byChildrenWeights",'
          ' childrenWeights must be set, but it is null');
    }

    if (constraintsDivideMethod.isNot(ConstraintsDivideMethod.byChildrenWeights) && childrenWeights != null) {
      throw StateError('weights not applicable for ConstraintsDivideMethod.evenly or noDivide');
    }

    if (childrenWeights != null) {
      assert(childrenWeights.length == divideIntoCount);
      sumChildrenWeights = childrenWeights.fold<double>(0, (previousValue, element) => previousValue + element);
    }

    switch (constraintsDivideMethod) {
      case ConstraintsDivideMethod.evenDivision:
        switch (divideAlongAxis) {
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
            divideAlongAxis: divideAlongAxis,
          );
          fractions.add(fraction);
        }
        return List.from(fractions, growable: false);
      case ConstraintsDivideMethod.byChildrenWeights:
        List<BoundingBoxesBase> fractions = [];
        for (var weight in childrenWeights!) {
          switch (divideAlongAxis) {
            case LayoutAxis.horizontal:
              minWidth = minSize.width * (1.0 * weight) / sumChildrenWeights;
              minHeight = minSize.height;
              maxWidth = maxSize.width * (1.0 * weight) / sumChildrenWeights;
              maxHeight = maxSize.height;
              break;
            case LayoutAxis.vertical:
              minWidth = minSize.width;
              minHeight = minSize.height * (1.0 * weight) / sumChildrenWeights;
              maxWidth = maxSize.width;
              maxHeight = maxSize.height * (1.0 * weight) / sumChildrenWeights;
              break;
          }
          var fraction = cloneWith(
            minWidth: minWidth,
            minHeight: minHeight,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            divideAlongAxis: divideAlongAxis,
          );
          fractions.add(fraction);
        }
        return List.from(fractions, growable: false);
      case ConstraintsDivideMethod.noDivision:
        return List.filled(divideIntoCount, clone(), growable: false);
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
    LayoutAxis? divideAlongAxis,
  }) : super.cloneOtherWith(
          other: other,
          minWidth: minWidth,
          minHeight: minHeight,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          divideAlongAxis: divideAlongAxis,
        );

  /// [cloneWith] method implementation.
  /// Returns instance created by the [BoundingBoxes.cloneOtherWith] constructor
  @override
  BoundingBoxes cloneWith({
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
    LayoutAxis? divideAlongAxis,
  }) {
    return BoundingBoxes.cloneOtherWith(
      other: this,
      minWidth: minWidth,
      minHeight: minHeight,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      divideAlongAxis: divideAlongAxis,
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

/// Defines how a container [layout] should expand the container in horizontal and vertical direction.
///
/// The expansion (length) in either direction is defined the same way [ui.Size] defines
/// it's expansion as "width" or "height".
///
/// The allowed expansion (lengths in horizontal and vertical direction) is defined by named constructors.
///
class BoxContainerConstraints extends BoundingBoxesBase {

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
  // todo-04 : Add a singleton member unusedConstraints, initialized with this and set as const. Then this constructor can be private ?
  /// Named constructor for unused expansion
  BoxContainerConstraints.unused() : this.exactBox(size: const Size(0.0, 0.0));
  BoxContainerConstraints.infinity() : this.insideBox(size: const Size(double.infinity, double.infinity));

  // ### Prototype design pattern for cloning - cloneOther constructor used in clone extensions

  /// Generative named constructor, from other constraint.
  ///
  /// The initializer list initializes the added field [isOnTop],
  ///   followed by a call to super which initializes the common fields,
  BoxContainerConstraints.cloneOther(BoxContainerConstraints other)
      : super.cloneOther(other: other);

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
    LayoutAxis? divideAlongAxis,
  }) : super.cloneOtherWith(
    other: other,
    minWidth: minWidth,
    minHeight: minHeight,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    divideAlongAxis: divideAlongAxis,
  );

  /// [cloneWith] method implementation.
  /// Returns instance created by the [BoxContainerConstraints.cloneOtherWith] constructor
  @override
  BoxContainerConstraints cloneWith({
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
    LayoutAxis? divideAlongAxis,
  }) {
    return BoxContainerConstraints.cloneOtherWith(
      other: this,
      minWidth: minWidth,
      minHeight: minHeight,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      divideAlongAxis: divideAlongAxis,
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

  /// Present itself as code
  String asCodeConstructorInsideBox() {
    return 'BoxContainerConstraints.insideBox(size: const Size($width, $height))';
  }

}

