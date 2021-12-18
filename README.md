<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [New in the current release](#new-in-the-current-release)
    - [Illustration of this new feature, ability to hide labels, legend, or gridlines](#illustration-of-this-new-feature-ability-to-hide-labels-legend-or-gridlines)
- [Installing flutter\_charts as a library into your app](#installing-flutter_charts-as-a-library-into-your-app)
- [Installing the flutter\_charts project locally from Github, and running the example app](#installing-the-flutter_charts-project-locally-from-github-and-running-the-example-app)
    - [Installing the flutter\_charts project locally from Github](#installing-the-flutter_charts-project-locally-from-github)
    - [Running the example app](#running-the-example-app)
- [Examples with code: LineChart and VerticalBarChart. Code and resulting charts](#examples-with-code-linechart-and-verticalbarchart-code-and-resulting-charts)
    - [Example with Random Data (Y values), Random X Labels, Random Colors, Random Data Rows Legends, Data-Generated Y Labels.](#example-with-random-data-y-values-random-x-labels-random-colors-random-data-rows-legends-data-generated-y-labels)
    - [User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, Data-Generated Y Labels,](#user-provided-data-y-values-user-provided-x-labels-random-colors-user-provided-data-rows-legends-data-generated-y-labels)
    - [User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, User-Provided Y Labels](#user-provided-data-y-values-user-provided-x-labels-random-colors-user-provided-data-rows-legends-user-provided-y-labels)
    - [VerticalBar Chart - one more example, showing positive/negative stacks:](#verticalbar-chart---one-more-example-showing-positivenegative-stacks)
        - [User-Provided Data (Y values), User-Provided X Labels, User-Provided Colors, User-Provided Data Rows Legends, User-Provided Y Labels](#user-provided-data-y-values-user-provided-x-labels-user-provided-colors-user-provided-data-rows-legends-user-provided-y-labels)
- [Illustration of the "iterative auto layout" feature](#illustration-of-the-iterative-auto-layout-feature)
    - [Autolayout step 1](#autolayout-step-1)
    - [Autolayout step 2](#autolayout-step-2)
    - [Autolayout step 3](#autolayout-step-3)
    - [Autolayout step 4](#autolayout-step-4)
    - [Autolayout step 5](#autolayout-step-5)
- [Known packages, libraries and apps that use this flutter\_charts package](#known-packages-libraries-and-apps-that-use-this-flutter_charts-package)
- [An overview of this library: data, options, classes](#an-overview-of-this-library-data-options-classes)

<!-- markdown-toc end -->



<a id="org46498e5"></a>

# New in the current release

Current release is 0.3.0

See <CHANGELOG.md> for the list of new features and bug fixes in this release.

In particular, the optional ability to hide labels (on x axis, y axis), hide the legend, and hide the gridline has been added. This feature is controlled by `ChartOptions`. See the code in \`example1/lib/main.dart\`. This is an out of context example of how to create the options that ignore all labels, legend, and gridline. Ignoring only one, or any combination will also work

    ChartOptions chartOptions = VerticalBarChartOptions.noLabels();

or to set individual values to false. Default is true so no need to set those that we want to show.

    ChartOptions chartOptions =
          VerticalBarChartOptions(
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


<a id="org95dc140"></a>

## Illustration of this new feature, ability to hide labels, legend, or gridlines

Code is for the line chart. See the function `Widget createRequestedChart()` in <https://github.com/mzimmerm/flutter_charts/blob/master/example1/lib/main.dart> for changes to create a vertical bar chart instead (essentially in this code substitute "Line" for "VerticalBar". For the configuration, the section of interest is around `ExamplesEnum.ex31AnimalsBySeasonNoLabelsShown`

    // This is how noLabels can be set. See the previous section for a fine control of this option
    ChartOptions  chartOptions = LineChartOptions.noLabels(); 
    ChartData  chartData = ChartData();
    chartData.dataRowsLegends = [
      'Spring',
      'Summer',
      'Fall',
      'Winter',
    ];
    chartData.dataRows = [
      [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
      [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
      [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
      [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
    ];
    chartData.xLabels = ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'];
    chartData.assignDataRowsDefaultColors();
    
    // This section is shown repeatedly in all examples, to stress how charts are created
    LineChartTopContainer lineChartContainer = LineChartTopContainer(
      chartData: chartData,
      chartOptions: chartOptions,
      xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
    );
    
    LineChart lineChart = LineChart(
      painter: LineChartPainter(
        lineChartContainer: lineChartContainer,
      ),
    );

The `lineChart` widget can be placed on any Flutter app. The example code is in <https://github.com/mzimmerm/flutter_charts/blob/master/example1/lib/main.dart>

Result line chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex31AnimalsBySeasonNoLabelsShown_lineChart.png "Line Chart caption")

Result vertical bar chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex31AnimalsBySeasonNoLabelsShown_verticalBarChart.png "Vertical Bar Chart caption")


<a id="orga899724"></a>

# Installing flutter\_charts as a library into your app

If you want to use flutter\_charts in your app, please follow <https://pub.dev/packages/flutter_charts/install>.


<a id="org3b85e50"></a>

# Installing the flutter\_charts project locally from Github, and running the example app

The advantage of installing the full flutter\_charts project locally from Github is that you can run the packaged example application and also run the integration and widget tests.


<a id="org5515cf5"></a>

## Installing the flutter\_charts project locally from Github

To install flutter\_charts project locally from Github, follow these steps:

-   Install Flutter, and items such as Android emulator. Instructions are on the Flutter website <https://docs.flutter.dev/get-started/install>.
-   Go to <https://github.com/mzimmerm/flutter_charts>, click on the "Code" button, and follow the instuctions to checkout flutter\_charts. A summary of one installation method (download method):
-   Click the "Download zip" link <https://github.com/mzimmerm/flutter_charts/archive/refs/heads/master.zip>
-   When prompted, save the file `flutter_charts-master.zip` one level above where you want the project. We will use `$HOME/dev`
-   Unzip the file `flutter_charts-master.zip`
-   The project will be in the `$HOME/dev/flutter_charts-master/` directory


<a id="orge4894a8"></a>

## Running the example app

There is an example application in flutter\_charts: `example1/lib/main.dart`. It shows how the Flutter Charts library can be included in a Flutter application.

To run the example application, Android emulator or iOS emulator need to be installed. See the installation link above. To use the project, you can use an IDE or command line. Instructions here are for the command line. Start in the unzipped directory, and follow items below:

-   Important: Make sure an Android or iOS emulator is running, or you have a physical device connected. See the [3.1](#org5515cf5) section.
-   `cd $HOME/dev/flutter_charts-master/` This is where
-   Paste any of the lines below to the command line. Each line runs the example app with a different chart example.
    
        flutter run --dart-define=EXAMPLE_TO_RUN=ex10RandomData --dart-define=CHART_TYPE_TO_SHOW=lineChart example1/lib/main.dart
        flutter run --dart-define=EXAMPLE_TO_RUN=ex10RandomData --dart-define=CHART_TYPE_TO_SHOW=verticalBarChart example1/lib/main.dart
        flutter run --dart-define=EXAMPLE_TO_RUN=ex20RandomDataWithLabelLayoutStrategy --dart-define=CHART_TYPE_TO_SHOW=lineChart example1/lib/main.dart
        flutter run --dart-define=EXAMPLE_TO_RUN=ex20RandomDataWithLabelLayoutStrategy --dart-define=CHART_TYPE_TO_SHOW=verticalBarChart example1/lib/main.dart
        flutter run --dart-define=EXAMPLE_TO_RUN=ex30AnimalsBySeasonWithLabelLayoutStrategy --dart-define=CHART_TYPE_TO_SHOW=lineChart example1/lib/main.dart
        flutter run --dart-define=EXAMPLE_TO_RUN=ex30AnimalsBySeasonWithLabelLayoutStrategy --dart-define=CHART_TYPE_TO_SHOW=verticalBarChart example1/lib/main.dart
        flutter run --dart-define=EXAMPLE_TO_RUN=ex31AnimalsBySeasonNoLabelsShown --dart-define=CHART_TYPE_TO_SHOW=lineChart example1/lib/main.dart
        flutter run --dart-define=EXAMPLE_TO_RUN=ex31AnimalsBySeasonNoLabelsShown --dart-define=CHART_TYPE_TO_SHOW=verticalBarChart example1/lib/main.dart
        flutter run --dart-define=EXAMPLE_TO_RUN=ex40LanguagesWithYOrdinalUserLabelsAndUserColors --dart-define=CHART_TYPE_TO_SHOW=lineChart example1/lib/main.dart
        flutter run --dart-define=EXAMPLE_TO_RUN=ex50StocksWithNegativesWithUserColors --dart-define=CHART_TYPE_TO_SHOW=verticalBarChart example1/lib/main.dart

Screenshot from the running example app

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_lineChart.png "Line Chart caption")

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_verticalBarChart.png "Vertical Bar Chart caption")


<a id="org1751476"></a>

# Examples with code: LineChart and VerticalBarChart. Code and resulting charts

Flutter Charts code allow to define the following data elements:

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<tbody>
<tr>
<td class="org-left"><i>Data (Y values)</i></td>
<td class="org-left">User-Provided or Random</td>
</tr>


<tr>
<td class="org-left"><i>X Labels</i></td>
<td class="org-left">User-Provided or Random</td>
</tr>


<tr>
<td class="org-left"><i>Options including Colors</i></td>
<td class="org-left">User-Provided or Random</td>
</tr>


<tr>
<td class="org-left"><i>Data Rows Legends</i></td>
<td class="org-left">User-Provided or Random</td>
</tr>


<tr>
<td class="org-left"><i>Y Labels</i></td>
<td class="org-left">User-Provided or Data-Generated</td>
</tr>
</tbody>
</table>

The examples below show a few alternative code snippets (User-Provided or Random data, labels, option) and the resulting charts.

See the section [3.2](#orge4894a8) on how to run the code that created the images below.  The code snippets are from the method `Widget createRequestedChart()` in `example1/lib/main.dart` 


<a id="orgc5496bb"></a>

## Example with Random Data (Y values), Random X Labels, Random Colors, Random Data Rows Legends, Data-Generated Y Labels.

This example shows that Data-Generated Y labels are default. Flutter Charts support reasonably intelligently generated Y Labels from data, including dealing with negatives.

Code is for line chart. See the function `Widget createRequestedChart()` in <https://github.com/mzimmerm/flutter_charts/blob/master/example1/lib/main.dart> for changes to create a vertical bar chart instead (essentially in this code substitute "Line" for "VerticalBar".

    ChartOptions chartOptions = LineChartOptions();  
    ChartData chartData = RandomChartData();
    
    // This section is shown repeatedly in all examples, to stress how charts are created
    LineChartTopContainer lineChartContainer = LineChartTopContainer(
      chartData: chartData,
      chartOptions: chartOptions,
      xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
    );
    
    LineChart lineChart = LineChart(
      painter: LineChartPainter(
        lineChartContainer: lineChartContainer,
      ),
    );

The `lineChart` widget can be placed on any Flutter app. The example code is in <https://github.com/mzimmerm/flutter_charts/blob/master/example1/lib/main.dart>

Result line chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_lineChart.png "Line Chart caption")

Result vertical bar chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_verticalBarChart.png "Vertical Bar Chart caption")


<a id="orgf13fc06"></a>

## User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, Data-Generated Y Labels,

Code is for line chart. See the function `Widget createRequestedChart()` in <https://github.com/mzimmerm/flutter_charts/blob/master/example1/lib/main.dart> for changes to create a vertical bar chart instead (essentially in this code substitute "Line" for "VerticalBar". Section `ExamplesEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy_lineChart.png`

    ChartOptions chartOptions = LineChartOptions();  
    LabelLayoutStrategy xContainerLabelLayoutStrategy = DefaultIterativeLabelLayoutStrategy(
      options: chartOptions,
    );
    ChartData  chartData = ChartData();
    chartData.dataRowsLegends = [
      'Spring',
      'Summer',
      'Fall',
      'Winter',
    ];
    chartData.dataRows = [
      [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
      [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
      [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
      [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
    ];
    chartData.xLabels = ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'];
    chartData.assignDataRowsDefaultColors();
    
    // This section is shown repeatedly in all examples, to stress how charts are created
    LineChartTopContainer lineChartContainer = LineChartTopContainer(
      chartData: chartData,
      chartOptions: chartOptions,
      xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
    );
    
    LineChart lineChart = LineChart(
      painter: LineChartPainter(
        lineChartContainer: lineChartContainer,
      ),
    );

The `lineChart` widget can be placed on any Flutter app. The example code is in <https://github.com/mzimmerm/flutter_charts/blob/master/example1/lib/main.dart>

Result line chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex30AnimalsBySeasonWithLabelLayoutStrategy_lineChart.png "Line Chart caption")

Result vertical bar chart:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex30AnimalsBySeasonWithLabelLayoutStrategy_verticalBarChart.png "Vertical Bar Chart caption")


<a id="org2a4251f"></a>

## User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, User-Provided Y Labels

This example show how to use the option `useUserProvidedYLabels`, and scaling of data to the Y labels range.

For code, please refer to the function `Widget createRequestedChart()` in <https://github.com/mzimmerm/flutter_charts/blob/master/example1/lib/main.dart>, section `ExamplesEnum.ex40LanguagesWithYOrdinalUserLabelsAndUserColors`

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex40LanguagesWithYOrdinalUserLabelsAndUserColors_lineChart.png "Line Chart caption")


<a id="orgf786817"></a>

## VerticalBar Chart - one more example, showing positive/negative stacks:


<a id="org8c2555f"></a>

### User-Provided Data (Y values), User-Provided X Labels, User-Provided Colors, User-Provided Data Rows Legends, User-Provided Y Labels

This example has again user defined Y Labels, with a bar chart, using the smart auto-layout of user defined Y Labels. The chart shows negative and positive values similar to %down/%up stock charts.

For code, please refer to the function `Widget createRequestedChart()` in <https://github.com/mzimmerm/flutter_charts/blob/master/example1/lib/main.dart>, section `ExamplesEnum.ex50StocksWithNegativesWithUserColors`

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex50StocksWithNegativesWithUserColors_verticalBarChart.png "Line Chart caption")

(there is a bug here,see Known Bugs)


<a id="org8ed4fcc"></a>

# Illustration of the "iterative auto layout" feature

This section illustrates how the auto layout behaves when less and less horizontal space is available to display the chart. 

Flutter chart library automatically checks for the X label overlap, and follows with rule-based iterative re-layout, to prevent labels running into each other.

To illustrate "stressed" horizontal space for the chart, we are gradually adding a text widget containing and increasing number of '<' signs on the right of the chart.


<a id="org6e4cf81"></a>

## Autolayout step 1

Let's say there are six labels on a chart, and sufficient space to display labels horizontally. The result may look like this:

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-1.png)

We can see all x axis labels displayed it full, horizontally oriented.


<a id="org69d46b5"></a>

## Autolayout step 2

Next, let us make less available space by taking away some space on the right with a wider text label like this '<<<<<<'

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-2.png)

We can see the labels were automatically tilted by angle `ChartOptions labelTiltRadians` for the labels to fit.


<a id="org1fe4b8e"></a>

## Autolayout step 3

Next, let us make even less available space by taking away some space on the right with a wider text label like this '<<<<<<<<<<<'.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-3.png)

We can see that labels are not only tilted, but also automatically skipped (every 2nd) for labels not to overlap.


<a id="orgde5c56b"></a>

## Autolayout step 4

Next, let us make even less available space some more compared to step 3, with even a wider text label like this '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-4.png)

We can see even more labels were skipped for labels to prevent overlap, the chart is showing evey 5th label


<a id="org0ec6f24"></a>

## Autolayout step 5

Last, let us take away extreme amount of horizontal space by using '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<',

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-5.png)

Here we can see the "default auto layout" finally gave up, and overlaps labels. Also, the legend is now hidded, as there is not enough horizontal space.


<a id="org585d96c"></a>

# Known packages, libraries and apps that use this flutter\_charts package

1.  Michael R. Fairhurst's **Language reader app** - see <https://github.com/MichaelRFairhurst/flutter-language-reader-app>


<a id="orge3a17cf"></a>

# An overview of this library: data, options, classes

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

