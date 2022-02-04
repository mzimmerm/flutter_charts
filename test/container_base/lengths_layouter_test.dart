import 'package:flutter_charts/src/chart/new/container_base_new.dart' show Packing, Align, LengthsLayouter, LayedOutLineSegments;
import 'package:flutter_charts/src/util/util_dart.dart' show Interval, LineSegment;

import 'package:test/test.dart';

main() {
  List<double> lengths = [5.0, 10.0, 15.0];
  var matrjoskaMinNoAddedLength = LengthsLayouter(lengths: lengths, packing: Packing.matrjoska, align: Align.min);

  test('LengthsLayouter.layout() test for Matrjoska Min, no added length', () {
    LayedOutLineSegments segments = matrjoskaMinNoAddedLength.layout();
    
    expect(segments.lineSegments.length, 3);
    expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
    expect(segments.lineSegments[1], LineSegment(0.0, 10.0));
    expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
    
  });
}