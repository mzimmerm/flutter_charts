<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Table of contents     :TOC:<a id="sec-1" name="sec-1"></a>](#table-of-contents-----toca-idsec-1-namesec-1a)
- [Flutter Charts - How to include the flutter\_charts library in your application<a id="sec-2" name="sec-2"></a>](#flutter-charts---how-to-include-the-fluttercharts-library-in-your-applicationa-idsec-2-namesec-2a)
- [An example of Flutter Chart output<a id="sec-3" name="sec-3"></a>](#an-example-of-flutter-chart-outputa-idsec-3-namesec-3a)
- [Known packages, libraries and apps that use this this flutter\_charts package<a id="sec-4" name="sec-4"></a>](#known-packages-libraries-and-apps-that-use-this-this-fluttercharts-packagea-idsec-4-namesec-4a)
- [Flutter Charts - an overview: data, options, classes<a id="sec-5" name="sec-5"></a>](#flutter-charts---an-overview-data-options-classesa-idsec-5-namesec-5a)
- [Experimenting with Flutter Charts: Using the included example app `file:example/lib/main.dart`<a id="sec-6" name="sec-6"></a>](#experimenting-with-flutter-charts-using-the-included-example-app-fileexamplelibmaindarta-idsec-6-namesec-6a)
- [Flutter Charts - examples: LineChart and VerticalBarChart. Code and resulting charts<a id="sec-7" name="sec-7"></a>](#flutter-charts---examples-linechart-and-verticalbarchart-code-and-resulting-chartsa-idsec-7-namesec-7a)
    - [Random Data (Y values), Random X Labels, Random Colors, Random Data Rows Legends, Data-Generated Y Labels.<a id="sec-7-1" name="sec-7-1"></a>](#random-data-y-values-random-x-labels-random-colors-random-data-rows-legends-data-generated-y-labelsa-idsec-7-1-namesec-7-1a)
    - [User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, Data-Generated Y Labels,<a id="sec-7-2" name="sec-7-2"></a>](#user-provided-data-y-values-user-provided-x-labels-random-colors-user-provided-data-rows-legends-data-generated-y-labelsa-idsec-7-2-namesec-7-2a)
    - [User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, User-Provided Y Labels<a id="sec-7-3" name="sec-7-3"></a>](#user-provided-data-y-values-user-provided-x-labels-random-colors-user-provided-data-rows-legends-user-provided-y-labelsa-idsec-7-3-namesec-7-3a)
- [VerticalBar Chart - one more example, showing positive/negative stacks:<a id="sec-8" name="sec-8"></a>](#verticalbar-chart---one-more-example-showing-positivenegative-stacksa-idsec-8-namesec-8a)
    - [User-Provided Data (Y values), User-Provided X Labels, User-Provided Colors, User-Provided Data Rows Legends, User-Provided Y Labels<a id="sec-8-1" name="sec-8-1"></a>](#user-provided-data-y-values-user-provided-x-labels-user-provided-colors-user-provided-data-rows-legends-user-provided-y-labelsa-idsec-8-1-namesec-8-1a)
- [Bugs status<a id="sec-9" name="sec-9"></a>](#bugs-statusa-idsec-9-namesec-9a)
- [Future enhancements and work<a id="sec-10" name="sec-10"></a>](#future-enhancements-and-worka-idsec-10-namesec-10a)
- [TODO Terminology and Selected Classes<a id="sec-11" name="sec-11"></a>](#todo-terminology-and-selected-classesa-idsec-11-namesec-11a)
- [Internal notes<a id="sec-12" name="sec-12"></a>](#internal-notesa-idsec-12-namesec-12a)
    - [DONE Add ability to create a Table of Contents to README.org<a id="sec-12-1" name="sec-12-1"></a>](#done-add-ability-to-create-a-table-of-contents-to-readmeorga-idsec-12-1-namesec-12-1a)
    - [Adding images to README.org<a id="sec-12-2" name="sec-12-2"></a>](#adding-images-to-readmeorga-idsec-12-2-namesec-12-2a)
    - [Pub - Publishing workflow on <https://pub.dartlang.org><a id="sec-12-3" name="sec-12-3"></a>](#pub---publishing-workflow-on-httpspubdartlangorga-idsec-12-3-namesec-12-3a)
        - [Notes:<a id="sec-12-3-1" name="sec-12-3-1"></a>](#notesa-idsec-12-3-1-namesec-12-3-1a)
        - [IF **README.md** needs change<a id="sec-12-3-2" name="sec-12-3-2"></a>](#if-readmemd-needs-changea-idsec-12-3-2-namesec-12-3-2a)
        - [**pubspec.yaml** - Increase version number<a id="sec-12-3-3" name="sec-12-3-3"></a>](#pubspecyaml---increase-version-numbera-idsec-12-3-3-namesec-12-3-3a)
        - [`cd flutter_charts; flutter packages pub upgrade`<a id="sec-12-3-4" name="sec-12-3-4"></a>](#cd-fluttercharts-flutter-packages-pub-upgradea-idsec-12-3-4-namesec-12-3-4a)
        - [`cd flutter_charts; flutter packages pub get`<a id="sec-12-3-5" name="sec-12-3-5"></a>](#cd-fluttercharts-flutter-packages-pub-geta-idsec-12-3-5-namesec-12-3-5a)
        - [Test included app from IntelliJ<a id="sec-12-3-6" name="sec-12-3-6"></a>](#test-included-app-from-intellija-idsec-12-3-6-namesec-12-3-6a)
        - [`git push`<a id="sec-12-3-7" name="sec-12-3-7"></a>](#git-pusha-idsec-12-3-7-namesec-12-3-7a)
        - [**README.md** on <https://github.com/mzimmerm/flutter_charts> - check if looks ok<a id="sec-12-3-8" name="sec-12-3-8"></a>](#readmemd-on-httpsgithubcommzimmermfluttercharts---check-if-looks-oka-idsec-12-3-8-namesec-12-3-8a)
        - [`flutter packages pub publish --dry-run`<a id="sec-12-3-9" name="sec-12-3-9"></a>](#flutter-packages-pub-publish---dry-runa-idsec-12-3-9-namesec-12-3-9a)
        - [`flutter packages pub publish`<a id="sec-12-3-10" name="sec-12-3-10"></a>](#flutter-packages-pub-publisha-idsec-12-3-10-namesec-12-3-10a)
        - [Check <https://pub.dartlang.org/packages/flutter_charts><a id="sec-12-3-11" name="sec-12-3-11"></a>](#check-httpspubdartlangorgpackagesflutterchartsa-idsec-12-3-11-namesec-12-3-11a)
        - [Test the package that was just published<a id="sec-12-3-12" name="sec-12-3-12"></a>](#test-the-package-that-was-just-publisheda-idsec-12-3-12-namesec-12-3-12a)

<!-- markdown-toc end -->

# Table of contents     :TOC:<a id="sec-1" name="sec-1"></a>

-   Flutter Charts - How to include the flutter\_charts library in your application (See section )
-   An example of Flutter Chart output (See section )
-   Known packages, libraries and apps that use this this flutter\_charts package (See section )
-   Flutter Charts - an overview: data, options, classes (See section )
-   Experimenting with Flutter Charts: Using the included example app `file:example/lib/main.dart` (See section )
-   Flutter Charts - examples: LineChart and VerticalBarChart. Code and resulting charts (See section )
    -   Random Data (Y values), Random X Labels, Random Colors, Random Data Rows Legends, Data-Generated Y Labels. (See section )
    -   User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, Data-Generated Y Labels, (See section )
    -   User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, User-Provided Y Labels (See section )
-   VerticalBar Chart - one more example, showing positive/negative stacks: (See section )
    -   User-Provided Data (Y values), User-Provided X Labels, User-Provided Colors, User-Provided Data Rows Legends, User-Provided Y Labels (See section )
-   Bugs status (See section )
-   Future enhancements and work (See section )
-   Terminology and Selected Classes (See section )
-   Internal notes (See section )
    -   Add ability to create a Table of Contents to README.org (See section )
    -   Adding images to README.org (See section )
    -   Pub - Publishing workflow on <https://pub.dartlang.org> (See section )

# Flutter Charts - How to include the flutter\_charts library in your application<a id="sec-2" name="sec-2"></a>

Flutter Charts is a charting library for Flutter, written in Flutter. Currently, column chart and line chart are supported.

The package is published on pub for inclusion in your application's `pubspec.yaml`: The *Installing* tab on <https://pub.dartlang.org/packages/flutter_charts> contains instructions on how to include the *flutter\_charts* package in your application.

# An example of Flutter Chart output<a id="sec-3" name="sec-3"></a>

There is one example application in flutter\_charts: `example/lib/main.dart`. It shows how a Flutter Chart can be included in a Flutter application.

You can run the example application using one of the methods (6, 7) in the paragraph below.

This application is also used as a base to show several sample charts in the paragraphs below.

Vertical Bar Chart (Column Chart)

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_154245_27063qmN.png)

Point and Line Chart (Line Chart)

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_154329_270633wT.png)

Output uses semi-random data. You can click the blue + button to rerun chart with a different dataset.

# Known packages, libraries and apps that use this this flutter\_charts package<a id="sec-4" name="sec-4"></a>

1.  Michael R. Fairhurst's **Language reader app** - see <https://github.com/MichaelRFairhurst/flutter-language-reader-app>

# Flutter Charts - an overview: data, options, classes<a id="sec-5" name="sec-5"></a>

Before we show several examples of charts, a few notes. 

-   The `ChartData` class: allows to define data - X labels, Y values, (optional) Y labels, each-dataRow (series) legends, each-dataRow (series) color. The list below provides a summary description of each item
    -   X labels: `ChartData.xLabels` allow to define X labels. Setting `xLabels` is required, but client can set them to empty strings.
    -   Y values: `ChartData.dataRows` allow to define Y values in rows. Assumption: size of each data row in `ChartData.dataRows` is the same, and each data row size ==  `ChartData.xLabels.size`
    -   Y labels (optional): Normally, Y labels are generated from data. The option `ChartOptions.useUserProvidedYLabels` (default *true*), asks flutter\_charts to data-generate Y labels. If this option is set to *false*, then `ChartData.yLabels` must be set. Any number of such user-provided Y labels is allowed.
    -   Each-dataRow (each series) legends: `ChartData.dataRowsLegends` allow to define a legend for each data row in  `ChartData.dataRows`. Assumption:  `ChartData.dataRows.size` ==  `ChartData.dataRowsLegends.size`
    -   Each-dataRow (each series) color: `ChartData.dataRowsColors` allow to define a color for each data row in  `ChartData.dataRows`. Assumption:  `ChartData.dataRows.size` ==  `ChartData.dataRowsColors.size`
-   The  `ChartOptions` class: allows to define options, by using it's defaults, or setting some options to non default values. There are also `LineChartOptions` and `VerticalBarChartOptions` classes.
-   Support for randomly generated data, colors, labels: Flutter Charts also provides randomly generated data, in the class `RandomChartData`. This class generates:
    -   Y values data,
    -   X labels,
    -   Series colors,
    -   Series legends
-   Currently the only purpose of `RandomChartData` is for use in the examples below. To be clear, `RandomChartData` Y values, series colors, and series legends are not completely random - they hardcode some demoable label, legends, color values, and data ranges (data random within the range).

# Experimenting with Flutter Charts: Using the included example app `file:example/lib/main.dart`<a id="sec-6" name="sec-6"></a>

There are multiple ways to experiment with Flutter Charts from your computer. We describe running Flutter Charts in development mode on your device (Android, iOS - follow 1, 2 or 3, 4 and 6), or alternatively on a device emulator (device emulator running from an IDE such as IntelliJ with Android Studio installed - follow 1, 2 or 3, 5, 6 or 7).

1.  Install Flutter on your computer. See <https://flutter.io/> installation section.
2.  Clone flutter\_charts code from Github to your computer. Needs git client.
    
        cd DIRECTORY_OF_CHOICE
        git clone https://github.com/mzimmerm/flutter_charts.git
        # clone will create directory  flutter_charts
        cd flutter_charts

3.  (Alternative to 2.): Download and unzip flutter\_charts code from Github
    -   Browse to  <https://github.com/mzimmerm/flutter_charts.git>
    -   On the righ top, click on the "Clone or Download" button, then select save Zip, save and extract to  DIRECTORY\_OF\_CHOICE
    -   cd flutter\_charts
4.  Prepare a physical device (must be set to Development Mode) to run applications from your computer. Then connect a android device in development mode to your computer. See <https://www.kingoapp.com/root-tutorials/how-to-enable-usb-debugging-mode-on-android.htm>

5.  (Alternative to 4.): Prepare and start an Android device emulator on your computer.
    -   Install Android Studio: see <https://developer.android.com/studio/index.html>
    
    -   Install an IDE such as IntelliJ with Flutter plugin. See <https://flutter.io/intellij-setup/>

6.  Run Flutter Charts demo app from command line (this will work in both method 4. and method 5.)
    
        cd DIRECTORY_OF_CHOICE/flutter_charts 
        flutter run example/lib/main.dart

7.  (Alternative to 6.) Run  Flutter Charts demo app from IDE. This will work only with method 5. 
    -   Start IntelliJ IDE, create a project in the `DIRECTORY_OF_CHOICE/flutter_charts` start an Android emulator, then click on the Run button in Intellij (which should show the `file:example/lib/main.dart` in the run button).

# Flutter Charts - examples: LineChart and VerticalBarChart. Code and resulting charts<a id="sec-7" name="sec-7"></a>

Flutter Charts code allow to define the following data elements:

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="left" />

<col  class="left" />
</colgroup>
<tbody>
<tr>
<td class="left">*Data (Y values)*</td>
<td class="left">User-Provided or Random</td>
</tr>


<tr>
<td class="left">*X Labels*</td>
<td class="left">User-Provided or Random</td>
</tr>


<tr>
<td class="left">*Options including Colors*</td>
<td class="left">User-Provided or Random</td>
</tr>


<tr>
<td class="left">*Data Rows Legends*</td>
<td class="left">User-Provided or Random</td>
</tr>


<tr>
<td class="left">*Y Labels*</td>
<td class="left">User-Provided or Data-Generated</td>
</tr>
</tbody>
</table>

The examples below show a few alternative code snippets (User-Provided or Random data, labels, option) and the resulting charts.

The chart images were obtained by substituting the code snippet to the `file:example/lib/main.dart` code. 

## Random Data (Y values), Random X Labels, Random Colors, Random Data Rows Legends, Data-Generated Y Labels.<a id="sec-7-1" name="sec-7-1"></a>

This example shows that Data-Generated Y labels is the default.  
Flutter Charts support reasonably intelligently generated Y Labels from data, including dealing with negatives.

Code in `defineOptionsAndData()`:

    void defineOptionsAndData() {
      _lineChartOptions = new LineChartOptions();
      _verticalBarChartOptions = new VerticalBarChartOptions();
      _chartData = new RandomChartData(useUserProvidedYLabels: _lineChartOptions.useUserProvidedYLabels);
    }

Result line chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_172324_27063E7Z.png)

Result vertical bar chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_173422_27063ePm.png)

## User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, Data-Generated Y Labels,<a id="sec-7-2" name="sec-7-2"></a>

Code in `defineOptionsAndData()`:

    void defineOptionsAndData() {
      _lineChartOptions = new LineChartOptions();
      _verticalBarChartOptions = new VerticalBarChartOptions();
      _chartData = new ChartData();
      _chartData.dataRowsLegends = [
        "Spring",
        "Summer",
        "Fall",
        "Winter"];
      _chartData.dataRows = [
        [10.0, 20.0,  5.0,  30.0,  5.0,  20.0, ],
        [30.0, 60.0, 16.0, 100.0, 12.0, 120.0, ],
        [25.0, 40.0, 20.0,  80.0, 12.0,  90.0, ],
        [12.0, 30.0, 18.0,  40.0, 10.0,  30.0, ],
      ];
      _chartData.xLabels =  ["Wolf", "Deer", "Owl", "Mouse", "Hawk", "Vole"];
      _chartData.assignDataRowsDefaultColors();
      // Note: ChartOptions.useUserProvidedYLabels default is still used (false);
    }

Result line chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_180657_27063rZs.png)

Result vertical bar chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_180915_270634jy.png)

## User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, User-Provided Y Labels<a id="sec-7-3" name="sec-7-3"></a>

This example show how to use the option `useUserProvidedYLabels`, and scaling of data to the Y labels range.

Code in `defineOptionsAndData()`:

    void defineOptionsAndData() {
      // This example shows user defined Y Labels.
      //   When setting Y labels by user, the dataRows value scale
      //   is irrelevant. User can use for example interval <0, 1>,
      //   <0, 10>, or any other, even negative ranges. Here we use <0-10>.
      //   The only thing that matters is  the relative values in the data Rows.
    
      // Note that current implementation sets
      // the minimum of dataRows range (1.0 in this example)
      // on the level of the first Y Label ("Ok" in this example),
      // and the maximum  of dataRows range (10.0 in this example)
      // on the level of the last Y Label ("High" in this example).
      // This is not desirable, we need to add a userProvidedYLabelsBoundaryMin/Max.
      _lineChartOptions = new LineChartOptions();
      _verticalBarChartOptions = new VerticalBarChartOptions();
      _chartData = new ChartData();
      _chartData.dataRowsLegends = [
        "Java",
        "Dart",
        "Python",
        "Newspeak"];
      _chartData.dataRows = [
        [9.0, 4.0,  3.0,  9.0, ],
        [7.0, 6.0,  7.0,  6.0, ],
        [4.0, 9.0,  6.0,  8.0, ],
        [3.0, 9.0, 10.0,  1.0, ],
      ];
      _chartData.xLabels =  ["Fast", "Readable", "Novel", "Use"];
      _chartData.dataRowsColors = [
        Colors.blue,
        Colors.yellow,
        Colors.green,
        Colors.amber,
      ];
      _lineChartOptions.useUserProvidedYLabels = true; // use the labels below on Y axis
      _chartData.yLabels = [
        "Ok",
        "Higher",
        "High",
      ];
    }

Result line chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_191037_27063qtB.png)
(Disclaimer: Not actually measured)

Result vertical bar chart: Here the Y values should be numeric (if any) as manual labeling "Ok", "Higher", High" does not make sense for stacked type charts.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_191138_2706333H.png)
(Disclaimer: Not actually measured)

# VerticalBar Chart - one more example, showing positive/negative stacks:<a id="sec-8" name="sec-8"></a>

## User-Provided Data (Y values), User-Provided X Labels, User-Provided Colors, User-Provided Data Rows Legends, User-Provided Y Labels<a id="sec-8-1" name="sec-8-1"></a>

This example has again user defined Y Labels, with a bar chart, using the smart auto-layout of user defined Y Labels. The chart shows negative and positive values similar to %down/%up stock charts.

Code in `defineOptionsAndData()`:

    void defineOptionsAndData() {
      // This example shows user defined Y Labels with
      // a bar chart, showing negative and positive values
      // similar to %down/%up stock charts.
      _lineChartOptions = new LineChartOptions();
      _verticalBarChartOptions = new VerticalBarChartOptions();
      _chartData = new ChartData();
      _chartData.dataRowsLegends = [
        "-2%_0%",
        "<-2%",
        "0%_+2%",
        ">+2%"];
      // each column absolute values should add to same number todo - 100 would make more sense, to represent 100% of stocks in each category
      _chartData.dataRows = [
        [-9.0, -8.0,  -8.0,  -5.0, -8.0, ],
        [-1.0, -2.0,  -4.0,  -1.0, -1.0, ],
        [7.0, 8.0,  7.0, 11.0, 9.0, ],
        [3.0, 2.0, 1.0,  3.0,  3.0, ],
      ];
      _chartData.xLabels =  ["Energy", "Health", "Finance", "Chips", "Oil"];
      _chartData.dataRowsColors = [
        Colors.grey,
        Colors.red,
        Colors.greenAccent,
        Colors.black,
      ];
      _lineChartOptions.useUserProvidedYLabels = false; // use labels below
      //_chartData.yLabels = [
      //  "Ok",
      //  "Higher",
      //  "High",
      //];
    }

Result vertical bar chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_195745_27063ECO.png)

(there is a bug here,see Known Bugs)

# Bugs status<a id="sec-9" name="sec-9"></a>

-   [ ] Chart area needs clipping in the application
-   [ ] Take a look at the stock charts example. There is a bug reverting series on the negative values - both negative dataRows, and dataRowsColors must be reverted for the chart stacks to show in intended order (black, green grey red from top). But even then,  dataRowsLegends are incorrect.
-   [X] <https://github.com/mzimmerm/flutter_charts/issues/5> - Coloring support: Make line chart dot colors settable
-   [ ] 

# Future enhancements and work<a id="sec-10" name="sec-10"></a>

Bug fixes:

-   Clip chart to not paint outside area provided by Flutter app.
-   Clip labels and legends not to run into the neighbor, if too long.

On the boundary of bug and enhancement:

-   For ChartOptions.useUserProvidedYLabels = true. See example with User defined YLabels: Current implementation sets the minimum of dataRows range (1.0 in the example) on the level of the first Y Label ("Ok" in this example), and the maximum  of dataRows range (10.0 in this example) on the level of the last Y Label ("High" in this example). This is not desirable, we need to add a userProvidedYLabelsBoundaryMin/Max.

Enhancements:

-   Create document / image showing layout and spacing - show option variables on image
-   Simple:
    -   Add options to hide the grid (keep axes)
    -   Add options to hide  axes (if axes not shown, labels should not show?)
    -   Decrease option for default spacing around the Y axis.
-   First, probably need to provide tooltips
-   Next, a few more chart types: Spline line chart (stacked line chart), Grouped VerticalBar chart,
-   Next, re-implement the layout more generically and clearly. Space saving changes such as *tilting* labels.
-   Next, add ability to invert X and Y axis (values on horizontal axis)

# TODO Terminology and Selected Classes<a id="sec-11" name="sec-11"></a>

-   **(Presenter)Leaf      :** The finest visual element presented in each  "column of view" in chart - that is, all widgets representing series of data displayed above each X label. For example, for Line chart, the leaf would be one line and dot representing one Y value at one X label. For the bar chart, the leaf would be one bar representing one (stacked) Y value at one X label.
    -   Classes: Presenter, LineAndHotspotPresenter, VerticalBarPresenter, PresenterCreator
-   **Painter              :** Class which paints to chart to canvas. Terminology and class structure taken from Flutter's Painter and Painting classes.
    -   Classes: todo

# Internal notes<a id="sec-12" name="sec-12"></a>

## DONE Add ability to create a Table of Contents to README.org<a id="sec-12-1" name="sec-12-1"></a>

-   [X] Install toc-org package
-   [X] Add to init.el
    
        (if (require 'toc-org nil t)
          (add-hook 'org-mode-hook 'toc-org-enable)
        (warn "toc-org not found"))
-   [X] Every time README.org is saved, first heading with a :TOC: tag will be updated with the current table of contents.
-   [X] So nothing special need be done after the above is configured.

## Adding images to README.org<a id="sec-12-2" name="sec-12-2"></a>

-   [ ] <https://pub.dartlang.org> does not allow storing images.
-   [ ] Add / move new images to `flutter_charts/doc/readme_images`
-   [ ] org file, change image links to look like ![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_154245_27063qmN.png)~

## Pub - Publishing workflow on <https://pub.dartlang.org><a id="sec-12-3" name="sec-12-3"></a>

### Notes:<a id="sec-12-3-1" name="sec-12-3-1"></a>

1.  Pub requires the following file in project to show the correct tabs on pub

    1.  Tab README.md    - Needs the file
    
    2.  Tab CHANGELOG.md - Needs the file
    
    3.  Tab Example      - this tab appears if the project file `file:flutter_charts/example/lib/main.dart` exists
    
    4.  Tab Installing   - shows automatically

### IF **README.md** needs change<a id="sec-12-3-2" name="sec-12-3-2"></a>

1.  **README.org**: make sure image links point to `flutter_charts/doc/readme_images`

2.  **README.org**: Conversion steps to **README.md**

    To convert **README.org** to **README.md**, we need to do a few extra steps for README.md image links to be readable on <https://pub.dartlang.org>.
    
    1.  Note: Org file which has :TOC: in heading, generates TOC on every save.
    2.  **README.org**: Export org to md: `C-c C-e m m` in the org file to create the generated md file
    3.  **README.md**: Delete generated TOC
    4.  **README.md**: Generate md-native TOC:
        -   Cursor on top
        -   `M-x: markdown-toc/generate-toc`
    5.  **README.md**: Fix image links in the README.md - links must look like this:
        
            -![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_180657_27063rZs.png)
            +![img](https://github.com/mzimmerm/flutter_charts/raw/master/https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_180657_27063rZs.png)
    6.  **README.md**: This is achieved with: `replace-string https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ https://github.com/mzimmerm/flutter_charts/raw/master/https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/`

### **pubspec.yaml** - Increase version number<a id="sec-12-3-3" name="sec-12-3-3"></a>

### `cd flutter_charts; flutter packages pub upgrade`<a id="sec-12-3-4" name="sec-12-3-4"></a>

### `cd flutter_charts; flutter packages pub get`<a id="sec-12-3-5" name="sec-12-3-5"></a>

### Test included app from IntelliJ<a id="sec-12-3-6" name="sec-12-3-6"></a>

### `git push`<a id="sec-12-3-7" name="sec-12-3-7"></a>

### **README.md** on <https://github.com/mzimmerm/flutter_charts> - check if looks ok<a id="sec-12-3-8" name="sec-12-3-8"></a>

### `flutter packages pub publish --dry-run`<a id="sec-12-3-9" name="sec-12-3-9"></a>

### `flutter packages pub publish`<a id="sec-12-3-10" name="sec-12-3-10"></a>

### Check <https://pub.dartlang.org/packages/flutter_charts><a id="sec-12-3-11" name="sec-12-3-11"></a>

### Test the package that was just published<a id="sec-12-3-12" name="sec-12-3-12"></a>

1.  `cd flutter_charts_sample_app; flutter packages pub upgrade; flutter packages pub get; flutter run`
