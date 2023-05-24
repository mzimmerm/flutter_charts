import 'package:test/test.dart';

void main() {

  group('Functions', () {
    group('Functions == : Same result producing functions are not ==', () {
      double f(double arg) => arg * arg;
      double g(double arg) => arg * arg;
      test('f == g', () {
        assert(f == f, true);
        assert(g == g, true);
        // Always throws, whether true or false. Use expect instead of assert: assert(f == g, true);
        expect((f == f), true);
        expect((g == g), true);
        expect((f == g), false);
        });
      });
    });

}

