import 'matrix_2d.dart';

typedef DoubleToDoubleFunction = double Function(double);

/// Each instance of this class is a Functional in the Function space (the set of oll its instances).
///
/// Actually, each instance of this class can also act as a function from which it was created;
/// however, the methods defined make the function also a functional. This definition is not the same
/// as one used in math, so read before for details
///
/// Let FSet be a set of functions f: set X -> vector-space V over field F
/// Functional is a mapping m: set of functions FSet -> the same FSet.
/// Functional Space is the set of all such Functionals.
///
/// There are two operations on the Functional space (the mapping FSet -> FSet)
///   +:         (FSet, FSet) -> FSet
///   *(or dot): (F, FSet)    -> FSet
/// WITH SUCH 2 OPERATIONS, FUNCTIONAL SPACE IS A LINEAR SPACE OVER THE FIELD F.
///
/// Rephrasing the above a bit more precisely:
///
/// A (Vector-valued) Function space is defined as follows:
/// - Given
///   - F, a field
///   - V, a vector space over field F
///   - X, any set
///   - FSet, a set of vector-valued functions from X -> V, with the following operations on the left:
///     - + : (FSet, FSet) -> FSet, in other words, (f, g) -> f + g
///       - for any f, g in FSet, any x in X
///           (f + g)(x) = f(x) + g(x) // operation + on the right is the "+" in the the vector space V
///     - * (or dot) : (F, FSet) -> FSet, in other words, (c, f) -> c * g
///       - for any f in FSet, any x in X, any c in F
///           (c * f)(x) = c * f(x) // operation * on the right in V is the "*" in the vector space V
///   - Then we say that the tuple (F, V, X, FSet) with the above operations is a FUNCTION SPACE.
///
/// - With the above definition:
///   - If X is ALSO a vector space over F (not just a set), then (see https://en.wikipedia.org/wiki/Function_space)
///     - The subset of FSet, formed by the set of linear maps X → V (are there always linear maps among set of functions???)
///       form a vector space over F with pointwise operations (denoted Hom(X,V)).
///     - One such space is the DUAL VECTOR SPACE of V: the set of linear functionals V → F
///       with addition and scalar multiplication defined pointwise in F.
///   - it can be shown that *FSet is a Vector space over the field F*
///
/// This class defines, in addition to the "+" and "*" operations, the "compose" operation f(g(x)) from X -> V,
/// and the "apply" operation, same as application of it's member function [fun] .
/// All functions this class defines:
///   -
///   - The "+"       (FSet, FSet) -> FSet : DoubleToDoubleFunction addT(DoubleToDoubleFunction other)       => (double arg) => fun(arg) + other(arg);
///   - The "*"       (F, FSet)    -> FSet : DoubleToDoubleFunction multiplyN(double number) => (double arg) => number * fun(arg);
///   - The "compose" (FSet, FSet) -> FSet : (DoubleToDoubleFunction composeT(DoubleToDoubleFunction other)  => (double arg) => fun(other(arg));
///     - This is possible to define only if f: X -> V is composable X -> V -> V, that is, X = V, that is, X is also a Vector space.
///     - In our situation this is true, because we use: X = V = double
///   - The "apply"   X -> V               : double applyOnN(double arg)                                      => fun(arg); // function(number)
///     - This allows the instance of Functional also act as a function X -> V in general, and, double -> double in our situation.
///     - So due to the special case we have, X = V = double, the DUAL VECTOR SPACE (set of Functionals)
///       is isomorphic to the set of functions [fun] (hmm, really? how?)
///
class Functional {

  const Functional(this.fun);

  /// == will be true (todo 010 - test)
  factory Functional.identity() {
    return _identity;
  }

  /// == will be true (todo 010 - test)
  factory Functional.zero() {
    return _zero;
  }

  /// == will be false (todo 010 - test)
  factory Functional.constant(double c) {
    return Functional( (double x) => c );
  }

  /// The function defining this functional.
  final DoubleToDoubleFunction fun;

  static final Functional _identity = Functional( _identityDD );
  static final Functional _zero = Functional( _toZeroD );

  call(double number) {
    // return fun(number);
    throw StateError('For clarity: Functional is not a generic function. '
        'Functional supports only Object methods, and methods defined on it.');
  }

  DoubleToDoubleFunction addT(DoubleToDoubleFunction other) => (double arg) => fun(arg) + other(arg);
  DoubleToDoubleFunction multiplyN(double number) => (double arg) => number * fun(arg);
  DoubleToDoubleFunction composeT(DoubleToDoubleFunction other) => (double arg) => fun(other(arg)); // * is compose
  double applyOnN(double arg) => fun(arg); // function(number)

}

DoubleToDoubleFunction _toZeroD = (double x) => 0.0;
DoubleToDoubleFunction _identityDD = (double x) => x;

// class FunctionMatrix2D<T extends DoubleToDoubleFunction> extends Matrix2D {
class FunctionalMatrix2D<T extends Functional> extends Matrix2D {
  FunctionalMatrix2D(List<List<T>> from) : super(from);

  /// T should be either number or functional,
  @override
  get zeroOfT => _toZeroD;
  /// Addition:   number to number it T is number, functional to functional if T is functional
  @override
  addTT(t1, t2) => t1.addT(t2.fun);
  /// Multiplication: number by number it T is number, number by functional if T is functional
  @override
  multiplyNT(double number, t) => t.multiplyNT(number);
  /// Multiplication if T is number, composition if T is functional
  @override
  multiplyOrComposeTT(t1, t2) => t1.composeT(t2.fun);
  /// Multiplication if T, N both numbers, call T(n) if T is a functional
  @override
  multiplyOrApplyTN(t, double n) => t.applyOnN(n);

  /// This test of equality a fake. There is no way (mirrors?) to define 'natural' equality between functions.
  /// We fake it, for test purposes, by applying on two numbers, 1 and 2
  @override
  bool equalsTT(first, second) {
    for (double d in [1.0, 2.0]) {
      if (multiplyOrApplyTN(first, d) != multiplyOrApplyTN(second, d)) {
        return false;
      }
    }
    return true;
  }
}

