import 'dart:ui' as ui show Size, Offset;
import 'dart:math' as math show Rectangle;

import '../../morphic/container/constraints.dart' show ContainerConstraints;

// todo-05: Container core rules: 
//           1) I do not expose position, offset, or layoutSize.
//               I stay put until someone calls transform on me, OR it's special case applyParentOffset.
//               Is that possible?
//           2) The layout() method finds, iteratively, the sizes of all Container children of the top Container. 
//              The paint() method must NOT paint beyond the size of any Container


// todo-05 : Shape and extensions (Box, Pie), Container and extensions, Layout, Painter -------------------------------

/// Shape is the set of points in a Container.
/// 
/// Returned from [layout].
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

/// Represents not-positioned pie shape. Internal coordinates are polar, but can ask for containing rectangle.
/// Equivalent to Size in Box shapes (internally in cartesian coordinates)
class Pie {
  // todo-05 add distance and angle, and implement
  double angle = 0.0; // radians
  double radius = 0.0; // pixels ?
}

/// Represents a positioned pie shape. Positioning is in Cartesian coordinates represented by Offset.
/// Equivalent to Rectangle in Box shapes.
class PositionedPie extends Pie {
  ui.Offset offset = const ui.Offset(0.0, 0.0);
}

// todo-05 implement
class PieShape extends Shape {
  @override
  Pie get surface => Pie();
  @override
  PositionedPie get positionedSurface => PositionedPie();
}

// todo-05 : Constraints and extensions -------------------------------------------------------------------------------

class PieContainerConstraints extends ContainerConstraints {
}

// todo-05 : BoxContainerConstraints - see constraints.dart ------------------------------------------------------------

// todo-05 : split:
//           - Container to BoxContainer and PieContainer
//           - Shape to BoxShape (wraps Size) and PieShape
//           - ContainerConstraint to BoxContainerConstraint and PieContainerConstraint 
// todo-05 : Change Container.layout to 
//               Shape layout({required covariant ContainerConstraints constraints}); // Must set Shape (Size for now) on layoutableBoxParentSandbox 
//           This base layout maybe eventually configures some constraints caching and debugging.
//           Extensions of Container: BoxContainer, PieContainer override layout as
//               BoxShape layout({required covariant BoxContainerConstraints constraints}); // Must set BoxShape (essentially, this is Size)  on layoutableBoxParentSandbox 
//               PieShape layout({required covariant PieContainerConstraints constraints}); // Must set PieShape on layoutableBoxParentSandbox


