# Table of Contents

1.  [Flutter Charts - introduction](#org3bcbfc4)
2.  [Flutter Charts - data, options, classes](#org679085d)
3.  [Experimenting with Flutter Charts: Using the included sample app flutter\_charts\_sample\_app.dart](#org9974114)
    1.  [Sample Flutter Charts application output](#org5bcbf40)
4.  [Flutter Charts: LineChart and VerticalBarChart samples: Code and resulting charts](#org81ced17)
    1.  [Random Data (Y values), Random X Labels, Random Colors, Random Data Rows Legends, Data-Generated Y Labels.](#org804fb2a)
    2.  [User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, Data-Generated Y Labels,](#org2291aa2)
    3.  [User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, User-Provided Y Labels](#orga026989)
5.  [VerticalBar Chart - one more example, showing positive/negative stacks:](#org70c7a62)
    1.  [User-Provided Data (Y values), User-Provided X Labels, User-Provided Colors, User-Provided Data Rows Legends, User-Provided Y Labels](#org528a6a0)
6.  [Known bugs](#org46114f9)
7.  [Future enhancements and work](#orgfe47381)
8.  [Terminology and Selected Classes](#org5f82399)



<a id="org3bcbfc4"></a>

# Flutter Charts - introduction

Flutter Charts is a charting library for Flutter, written in Flutter. Currently, column chart and line chart are supported.

You may want to study the included sample app `flutter_charts_sample_app.dart` to build your application using Flutter Charts. The sample app shows how a Flutter Chart can be included in a Flutter application.


<a id="org679085d"></a>

# Flutter Charts - data, options, classes

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


<a id="org9974114"></a>

# Experimenting with Flutter Charts: Using the included sample app flutter\_charts\_sample\_app.dart

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
        flutter run example/chart/flutter_charts_sample_app.dart

7.  (Alternative to 6.) Run  Flutter Charts demo app from IDE. This will work only with method 5. 
    -   Start IntelliJ IDE, create a project in the `DIRECTORY_OF_CHOICE/flutter_charts` start an Android emulator, then click on the Run button in Intellij (which should see the flutter\_charts\_sample\_app)


<a id="org5bcbf40"></a>

## Sample Flutter Charts application output

As described above, there is one sample application in flutter\_charts: example/chart/chart\_usage\_example.dart. You can run the application using one of the methods (6, 7) above.

This application is also used as a base to show several possible sample charts in the paragraphs below. Two samples:

Vertical Bar Chart (Column Chart)

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_154245_27063qmN.png)

Point and Line Chart (Line Chart)

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_20171102_154329_270633wT.png)

Output uses semi-random data. Click the blue + button to rerun chart with a different dataset.


<a id="org81ced17"></a>

# Flutter Charts: LineChart and VerticalBarChart samples: Code and resulting charts

Flutter Charts code allow to define the following data elements:

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<tbody>
<tr>
<td class="org-left">*Data (Y values)*</td>
<td class="org-left">User-Provided or Random</td>
</tr>


<tr>
<td class="org-left">*X Labels*</td>
<td class="org-left">User-Provided or Random</td>
</tr>


<tr>
<td class="org-left">*Options including Colors*</td>
<td class="org-left">User-Provided or Random</td>
</tr>


<tr>
<td class="org-left">*Data Rows Legends*</td>
<td class="org-left">User-Provided or Random</td>
</tr>


<tr>
<td class="org-left">*Y Labels*</td>
<td class="org-left">User-Provided or Data-Generated</td>
</tr>
</tbody>
</table>

The samples below show a few alternative code snippets (User-Provided or Random data, labels, option) and the resulting charts.

The chart images were obtained by substituting the code snippet to the `example/chart/flutter_charts_sample_app.dart` code. 


<a id="org804fb2a"></a>

## Random Data (Y values), Random X Labels, Random Colors, Random Data Rows Legends, Data-Generated Y Labels.

This example shows that Data-Generated Y labels is the default.  
Flutter Charts support reasonably intelligently generated Y Labels from data, including dealing with negatives.

The example charts in this section are equivalent to those shown in "Sample Flutter Charts Application Output".

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


<a id="org2291aa2"></a>

## User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, Data-Generated Y Labels,

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


<a id="orga026989"></a>

## User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, User-Provided Y Labels

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


<a id="org70c7a62"></a>

# VerticalBar Chart - one more example, showing positive/negative stacks:


<a id="org528a6a0"></a>

## User-Provided Data (Y values), User-Provided X Labels, User-Provided Colors, User-Provided Data Rows Legends, User-Provided Y Labels

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


<a id="org46114f9"></a>

# Known bugs

-   Chart area needs clipping in the application
-   Take a look at the stock charts example. There is a bug reverting series on the negative values - both negative dataRows, and dataRowsColors must be reverted for the chart stacks to show in intended order (black, green grey red from top). But even then,  dataRowsLegends are incorrect.


<a id="orgfe47381"></a>

# Future enhancements and work

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


<a id="org5f82399"></a>

# TODO Terminology and Selected Classes

-   **(Presenter)Leaf      :** The finest visual element presented in each  "column of view" in chart - that is, all widgets representing series of data displayed above each X label. For example, for Line chart, the leaf would be one line and dot representing one Y value at one X label. For the bar chart, the leaf would be one bar representing one (stacked) Y value at one X label.
    -   Classes: Presenter, LineAndHotspotPresenter, VerticalBarPresenter, PresenterCreator
-   **Painter              :** Class which paints to chart to canvas. Terminology and class structure taken from Flutter's Painter and Painting classes.
    -   Classes: todo

