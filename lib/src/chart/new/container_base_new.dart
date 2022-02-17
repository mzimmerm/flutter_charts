import 'dart:ui' as ui show Size, Offset;
// import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'dart:math' as math show Rectangle;

// import 'package:flutter_charts/src/util/util_dart.dart' as util_dart show LineSegment;
// import 'package:flutter_charts/src/morphic/rendering/constraints.dart' show BoxContainerConstraints;

import 'package:flutter_charts/src/chart/container_base.dart' show BoxContainer;

// todo-01: Container core rule: I do not expose position, offset, or layoutSize.
//               I stay put until someone calls transform on me, OR it's special case applyParentOffset.
//               Is that possible?


// todo-01 : Shape and extensions (Box, Pie), Container and extensions, Layout, Painter -------------------------------

/// Shape is the set of points in a Container.
/// 
/// Returned from [layout].
/// todo-01
class Shape {
  Object? get surface => null; // represents non positioned surface after getting size in layout
  Object? get positionedSurface => null;  // represents surface after positioning during layout
}

class BoxShape extends Shape {
  @override
  ui.Size get surface => ui.Size.zero;
  @override
  math.Rectangle get positionedSurface => const math.Rectangle(0.0, 0.0, 0.0, 0.0);
}

/// Represents non-positioned pie shape. Internal coordinates are polar, but can ask for containing rectangle.
/// Equivalent to Size in Box shapes (internally in cartesian coordinates)
class Pie {
  // todo-03 add distance and angle, and implement
  double angle = 0.0; // radians
  double radius = 0.0; // pixels ?
}

/// Represents a positioned pie shape. Positioning is in Cartesian coordinates represented by Offset.
/// Equivalent to Rectangle in Box shapes.
class PositionedPie extends Pie {
  ui.Offset offset = const ui.Offset(0.0, 0.0);
}

// todo-03 implement
class PieShape extends Shape {
  @override
  Pie get surface => Pie();
  @override
  PositionedPie get positionedSurface => PositionedPie();
}

// todo-01 : Constraints and extensions -------------------------------------------------------------------------------

class ContainerConstraints {
}
class PieContainerConstraints extends ContainerConstraints {
}

// todo-01 : BoxContainerConstraints - see constraints.dart ------------------------------------------------------------

// todo-01 : split:
//           - Container to BoxContainer and PieContainer
//           - Shape to BoxShape (wraps Size) and PieShape
//           - ContainerConstraint to BoxContainerConstraint and PieContainerConstraint 
// todo-01 : Change Container.newCoreLayout to 
//               Shape newCoreLayout({required covariant ContainerConstraints constraints}); // Must set Shape (Size for now) on parentSandbox 
//           This base newCoreLayout maybe eventually configures some constraints caching and debugging.
//           Extensions of Container: BoxContainer, PieContainer override layout as
//               BoxShape newCoreLayout({required covariant BoxContainerConstraints constraints}); // Must set BoxShape (essentially, this is Size)  on parentSandbox 
//               PieShape newCoreLayout({required covariant PieContainerConstraints constraints}); // Must set PieShape on parentSandbox


