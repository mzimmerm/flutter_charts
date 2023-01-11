import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_charts/src/chart/container_layouter_base.dart';

/// [ContainerKey] is a unique identifier of a [BoxContainer].
///
/// The meaning of 'unique' depends on the 'context'.
///
/// In the current implementation, the only supported 'uniqueness context' is 'siblings of [BoxContainerHierarchy]'.
/// In other words, extensions of [ContainerKey] currently support the ability to identify [BoxContainer]
/// uniquely among it's children in the [BoxContainerHierarchy].
///
/// In the future the 'uniqueness context' may be 'application', or other well-defined subsets of it.
@immutable
abstract class ContainerKey {

  /// Default generative constructor constructs Key without value,
  /// allows extensions to define `const` constructor.
  ///
  /// This trick ensures the default constructor [Key] is not generated,
  /// replaced with this const constructor. Simply trying to use
  ///   `Key();`
  /// or
  ///   `const Key();`
  /// causes a compile error 'the unnamed constructor is already defined'
  ///
  const ContainerKey._simple();

  /// Default way to create instance of [ContainerKey] extension.
  ///
  /// Note this creates a siblings unique key.
  /// Must override if uniqueness in other context key is needed.
  const factory ContainerKey(String value) = SiblingsValueKey<String>;
}

/// [SiblingsKey] is a [ContainerKey] intended to be unique among siblings
/// of the same parent in the [BoxContainerHierarchy].
///
@immutable
abstract class SiblingsKey extends ContainerKey {
  /// Default constructor.
  ///
  /// Must be [const] to enable extensions' [const] constructors.
  const SiblingsKey() : super._simple();

}

/// A [SiblingsKey] extension uses a parametrized [value] as identifier.
///
/// It is assumed to be created and set on [BoxContainer] during construction, unique
/// among siblings. That means, the creator of the [BoxContainer]s must be aware
/// of any future siblings, or generate the key sufficiently randomly.
@immutable
class SiblingsValueKey<T> extends SiblingsKey {
  final T value;

  const SiblingsValueKey(this.value) : super();

  @override
  String toString() {
    return '$runtimeType: value=$value';
  }

  @override
  bool operator ==(Object other) =>
      other is SiblingsValueKey<T> && other.runtimeType == runtimeType && other.value == value;

  @override
  int get hashCode => value.hashCode * 17;
}

// todo-01-document
abstract class Keyed {
  ContainerKey get key;
}

/// Manager of [Keyed] objects in member list [keyedMembers] which [ContainerKey]s must be kept unique
/// within the [keyedMembers].
///
/// Works as a mixin on behalf of it's extension, by delegating the [keyedMembers] getter (a list of [Keyed] objects)
/// to it's extension's member.
///
/// The method [ensureUnique] must be called by the extension after the list underlying
/// the [keyedMembers] getter is changed.
///
/// For example, a [BoxContainer] we want siblings should be unique,
/// so we ensure [BoxContainer] implements the [UniqueKeyedObjectsManager],
/// and we forward the [BoxContainer]'s [children] to the [UniqueKeyedObjectsManager]'s [keyedMembers];
/// we also ensure that in [BoxContainer]'s constructor, after [BoxContainer]'s [children] change, we call [ensureUnique].
abstract class UniqueKeyedObjectsManager {

  /// Holder of the [Keyed] members, which keys must stay unique.
  ///
  /// Serves as a backing [Iterable] of the [Keyed] objects
  /// this holder manages.
  ///
  /// Implementors need to override this
  /// method to start holding uniquely [Keyed] objects.
  List<Keyed> get keyedMembers;

  /* todo-01-remove ??
  /// Returns, among this holder's managed [Keyed] members, the member with the passed [containerKey].
  ///
  /// Throws exception if the passed [containerKey] is not found, or multiple are found.
  Keyed memberForKey(ContainerKey containerKey) {
    Iterable<Keyed> matchingMembers = keyedMembers.where((Keyed keyed) => keyed.key == containerKey);
    if (matchingMembers.length > 1) {
      throw StateError('Internal error: Multiple matching members $matchingMembers for key $containerKey');
    }
    if (matchingMembers.isEmpty) {
      throw StateError('No matching member for key $containerKey in _keyedMembers $keyedMembers');
    }
    return matchingMembers.first;
  }
 */

  Iterable<ContainerKey> get _memberKeys => keyedMembers.map((Keyed keyed) => keyed.key);

  /// Checks uniqueness of all managed [Keyed] members.
  ///
  /// Implementors must call [ensureUnique] every time after the list backing
  /// the [keyedMembers] is modified.
  void ensureUnique() {
    // toSet converts to set using ==. If lengths do not match, there are at least two == keys in [keys].
    Set toSet = _memberKeys.toSet();
    if (toSet.length != _memberKeys.length) {
      throw StateError('ensureUnique:  keys $_memberKeys of members $keyedMembers are not unique');
    }
  }
}