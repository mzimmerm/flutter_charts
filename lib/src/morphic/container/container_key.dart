import 'package:flutter/foundation.dart' show immutable;

import 'container_layouter_base.dart';

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

  /// Single generative constructor constructs Key without value,
  /// allows extensions to define `const` constructor.
  ///
  /// This trick ensures the default no-arg constructor `ContainerKey()` is not generated,
  /// and so ContainerKey cannot be extended outside of this library `container_key.dart`.
  ///
  /// Note:
  /// Trying to use
  ///   `ContainerKey();`
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

/// Allows implementations to be identified by a user-defined unique key.
///
/// Uniqueness depends on context, and is not described by this class:
/// Uniqueness can be global, in hierarchy, among siblings etc.
abstract class Keyed {
  ContainerKey get key;
}

/// Manager of [Keyed] objects in member list [keyedMembers] which [ContainerKey]s must be kept unique
/// within the [keyedMembers].
///
/// Works as a mixin on behalf of it's extension, by delegating the [keyedMembers] getter (a list of [Keyed] objects)
/// to it's extension's member.
///
/// The method [ensureKeyedMembersHaveUniqueKeys] must be called by the extension
/// every time after the list underlying the [keyedMembers] getter is changed.
///
/// For example, a [BoxContainer] we want siblings should be unique,
/// so we ensure [BoxContainer] implements the [UniqueKeyedObjectsManager],
/// and we forward the [BoxContainer]'s [_children] to the [UniqueKeyedObjectsManager]'s [keyedMembers];
/// we also ensure that in [BoxContainer]'s constructor, after [BoxContainer]'s [_children] change, we call [ensureKeyedMembersHaveUniqueKeys].
abstract class UniqueKeyedObjectsManager {

  /// Holder of the [Keyed] members, which keys must stay unique.
  ///
  /// Serves as a backing [Iterable] of the [Keyed] objects
  /// this holder manages.
  ///
  /// Implementors need to override this
  /// method to start holding uniquely [Keyed] objects.
  List<Keyed> get keyedMembers;

  Iterable<ContainerKey> get _memberKeys => keyedMembers.map((Keyed keyed) => keyed.key);

  Keyed getKeyedByKey(ContainerKey containerKey) {
    return keyedMembers.firstWhere((Keyed keyed) => keyed.key == containerKey);
  }

  /// Checks uniqueness of all managed [Keyed] members.
  ///
  /// Implementors must call this method every time after the list backing
  /// the [keyedMembers] is modified.
  ///
  /// As by default, the [BoxContainer._children], is the list backing the [UniqueKeyedObjectsManager.keyedMembers],
  /// this method must be called after changing [_children].
  void ensureKeyedMembersHaveUniqueKeys() {
    // toSet converts to set using ==.
    // If lengths do not match, there are at least two == keys in [keys].
    Set toSet = _memberKeys.toSet();
    if (toSet.length != _memberKeys.length) {
      throw StateError('ensureKeyedMembersHaveUniqueKeys:  keys $_memberKeys of members $keyedMembers are not unique');
    }
  }
}