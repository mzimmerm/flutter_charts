import 'matrix_2d.dart';

typedef DoubleToDoubleFunction = double Function(double);

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

  final DoubleToDoubleFunction fun;

/*
  static final Functional _identity = Functional( (double x) => x );
  static final Functional _zero = Functional( (double x) => 0.0 );
*/
  static final Functional _identity = Functional( _identityDD );
  static final Functional _zero = Functional( _toZeroD );


  call(double number) {
    // return fun(number);
    throw StateError('For clarity: Functional is not a generic function. '
        'Functional supports only Object methods, and methods defined on it.');
  }

  DoubleToDoubleFunction addT(DoubleToDoubleFunction other) => (double arg) => fun(arg) + other(arg);
  DoubleToDoubleFunction multiplyN(double number) => (double arg) => number * fun(arg);
  DoubleToDoubleFunction multiplyT(DoubleToDoubleFunction other) => (double arg) => fun(other(arg)); // * is compose
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
  addTT(t1, t2) => t1.addT(t2);
  /// Multiplication: number by number it T is number, number by functional if T is functional
  @override
  multiplyNT(double number, t) => t.multiplyNT(number);
  /// Multiplication if T is number, composition if T is functional
  @override
  multiplyOrComposeTT(t1, t2) => t1.multiplyT(t2);
  /// Multiplication if T, N both numbFunctionalers, call T(n) if T is a functional
  @override
  multiplyOrApplyTN(t, double n) => t.applyOnN(n);

}


/*
// Not working illustration of a functional vector space.
// A functional vector space is defined as:
//   - F, a field
//   - V, a vector space over field F
//   - X, any set, a domain of functions from set FSet
//   - FSet, a set of vector-valued functions from X -> V, with the following operations:
//     - + : (FSet, FSet) -> FSet, in other words, (f, g) -> f + g
//       - for any f, g in FSet, any x in X
//           (f + g)(x) = f(x) + g(x) // operation + in V is valid
//     - * (or dot) : (F, FSet) -> FSet, in other words, (c, f) -> c * g
//       - for any f in FSet, any x in X, any c in F
//           (c * f)(x) = c * f(x) // operation * in V is valid
//
extension RealVectorSpace1D on double {}
extension RealField on double {}
extension RealFunctionDomain on double {}

class FunctionalVectorSpace {
  RealVectorSpace1D vectorSpace;
  RealField field;
  RealFunctionDomain functionDomain;
}
*/

