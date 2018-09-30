///
/// **This file [root/lib/flutter_charts.dart]
///    _IS the flutter_charts package_,
///    and can be used by _external code_ OR _code inside the same lib_.**.
///
/// Basically, files _exported_ in this file, for example
///
/// > export 'src/chart/data.dart';
///
/// are visible to external applications (to which the contents of the _lib_
/// directory is copied through pub) using code like this
///
///       > import 'package:flutter_charts/flutter_charts.dart';
///
/// Code under [root/lib] directory
///     1. can use same _import 'package:etc'_ as above external code
///     2. or file scheme, e.g.
///     > import 'src/chart/data.dart';
///
/// Any dart file (any client application) located outside
/// of the "lib" directory just above, can only see the classes
/// contained in the exported packages listed in this file, flutter_chart.dart.
///
/// Why? The reasons are complex combination of Dart conventions.
///
/// 1. First:  what makes the directory structure starting from the top level
///            `flutter_charts` (call it `root directory`)
///            a **“library package”** (or **”pub package”**)
///            named `flutter_charts`?
///     Four requirements must be satisfied:
///       1. In the `root directory`, the existence of file `pubspec.yaml`.
///       2. In `pubspec.yaml`, the presence of the following line
///         `name: flutter_charts`. This line gives the library
///         it's name on pub.
///       3. Under the `root directory`, the existence of directory `lib`.
///       4. Under lib, the existence of file named `flutter_charts.dart`.
///          This file contains the exported dart files (libraries)
///
/// 2. Second: Why is this file needed?
///      Because dart tools have the
///      convention to consider everything under lib/src private
///      and not visible to external Dart files (if we  were too,
///      for example, copy the whole  root directory under `flutter_charts`
///      to some other project). So this file, _flutter_charts.dart_
///      provides the public API to our package `flutter_charts`.
///      All classes (and oly those classes) listed "exported" in this file,
///      are visible externally.
///
/// 3. Third:  Why so complicated?
///      This is an unfortunate result Dart
///      not being Newspeak :)  a Dart appologetic, this is the
///      Dart way of providing ability to create private classes in
///      public libraries we share with the world.
///
/// Notes:
///
///  1.  Paths in export the *lib level is skipped*
///      starting with the ‘src’ representing Private.
///         `export 'src/chart/torefactor/line_chart.dart';` // even though under lib
///  2.  Generally, external code can import
///      all classes in one library in one line, referencing this file
///         `import 'package:flutter_charts/flutter_charts.dart';`
///  3. We can say that **files below the _lib/src_ directory in Dart,
///     are by convention, private, and invisible above the _lib_ directory.
///  4. Equivalent export syntaxes
///     - `export                        'src/chart/data.dart'`
///     - `export 'package:flutter_charts/src/chart/data.dart'`
///

/// Note:
/// Export path starts after lib, whether using
///   'package:flutter_charts' format or 'src/' format.
///
export 'package:flutter_charts/src/chart/label_container.dart';
export 'package:flutter_charts/src/util/random_chart_data.dart';

export 'package:flutter_charts/src/util/util.dart';
export 'package:flutter_charts/src/util/range.dart';

export 'package:flutter_charts/src/chart/data.dart';
export 'package:flutter_charts/src/chart/container.dart';
export 'package:flutter_charts/src/chart/iterative_layout_strategy.dart';
export 'package:flutter_charts/src/chart/options.dart';

export 'package:flutter_charts/src/chart/line/chart.dart';
export 'package:flutter_charts/src/chart/line/painter.dart';
export 'package:flutter_charts/src/chart/line/container.dart';
export 'package:flutter_charts/src/chart/line/options.dart';

export 'package:flutter_charts/src/chart/bar/chart.dart';
export 'package:flutter_charts/src/chart/bar/painter.dart';
export 'package:flutter_charts/src/chart/bar/container.dart';
export 'package:flutter_charts/src/chart/bar/options.dart';

export 'package:flutter_charts/src/util/random_chart_data.dart';
