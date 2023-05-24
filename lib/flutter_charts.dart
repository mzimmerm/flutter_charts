library flutter_charts; // Not necessary, would default to file name 'flutter_charts.dart'
///
/// **This file [root/lib/flutter_charts.dart]
///    _IS the flutter_charts library package_,
///    and can be used by _external code_ OR _code inside this lib/src_.**
///
/// The core of how library packages work in Dart can be summarized in A, B, below:
///
///   A. Files _exported_ in this file, should be exported as
///       ```dart
///         export 'src/chart/data_model.dart';
///       ```
///      are visible to external applications.
///
///   B. External applications (to which the contents of the _lib_
///        directory is copied through pub) can use the library exported in A.
///        using code like this
///       ```dart
///         import 'package:flutter_charts/flutter_charts.dart';
///       ```
///
/// Code in this project, under [root/lib] directory can import this package's code IN 3 WAYS:
///     1. Either using the same package: scheme, as above external code, for example
///       ```dart
///         import 'package:flutter_charts/flutter_charts.dart';
///       ```
///       Note 1: Only libraries (dart files) listed as `export` in `flutter_charts.dart`
///               are made available to the file with this import clause!
///               For libraries NOT-EXPORTED in `flutter_charts.dart`,
///               we have to use one of the 'code local' schemes in the item below.
///       Note 2: The package: scheme in 1. MUST BE USED IN a) example/lib and b) in tests.
///               Both appear to be able to import relative, crossing the 'lib' boundary,
///               but THEN FLUTTER THINGS THOSE ARE DIFFERENT LIBRARIES!
///     2. Or using a RELATIVE PATH SCHEME, for example from a .dart file located 
///        in flutter_charts/(lib)/src/chart/bar, CAN REACH EXPORTED OR NOT-EXPORTED LIBRARY
///       ```dart
///          // Note: Below, we have to ascend on the 'src' level as in the first line. 
///                   We can ascend above 'src', but that is not needed. So use the first form  
///          import '../../chart/root_container.dart'; // relative path
///          import '../../../src/chart/root_container.dart'; // relative path
///          // Note: THE ABOVE IS PROBABLY THE PREFERRED FORM AS IT MAKES HIERARCHY CLEAR
///          import 'src/util/examples_descriptor.dart'; // relative path ONLY FROM example/src/main.dart
///       ```
///     3. Or using an ABSOLUTE PATH SCHEME, WHICH STARTS WITH THE PACKAGE NAME, AND PROVIDES FULL PATH
///        TO EXPORTED OR NOT-EXPORTED LIBRARY, for example
///       ```dart
///         import 'package:flutter_charts/src/chart/root_container.dart';
///       ```
///
/// Any dart file (any client application) located outside
/// of the "lib" directory just above, can only see the classes
/// contained in the exported packages listed in this file, flutter_charts.dart.
///
/// Why? The reasons are complex combination of Dart conventions.
///
/// 1. First: what makes the directory structure starting from the project root level `flutter_charts`
///            a **“library package”** (or **”pub package”**) named `flutter_charts`?
///     Four requirements must be satisfied:
///       1. In the `root directory`, the existence of file `pubspec.yaml`.
///       2. In `pubspec.yaml`, the presence of the following line
///         `name: flutter_charts`. This line gives the library
///         it's name on pub.
///       3. Under the `root directory`, the existence of directory `lib`.
///       4. Under lib, the existence of file named `flutter_charts.dart`.
///          This file contains the exported dart files (which are also libraries)
///          that are under `src`.
///
/// 2. Second: Why is this file _flutter_charts.dart_ needed?
///      Because dart tools have the
///      convention to consider everything under lib/src private
///      and not visible to external Dart files (if we  were too,
///      for example, copy the whole  root directory under `flutter_charts`
///      to some other project). So this file, _flutter_charts.dart_
///      provides the public API to our package `flutter_charts`.
///      All classes (and only those classes) listed "exported" in this file,
///      are visible externally to other packages (libraries) and applications
///      which depend on it.
///
/// 3. Third:  Why so complicated?
///      This is an unfortunate result Dart
///      not being Newspeak :)  a Dart apologetic, this is the
///      Dart way of providing ability to create private classes in
///      public libraries we share with the world.
///
/// Notes:
///
///  1.  When writing the export code such as in this file, flutter_charts/lib/flutter_charts.dart,
///      both formats below are equivalent:
///       ```dart
///         export 'package:flutter_charts/src/chart/line/chart.dart'; // lib not named in path
///         export 'src/chart/line/chart.dart'; // even though under lib - 2021-12-12 preferred format
///       ```
///      the *lib level above src  is skipped - not specified*
///      Basically files under ‘lib/src’ are private (unless exported) even for other files in project.
///  2.  Generally, external code can import
///      all classes in one library in one line, referencing this file
///      ```dart
///        import 'package:flutter_charts/flutter_charts.dart';
///      ```
///  3. We can say that **files below the _lib/src_ directory in Dart,
///     are by convention, private, and invisible above the _lib_ directory.
///     ```dart
///        export 'package:flutter_charts/src/chart/data_model.dart';
///     ```
///  5. In each of the export lines, we could control exported classes
///     by name using the `show` syntax, for example:
///     ```dart
///        export 'package:flutter_charts/src/chart/data_model.dart' show ChartData;
///     ```

/// Important:
///   In the package import and export paths, the 'lib' node is skipped. This is a convention.
///   We write
///   ```dart
///     import 'package:flutter_charts/flutter_charts.dart'
///   ```
///   even though `flutter_charts.dart` path is `flutter_charts/lib/flutter_charts.dart`.
///
/// Terminology:
/// - 'Envelope' always means an double interval which contains all items in a List<double>. Envelop can be:
///   - A 'tight envelope' - the smallest such interval
///   - An 'extension' of such interval. The extension typically starts at 0.0 if all values in List<double> are positive,
///     or ends at 0.0 if all values in List<double> are negative.
///
/// - 'dataY' ANY variable named dataYs in the chart objects, once they are copied out of ChartData
///   are always lifecycled in this order
///   1. transformed, then
///   2. potentially stacked IN PLACE, then
///   3. potentially extrapolated IN A COPY!!
///   This is the sequence that always happens. The transform is by default an identity
///
/// - 'chart area'  is the full size given to the [ChartPainter] by the application.
///
/// - 'absolute positions' in 'Container' classes refer to the positions
///   "in the coordinates of the 'chart area'".
///
/// - 'data', 'dataY' represents transformed, not-stacked not-extrapolated data.
///
/// - 'rawData' 'rawDataY' represents original not-transformed data.
///   - Most of the code deals with 'transformed data', named 'data', which is nice and short.
///     Places in code where we see 'rawData' are not-transformed original data,
///     except in `ChartModel.dataRows` which contains raw data.
///

export 'src/chart/chart_type/line/chart.dart';
export 'src/chart/chart_type/line/options.dart';
export 'src/chart/chart_type/bar/chart.dart';
export 'src/chart/chart_type/bar/options.dart';

export 'src/chart/chart_label_container.dart';
export 'src/chart/view_model/view_model.dart';
export 'src/chart/container/axis_container.dart';
export 'src/chart/container/axis_corner_container.dart';
export 'src/chart/container/container_common.dart';
export 'src/chart/container/data_container.dart';
export 'src/chart/container/line_segment_container.dart';
export 'src/chart/container/root_container.dart';
export 'src/chart/model/data_model.dart';
export 'src/chart/iterative_layout_strategy.dart';
export 'src/chart/options.dart';

export 'src/chart/model/random_chart_data.dart';
export 'src/util/util_dart.dart';
export 'src/util/util_flutter.dart';
export 'src/chart/view_model/label_model.dart';

// export 'src/coded_layout/chart/data_model.dart';
export 'src/coded_layout/chart/container.dart';
export 'src/coded_layout/chart/chart_type/line/root_container.dart';
export 'src/coded_layout/chart/chart_type/bar/root_container.dart';

export 'src/switch_view_model/auto_layout/line/view_model.dart';
