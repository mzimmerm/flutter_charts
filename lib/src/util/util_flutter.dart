/// Utility that contain only Dart code BUT DOES import 'dart:ui' or anything Flutter.
/// See util_dart.dart for reason.
import 'dart:math' as math;
import 'dart:ui' show Rect, Size, Offset;

import 'package:flutter_charts/src/morphic/ui2d/point.dart';
import 'package:flutter_charts/src/util/extensions_dart.dart';
import 'util_dart.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart' show ChartOrientation;


/// Returns the smallest rectangle which contains all passed [rectangles].
///
/// If the [rectangles] list is empty, an origin-based, zero-sized rectangle is returned.
Rect boundingRect(List<Rect> rectangles, /*{double Function()? orElse}*/) {
  return Rect.fromLTRB(
    rectangles.map((Rect rectangle) => rectangle.left).reduceOrElse(math.min, orElse: () => 0.0), // left
    rectangles.map((Rect rectangle) => rectangle.top).reduceOrElse(math.min, orElse: () => 0.0), // top,
    rectangles.map((Rect rectangle) => rectangle.right).reduceOrElse(math.max, orElse: () => 0.0), // right
    rectangles.map((Rect rectangle) => rectangle.bottom).reduceOrElse(math.max, orElse: () => 0.0), // bottom
  );
}

void assertSizeResultsSame(Size result, Size otherResult) {
  if (!(isCloserThanEpsilon(result.width, otherResult.width) &&
      isCloserThanEpsilon(result.height, otherResult.height))) {
    String msg = ' ### Log.Warning: Size results do not match. Result was $result, Other result was $otherResult.';
    print(msg);
    throw StateError(msg);
  }
}

void assertOffsetResultsSame(Offset result, Offset otherResult) {
  if (!(isCloserThanEpsilon(result.dx, otherResult.dx) &&
      isCloserThanEpsilon(result.dy, otherResult.dy))) {
    String msg = ' ### Log.Warning: Offset results do not match. Result was $result, Other result was $otherResult.';
    print(msg);
    throw StateError(msg);
  }
}

/// Holder class defining the ranges and orientation in one place for the benefit
/// of [PointOffset.affmapBetweenRanges].
///
/// todo-02-design : Should it contain ChartStacking information?
class FromTransposing2DValueRange {

  FromTransposing2DValueRange ({
    required this.inputDataRange,
    required this.outputDataRange,
    required this.chartOrientation,
  });

  final Interval inputDataRange;
  final Interval outputDataRange;
  final ChartOrientation chartOrientation;

  FromTransposing2DValueRange subsetForSignOfPointOffsetBeforeAffmap({required PointOffset pointOffset,}) {
    return FromTransposing2DValueRange(
      inputDataRange: inputDataRange.portionForSignOfValue(pointOffset.inputValue),
      outputDataRange: outputDataRange.portionForSignOfValue(pointOffset.outputValue),
      chartOrientation: chartOrientation,
    );
  }
}

/// Pixel 2D range encapsulates the 'to range' of values that ore affmap-ed
/// from a [FromTransposing2DValueRange] instance.
///
/// Always starts both dimensions from 0.
///
/// Although this mentions 'pixels', it should be part of model,
/// as the name is merely a convenience to define a 'to range' of
/// values that ore affmap-ed from [FromTransposing2DValueRange].
class To2DPixelRange {

  To2DPixelRange({
    // sizerWidth or constraints width
    required double width,
    // sizerHeight or constraints height
    required double height,
  }) : horizontalPixelRange = Interval(0, width), verticalPixelRange = Interval(0, height);

  final Interval horizontalPixelRange;
  final Interval verticalPixelRange;

  Size get size => Size(horizontalPixelRange.max, verticalPixelRange.max);
}
