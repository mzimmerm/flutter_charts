import 'dart:ui' show Size;

import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/chart/new/container_base_new.dart';


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
///   todo-00-document 
class BoxContainerConstraints extends ContainerConstraints {
  Size minSize;
  Size maxSize;

  BoxContainerConstraints({required this.minSize, required this.maxSize,});
  BoxContainerConstraints.exactBox({required Size size}) : this(minSize: size, maxSize: size,);
  BoxContainerConstraints.insideBox({required Size size}) : this(minSize: Size.zero, maxSize: size,);
  BoxContainerConstraints.outsideBox({required Size size}) : this(minSize: size, maxSize: Size.infinite,);
  Size get size {
    assert(isExact);
    return minSize;
  }
  
  bool get isExact => minSize == maxSize;

  bool containsFully(Size size) { 
    return size.width <= maxSize.width && size.height <= maxSize.height
        && size.width >= minSize.width && size.height >= minSize.height;
  }

  Size sizeLeftAfter(Size takenSize, LayoutAxis mainLayoutAxis) {
    if (!containsFully(takenSize)) {
      throw StateError('This constraints $toString() does not fully contain takenSize=$takenSize');
    }
    Size size;
    switch (mainLayoutAxis) {
      // Treat none as horizontal, although that is a question
      case LayoutAxis.none:
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
  
  /// Named constructor for unused expansion
  BoxContainerConstraints.unused()
      : this.exactBox(size: const Size(
          -1.0,
          -1.0,
        ));

  BoxContainerConstraints cloneWith({
    double? width,
    double? height,
  }) {
    assert(isExact);
    height ??= minSize.height;
    width ??= minSize.width;
    return BoxContainerConstraints.exactBox(size: Size(width, height));
  }

  @override
  String toString() {
    return '${runtimeType.toString()}: minSize=$minSize, maxSize=$maxSize';
  } 
}
