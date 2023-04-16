import 'util_dart.dart';

/// Extensions on the [String] class.
///
extension StringExtension on String {
  /// Convert this string to enum.
  ///
  /// In more detail:
  /// - If this string is a valid enum name in the passed enumValues, returns the enum value
  ///   represented by this string.
  /// - If this string does not represent an enum in the passed enumValues,
  ///   a StateError is thrown, indicating the values that failed.
  T asEnum<T extends Enum>(List<T> enumValues) {
    try {
      return enumValues.singleWhere((v) => this == enumName(v));
    } on Error {
      // on Error catch (e) {
      throw StateError('String $this is not in enum list $enumValues.');
    }
  }
}

extension IterableExtension<E> on Iterable<E> {
  E reduceOrElse(E Function(E value, E element) combine, {E Function()? orElse}) {
    if (isNotEmpty) {
      return reduce(combine);
    }
    if (orElse != null) {
      return orElse();
    }
    throw StateError('Iterable $this has no elements. this=${toList()}');
  }
}

extension ListExtension<E,T> on List<List<E>> {

  List<E> expandIt() => expand((item) => item).toList();

  List<List> multiplyElementsBy(List<T> multiplyBy) {
    return map((item) => List.generate(multiplyBy.length, (int index) => [item, multiplyBy[index]])).expand((item) => item).toList();
  }
}