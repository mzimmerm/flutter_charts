# Version 0.5.0 (2022-01-28)

## Functional improvements

1. To address issue #36, this version allows flutter_charts labels to use a custom font family.
   See the section for `ex34OptionsDefiningUserTextStyleOnLabels` in https://pub.dev/packages/flutter_charts
.   
   Also see https://github.com/mzimmerm/flutter_charts/blob/master/doc/readme_images/ex34OptionsDefiningUserTextStyleOnLabels_lineChart.png

## API changes

The `ChartOptions` that were previously set in LabelCommonOptions AND which are properties of Flutter `TextStyle`, 
(previously `LabelCommonOptions.labelFontSize` and `LabelCommonOptions.labelTextColor`) are removed in this version.  
In this version, such properties can be set as named parameters defined in the getter `LabelCommonOptions.labelTextStyle`.
To set those property values, the client has to create their own extension of `LabelCommonOptions`, overriding the getter `labelTextStyle`,
and setting such properties.
 See the section for `ex34OptionsDefiningUserTextStyleOnLabels` in https://pub.dev/packages/flutter_charts
.   
## Other changes

Google Fonts family `Comforter` was installed in this library to present examples of flutter_charts labels with a custom font family, 
and a line such as `GoogleFonts.config.allowRuntimeFetching = false;` was added to `main.dart`.

This is needed because of an apparent Flutter integration tests bug: for a custom font family such as Google Fonts to be used in integration driver tests,
the fonts need to be installed. This is ONLY for the benefit of integration tests. To run the app, none of the 2 changes are needed!

See notes in `pubspec.yaml` and in code around `Comforter`. 

I may consider removing those fonts, but keep them in this version for demonstration. 

See example `ex34OptionsDefiningUserTextStyleOnLabels`.


# Version 0.4.0 (2022-01-10)

## Functional improvements

1. Y axis can start at non-zero, request #31. See 
  - Details: Implemented issue request #31 https://github.com/mzimmerm/flutter_charts/issues/31 . Flutter_charts allows the Y axis to start at the minimum Y data values, rather than always from 0.0. 
  - Code Notes: See method `DataContainerOptions.startYAxisAtDataMinRequested` and option `ChartBehavior.startYAxisAtDataMinAllowed`.
  - More Details:
    - The option `startYAxisAtDataMinRequested` should only be `true` if data values are either all positive or all negative.
    - When all Y values are negative, Y axis starts at the minimum and tops at the maximum of Y values.
    - The option `startYAxisAtDataMinRequested` interacts with data transforms such as logarithmic scale, in the sense that the minimum on Y axis is the minimum transformed value.

2. Added logarithmic scale, request #22
  - Details: This release added logarithmic scale display. Any other reversible transform of data are also supported. This goes a bit beyond the issue request #22 in https://github.com/mzimmerm/flutter_charts/issues/22, which asks for logarithmic scale, but essentially this version implements #22. See the option `DataContainerOptions.yTransform`, and the example `ex52AnimalsBySeasonLogarithmicScale` in README.

## API changes

There are API changes in this release. Below may or may not be a full list

1. `ChartData` now 'knows' about `ChartOptions`, as data validation needs to know about options. For example, `ChartData` now needs to check if data are all positive, if the `ChartOptions` ask for a logarithmic scale. 

2. As a consequence of the above change, `ChartOptions` parameter has been removed from the `ChartTopContainer` constructors (such as `BarChartTopContainer`), and moved to `ChartData` constructors.

# Version 0.3.1 (2021-12-19)

1. Fixed error when all passed data are 0.0



# Version 0.3.0 (2021-12-17)

## API changes
1. `BarChart`, `LineChart` API changes: Removed the container parameter from the constructor of BarChart and LineChart.
    The container is now passed to the painter. A client example of creating a BarChart:
    ```dart
        ChartData chartData = RandomChartData();
        ChartOptions chartOptions = BarChartOptions();

        BarChartTopContainer barChartContainer = BarChartTopContainer(
          chartData: chartData,
          chartOptions: chartOptions,
          // optional xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        );
    
        BarChart barChart = BarChart(
          painter: BarChartPainter(
            barChartContainer: barChartContainer,
          ),
        );

    ```
    - If the container was passed before, it needs to be removed. 
    - The container is stored on the BarChartPainter and used from there.
    - A similar situation for the LineChart.
2. `ChartOptions`, `LineOptions`, `BarChartOptions` API changes. The constructors of all the options classes have changed. `ChartOptions` were split to `IterativeLayoutOptions`, `LegendOptions`, `XContainerOptions`, `YContainerOptions`, `DataContainerOptions`, and `LabelCommonOptions`. Please check the code in `example/main_run_doc_example.dart` which contains examples of how to create instances of those classes.

## Functional improvements

1. The optional ability to hide labels (on x axis, y axis), hide the legend, and hide the gridline has been added. This feature is controlled by ChartOptions. See the code in `example/main_run_doc_example.dart`. This is an out of context example of how to create the options that ignore all labels, legend, and gridline. Ignoring only one, or any combination will also work
    ```dart
      ChartOptions chartOptions = BarChartOptions.noLabels();
    ```
    or to set individual values to false. Default is true so no need to set
    ```dart
      ChartOptions chartOptions =
            BarChartOptions(
                chartOptions: const ChartOptions(
                  legendOptions: LegendOptions(
                    isLegendContainerShown: false,
                  ),
                  xContainerOptions: XContainerOptions(
                    isXContainerShown: false,
                  ),
                  yContainerOptions: YContainerOptions(
                    isYContainerShown: false,
                    isYGridlinesShown: false,
                  ),
                )
            );
    ```

## Added integration tests, including taking screenshots for comparison

All tests can be run using
```shell
tool/test/run_all_tests.sh
```
## Large amount of refactoring.

This is part of a process to make everything a container. Getting there.

# Version 0.2.0 (2021-03-07)

Support for null safety.

# Version 0.1.10 (2018-09-30)

Corrected formatting, and a few formal changes from pub auto-checking.

# Version 0.1.9 (2018-09-28)

Compatibility with Dart 2.0

# Version 0.1.8 (2018-06-20)

## Enhancements

### Making the codebase Dart 2 clean

Made changes to remove any analyser messages with Dart 2.

### *Labels auto layout* - added pluggable and automated ability to ensure that labels "fit", and do not overlap
 
This release added the ability to "iteratively auto layout" labels. 

Labels auto layout is a sequence of steps, such as skipping some labels, tilting labels, or decreasing label font, that result in label 'fit' nicely, readably, without overflowing or running into each other.

The ability to auto layout labels is implemented using a pluggable base class `LabelLayoutStrategy`, and a concrete implemented extension `DefaultIterativeLabelLayoutStrategy`. This default implementation of the iterative auto layout achieves that labels, defines a zero or more sequences of steps,
each performing a specific code to achieve labels fit, such as:
- Skipping every 2nd label
- Tilting all labels
- Decreasing label font size

The term "iterative" in  "iteratively auto layout" refers to the fact the  `LabelLayoutStrategy` repeates the layout steps multiple times, until a good fit is achieved.

The  `LabelLayoutStrategy` and extensions, including the default `DefaultIterativeLabelLayoutStrategy`, are members of containers which implement the `AdjustableContent`, or extend the abstract `AdjustableContentChartAreaContainer`. The term "adjustable content" here refers to ability to adjust sizes of child components, or even remove child components which would overlap in default conditions (sizes, and mumbers). See usages of `_xContainerLabelLayoutStrategy` in the sample app `example/main_run_doc_example.dart` for an example how to use custom `LabelLayoutStrategy` extensions. In practice, `AdjustableContent` is only used for multiple potentially overlaping labels. This knowledge is not necessary for most users who are merely using the default (not built in) iterative auto layout provided by the  `AdjustableContentChartAreaContainer`.

To learn more about the new auto layout process, see the [README.md](README.md) section "Illustration of the new "iterative auto layout" feature".

### Graceful skipping of legend

This release added the ability to skip the legend, when there is insufficient horizontal space. 

## Fixes

### Fixed a bug reported by Lorenzo Tejera, using this data

``` dart
  void defineOptionsAndData() {
    _lineChartOptions = new LineChartOptions();
    _barChartOptions = new BarChartOptions();
    _chartData = new ChartData();
    _chartData.dataRowsLegends = [
      "Spring",
      "Summer"
    ];
    _chartData.dataRows = [
      [1.0, 2.0, 3.0, 4.0],
      [4.0, 3.0, 5.0, 6.0]
    ];
    _chartData.xLabels = ["One", "Two", "Three", "Four"];
    _chartData.assignDataRowsDefaultColors();
    // Note: ChartOptions.useUserProvidedYLabels default is still used (false);
  }
```

Reason: This code - revisit when removing need for double data

``` dart
        if (signMax <= 0) {
          from = min;
          to = 0.0; // was 0, caused issues in Interval typed as double.
        } else {
          from = 0.0;// was 0, caused issues in Interval typed as double.
          to = max;
        }
```

# v0.1.7 (2017-12-17)

Fixed README.md error - images failing to show (https://github.com/mzimmerm/flutter_charts/issues/8)

# v0.1.6 (2017-12-03)

## Implemented change in https://github.com/mzimmerm/flutter_charts/issues/5  - allows to set paint on line chart hotspot circles
Added the following new line chart options in `charts/line/options.dart`
``` dart
  ui.Paint hotspotInnerPaint = new ui.Paint()
    ..color = material.Colors.yellow;

  ui.Paint hotspotOuterPaint = new ui.Paint()
    ..color = material.Colors.black;

  double lineStrokeWidth = 3.0;
```

## Implemented change in https://github.com/mzimmerm/flutter_charts/issues/6 - line chart allows to reverse order of data series (`dataRows`) to make the significant series line to be on top 
Added the following new chart options in `charts/options.dart`

``` dart
  bool firstDataRowPaintedFirst = true;
``` 

## Made several text options configurable

Moved the following to options in `charts/options.dart` (from being hardcoded)

``` dart
  painting.TextStyle labelTextStyle = new painting.TextStyle(
    color: material.Colors.grey[600],
    fontSize: 14.0,);

  ui.TextDirection labelTextDirection   = ui.TextDirection.ltr;
  ui.TextAlign     labelTextAlign       = ui.TextAlign.center;
  double           labelTextScaleFactor = 1.0;
```

## Renamed option `xTopMinTicksHeight` to `xTopPaddingAboveTicksHeight`
New name reflects the usage better.

# v0.1.5 (2017-10-27)

This version finally fixed issue https://github.com/mzimmerm/flutter_charts/issues/2 - flutter charts not actually working as a library package (reason: incorrectly specified dependencies).
# v0.1.4 (2017-10-27)

- Only changes in documentation. Also publishing using `flutter packages pub publish` instead of previously incorrect `pub publish` which resulted in a package that reports error on clients' getting the package using `flutter pub get`. Hopefully this change will fix the issue. Below is the full error this new version is trying to fix:

The following log is from a test app in https://github.com/mzimmerm/flutter_charts_sample_app. It is mostly relevant as a documentation of the issue, client apps can ignore this.
```
flutter_charts_sample_app> flutter pub get      
Running "flutter packages get" in flutter_charts_sample_app...      
Package flutter_charts has no versions that match >=0.1.3 <0.2.0 derived from:
- flutter_charts_sample_app depends on version ^0.1.3
---- Log transcript ----
FINE: Pub 1.25.0-dev.11.0
MSG : Resolving dependencies...
SLVR: Solving dependencies:
    | - flutter_charts ^0.1.3 from hosted (flutter_charts)
    | - flutter any from sdk (flutter) (locked to 0.0.37)
IO  : Get versions from https://pub.dartlang.org/api/packages/flutter_charts.
IO  : HTTP GET https://pub.dartlang.org/api/packages/flutter_charts
    | Accept: application/vnd.pub.v2+json
    | X-Pub-OS: linux
    | X-Pub-Command: get
    | X-Pub-Session-ID: 8D558B08-DBBE-4D24-AB8F-C0EEC36157B2
    | X-Pub-Environment: flutter_cli
    | X-Pub-Reason: direct
    | user-agent: Dart pub 1.25.0-dev.11.0
IO  : HTTP response 200 OK for GET https://pub.dartlang.org/api/packages/flutter_charts
    | took 0:00:00.332100
    | transfer-encoding: chunked
    | date: Tue, 28 Nov 2017 05:32:06 GMT
    | content-encoding: gzip
    | vary: Accept-Encoding
    | via: 1.1 google
    | content-type: application/json
    | x-frame-options: SAMEORIGIN
    | x-xss-protection: 1; mode=block
    | x-content-type-options: nosniff
    | server: nginx
SLVR: * start at root
SLVR: | flutter 0.0.37 from sdk is locked
SLVR: | * select flutter 0.0.37 from sdk
SLVR: | | collection 1.14.3 from hosted is locked
SLVR: | | * select collection 1.14.3 from hosted
SLVR: | | | http 0.11.3+14 from hosted is locked
SLVR: | | | * select http 0.11.3+14 from hosted
SLVR: | | | | async 1.13.3 from hosted is locked
SLVR: | | | | * select async 1.13.3 from hosted
SLVR: | | | | | http_parser 3.1.1 from hosted is locked
SLVR: | | | | | * select http_parser 3.1.1 from hosted
SLVR: | | | | | | charcode 1.1.1 from hosted is locked
SLVR: | | | | | | * select charcode 1.1.1 from hosted
SLVR: | | | | | | | meta 1.1.1 from hosted is locked
SLVR: | | | | | | | * select meta 1.1.1 from hosted
SLVR: | | | | | | | | path 1.4.2 from hosted is locked
SLVR: | | | | | | | | * select path 1.4.2 from hosted
SLVR: | | | | | | | | | sky_engine 0.0.99 from path is locked
SLVR: | | | | | | | | | * select sky_engine 0.0.99 from path
SLVR: | | | | | | | | | | source_span 1.4.0 from hosted is locked
SLVR: | | | | | | | | | | * select source_span 1.4.0 from hosted
SLVR: | | | | | | | | | | | stack_trace 1.8.2 from hosted is locked
SLVR: | | | | | | | | | | | * select stack_trace 1.8.2 from hosted
SLVR: | | | | | | | | | | | | string_scanner 1.0.2 from hosted is locked
SLVR: | | | | | | | | | | | | * select string_scanner 1.0.2 from hosted
SLVR: | | | | | | | | | | | | | typed_data 1.1.4 from hosted is locked
SLVR: | | | | | | | | | | | | | * select typed_data 1.1.4 from hosted
SLVR: | | | | | | | | | | | | | | vector_math 2.0.5 from hosted is locked
SLVR: | | | | | | | | | | | | | | * select vector_math 2.0.5 from hosted
SLVR: | | | | | | | | | | | | | | | inconsistent source "hosted" for flutter:
    | | | | | | | | | | | | | | | |   flutter_charts 0.1.3 from hosted -> flutter >=0.0.20 <0.1.0 from hosted (flutter)
    | | | | | | | | | | | | | | | |   flutter_charts_sample_app 0.0.0 (root) -> flutter any from sdk (flutter)
SLVR: | | | | | | | | | | | | | | | version 0.1.2 of flutter_charts doesn't match >=0.1.3 <0.2.0:
    | | | | | | | | | | | | | | | |   flutter_charts_sample_app 0.0.0 (root) -> flutter_charts ^0.1.3 from hosted (flutter_charts)
SLVR: | | | | | | | | | | | | | | | version 0.1.1 of flutter_charts doesn't match >=0.1.3 <0.2.0:
    | | | | | | | | | | | | | | | |   flutter_charts_sample_app 0.0.0 (root) -> flutter_charts ^0.1.3 from hosted (flutter_charts)
SLVR: | | | | | | | | | | | | | | | version 0.1.0 of flutter_charts doesn't match >=0.1.3 <0.2.0:
    | | | | | | | | | | | | | | | |   flutter_charts_sample_app 0.0.0 (root) -> flutter_charts ^0.1.3 from hosted (flutter_charts)
SLVR: BacktrackingSolver took 0:00:00.516136 seconds.
    | - Tried 1 solutions
    | - Requested 1 version lists
    | - Looked up 1 cached version lists
    | 
FINE: Resolving dependencies finished (0.5s).
ERR : Package flutter_charts has no versions that match >=0.1.3 <0.2.0 derived from:
    | - flutter_charts_sample_app depends on version ^0.1.3
FINE: Exception type: NoVersionException
FINE: package:pub/src/entrypoint.dart 195                                             Entrypoint.acquireDependencies
    | package:pub/src/command/get.dart 38                                             GetCommand.run
    | package:args/command_runner.dart 194                                            CommandRunner.runCommand
    | package:pub/src/command_runner.dart 168                                         PubCommandRunner.runCommand.<fn>
    | dart:async                                                                      new Future.sync
    | package:pub/src/utils.dart 102                                                  captureErrors.<fn>
    | package:stack_trace                                                             Chain.capture
    | package:pub/src/utils.dart 117                                                  captureErrors
    | package:pub/src/command_runner.dart 168                                         PubCommandRunner.runCommand
    | package:pub/src/command_runner.dart 117                                         PubCommandRunner.run
    | /b/build/slave/dart-sdk-linux-dev/build/sdk/third_party/pkg/pub/bin/pub.dart 8  main
    | ===== asynchronous gap ===========================
    | dart:async                                                                      _Completer.completeError
    | package:pub/src/entrypoint.dart 243                                             Entrypoint.acquireDependencies
    | ===== asynchronous gap ===========================
    | dart:async                                                                      _asyncThenWrapperHelper
    | package:pub/src/entrypoint.dart 192                                             Entrypoint.acquireDependencies
    | package:pub/src/command/get.dart 38                                             GetCommand.run
    | package:args/command_runner.dart 194                                            CommandRunner.runCommand
    | ===== asynchronous gap ===========================
    | dart:async                                                                      new Future.microtask
    | package:args/command_runner.dart 142                                            CommandRunner.runCommand
    | package:pub/src/command_runner.dart 168                                         PubCommandRunner.runCommand.<fn>
    | dart:async                                                                      new Future.sync
    | package:pub/src/utils.dart 102                                                  captureErrors.<fn>
    | package:stack_trace                                                             Chain.capture
    | package:pub/src/utils.dart 117                                                  captureErrors
    | package:pub/src/command_runner.dart 168                                         PubCommandRunner.runCommand
---- End log transcript ----
pub get failed (1)
```

# v0.1.3 (2017-10-03)

- Only changes in README, to figure out how to include images (turns out all links must be external)

# v0.1.0 (2017-10-03)

- Initial push. Line chart and (vertical) bar chart support. Various options supported.

# Semantic Version 2.0.0 Conventions

This package follows Semantic Version 2.0.0.
http://semver.org/

Example: 1.2.3 means MAJOR.MINOR.PATCH

Development:         Major version zero (0.y.z) is for initial development. Anything may change at any time. The public API should not be considered stable.

API Stable versions: All versions with the same MAJOR, where MAJOR>0 must have the same API. 
