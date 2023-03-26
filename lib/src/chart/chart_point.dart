
import 'dart:ui' show Offset;

class ChartPoint extends Offset {
  ChartPoint({
    required double inputValue,
    required double outputValue,
}) : super(inputValue, outputValue);

  double get inputValue => dx;
  double get outputValue => dy;
}