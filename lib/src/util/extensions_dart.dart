import 'dart:math' as math show min, max;

import '../morphic/container/morphic_dart_enums.dart' show Sign;
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

  double extremeValueWithSign(Sign sign) {
    switch(sign) {
      case Sign.positiveOr0:
        return fold<double>(0.0, (prev, element) => math.max(prev, element as double));
      case Sign.negative:
        return fold<double>(0.0, (prev, element) => math.min(prev, element as double));
      case Sign.any:
        throw StateError('method extremeWithSign cannot be applied on Sign.any');
    }
  }
}

extension ListExtension<E,T> on List<List<E>> {
  List<E> expandIt() => expand((item) => item).toList();

  /// Replace each element of this list with multiple elements, each element in the multiple
  /// is a list of two items: first item is the element of this list, the second item is element of the
  /// passed [multiplyBy] list in order.
  ///
  /// Example:
  ///   ['1', '2', '3'].multiplyElementsBy( ['a', 'b'] ) -> [[1, a], [1, b], [2, a], [2, b], [3, a], [3, b]]
  List<List> multiplyElementsBy(List<T> multiplyBy) {
    return map((item) => List.generate(multiplyBy.length, (int index) => [item, multiplyBy[index]])).expand((item) => item).toList();
  }
}

List expandList(List<List> listList) => listList.expand((item) => item).toList();

// List<List> is List<[E, T]>
List<List> multiplyListElementsBy<E,T>(List<E> list, List<T> multiplyBy) =>
    list.map((item) => List.generate(multiplyBy.length, (int index) => [item, multiplyBy[index]])).expand((item) => item).toList();