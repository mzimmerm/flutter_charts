import 'dart:ui' as ui show Color;

List<ui.Color> makeNonNullableWithNonNullAssert(List<ui.Color>? passed) {
  assert (passed != null);
  List<ui.Color> dataRowsColors = passed ?? [];
  return dataRowsColors;
}
