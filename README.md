
# Table of Contents

1.  [Examples with code](#org70673f2)
    1.  [ex10RandomData\_lineChart ](#org3eb3441)
    2.  [ex10RandomData\_barChart ](#orgbe8fa25)
    3.  [ex30AnimalsBySeasonWithLabelLayoutStrategy\_lineChart ](#orgda02a3d)
    4.  [ex30AnimalsBySeasonWithLabelLayoutStrategy\_barChart ](#org78a229d)
    5.  [ex31SomeNegativeValues\_lineChart ](#orgbf36cdb)
    6.  [ex31SomeNegativeValues\_barChart ](#org3432df0)
    7.  [ex32AllPositiveYsYAxisStartsAbove0\_lineChart ](#org763be56)
    8.  [ex32AllPositiveYsYAxisStartsAbove0\_barChart ](#orgfe5d568)
    9.  [ex33AllNegativeYsYAxisEndsBelow0\_lineChart ](#org86b4136)
    10. [ex34OptionsDefiningUserTextStyleOnLabels\_lineChart ](#org260cba6)
    11. [ex35AnimalsBySeasonNoLabelsShown\_lineChart ](#org3d3c134)
    12. [ex35AnimalsBySeasonNoLabelsShown\_barChart ](#org7a1ade3)
    13. [ex40LanguagesWithYOrdinalUserLabelsAndUserColors\_lineChart ](#orgc6be307)
    14. [ex50StocksWithNegativesWithUserColors\_barChart ](#org91f6516)
    15. [ex52AnimalsBySeasonLogarithmicScale\_lineChart ](#org77e5f4f)
    16. [ex52AnimalsBySeasonLogarithmicScale\_barChart ](#org042b202)
    17. [ex60LabelsIteration1\_barChart ](#orgada2279)
    18. [ex60LabelsIteration2\_barChart ](#orgd3771d7)
    19. [ex60LabelsIteration3\_barChart ](#org547dcea)
    20. [ex60LabelsIteration4\_barChart ](#org95e404c)
    21. [ex900ErrorFixUserDataAllZero\_lineChart ](#orgc87cb9f)
2.  [Latest release changes](#orgeaf773f)
3.  [Installation](#org03b46dd)
    1.  [Installing flutter\_charts as a library package into your app](#org30b6b7c)
    2.  [Installing the flutter\_charts project as a local clone from Github](#org03fe7ad)
4.  [Running the examples included in flutter\_charts](#org0430cd4)
5.  [Illustration of the "iterative auto layout" feature](#org84b6d75)
    1.  [Autolayout step 1](#org13982d7)
    2.  [Autolayout step 2](#orgc1d8a8f)
    3.  [Autolayout step 3](#org030cb34)
    4.  [Autolayout step 4](#orga7d9ad4)
    5.  [Autolayout step 5](#org435b9c8)
6.  [Known packages, libraries and apps that use this flutter\_charts package](#org269d91a)
7.  [Todos](#org44f7bdf)
8.  [Internal notes for exporting this document](#org91e5332)



<a id="org70673f2"></a>

# Examples with code

This section contains sample charts from flutter\_charts, with code that generated the charts. The code for each chart is in a method

    Widget chartToRun() {
     // .. code which generates the sample chart
    }

To quickly test the code, you can paste the method `chartToRun()` into the sample main app provided in <https://github.com/mzimmerm/flutter_charts/blob/master/example/lib/main_run_doc_example.dart>.

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<tbody>
<tr>
<td class="org-left"><a href="#org2ed092d"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org20acd52"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_barChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orga260a0c"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex30AnimalsBySeasonWithLabelLayoutStrategy_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org79c67fb"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex30AnimalsBySeasonWithLabelLayoutStrategy_barChart_w150.png" alt="nil"/></a></td>
</tr>


<tr>
<td class="org-left"><a href="#org3060b69"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex31SomeNegativeValues_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgb5f44f1"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex31SomeNegativeValues_barChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgbd56dc9"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex32AllPositiveYsYAxisStartsAbove0_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orge19a63d"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex32AllPositiveYsYAxisStartsAbove0_barChart_w150.png" alt="nil"/></a></td>
</tr>


<tr>
<td class="org-left"><a href="#orgd322ff6"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex33AllNegativeYsYAxisEndsBelow0_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgcdf5631"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex34OptionsDefiningUserTextStyleOnLabels_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgd400995"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex35AnimalsBySeasonNoLabelsShown_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org9227186"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex35AnimalsBySeasonNoLabelsShown_barChart_w150.png" alt="nil"/></a></td>
</tr>


<tr>
<td class="org-left"><a href="#orgd962a15"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex40LanguagesWithYOrdinalUserLabelsAndUserColors_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org6246d9c"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex50StocksWithNegativesWithUserColors_barChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org673ceb3"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex52AnimalsBySeasonLogarithmicScale_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org807928e"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex52AnimalsBySeasonLogarithmicScale_barChart_w150.png" alt="nil"/></a></td>
</tr>


<tr>
<td class="org-left"><a href="#orgbdb2c57"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex60LabelsIteration1_barChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgfe51f7b"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex60LabelsIteration2_barChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orga666d35"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex60LabelsIteration3_barChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org8f86d1f"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex60LabelsIteration4_barChart_w150.png" alt="nil"/></a></td>
</tr>


<tr>
<td class="org-left"><a href="#org429502d"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex900ErrorFixUserDataAllZero_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>
</tbody>
</table>


<a id="org3eb3441"></a>

## ex10RandomData\_lineChart <a id="org2ed092d"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example shows a demo-type data generated randomly in a range.
      chartData = RandomChartData.generated(chartOptions: chartOptions);
      var lineChartContainer = LineChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var lineChart = LineChart(
        painter: LineChartPainter(
          lineChartContainer: lineChartContainer,
        ),
      );
      return lineChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_lineChart.png "Line Chart caption")


<a id="orgbe8fa25"></a>

## ex10RandomData\_barChart <a id="org20acd52"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example shows a demo-type data generated randomly in a range.
      chartData = RandomChartData.generated(chartOptions: chartOptions);
      var barChartContainer = BarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var barChart = BarChart(
        painter: BarChartPainter(
          barChartContainer: barChartContainer,
        ),
      );
      return barChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_barChart.png "Line Chart caption")


<a id="orgda02a3d"></a>

## ex30AnimalsBySeasonWithLabelLayoutStrategy\_lineChart <a id="orga260a0c"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example shows an explicit use of the DefaultIterativeLabelLayoutStrategy.
      // The xContainerLabelLayoutStrategy, if set to null or not set at all,
      //   defaults to DefaultIterativeLabelLayoutStrategy
      // Clients can also create their own LayoutStrategy.
      xContainerLabelLayoutStrategy = DefaultIterativeLabelLayoutStrategy(
      options: chartOptions,
      );
      chartData = ChartData(
      dataRows: const [
      [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
      [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
      [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
      [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
      ],
      xUserLabels: const ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'],
      dataRowsLegends: const [
      'Spring',
      'Summer',
      'Fall',
      'Winter',
      ],
      chartOptions: chartOptions,
      );
      // chartData.dataRowsDefaultColors(); // if not set, called in constructor
      var lineChartContainer = LineChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var lineChart = LineChart(
        painter: LineChartPainter(
          lineChartContainer: lineChartContainer,
        ),
      );
      return lineChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex30AnimalsBySeasonWithLabelLayoutStrategy_lineChart.png "Line Chart caption")


<a id="org78a229d"></a>

## ex30AnimalsBySeasonWithLabelLayoutStrategy\_barChart <a id="org79c67fb"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example shows an explicit use of the DefaultIterativeLabelLayoutStrategy.
      // The xContainerLabelLayoutStrategy, if set to null or not set at all,
      //   defaults to DefaultIterativeLabelLayoutStrategy
      // Clients can also create their own LayoutStrategy.
      xContainerLabelLayoutStrategy = DefaultIterativeLabelLayoutStrategy(
      options: chartOptions,
      );
      chartData = ChartData(
      dataRows: const [
      [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
      [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
      [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
      [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
      ],
      xUserLabels: const ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'],
      dataRowsLegends: const [
      'Spring',
      'Summer',
      'Fall',
      'Winter',
      ],
      chartOptions: chartOptions,
      );
      // chartData.dataRowsDefaultColors(); // if not set, called in constructor
      var barChartContainer = BarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var barChart = BarChart(
        painter: BarChartPainter(
          barChartContainer: barChartContainer,
        ),
      );
      return barChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex30AnimalsBySeasonWithLabelLayoutStrategy_barChart.png "Line Chart caption")


<a id="orgbf36cdb"></a>

## ex31SomeNegativeValues\_lineChart <a id="org3060b69"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example shows a mix of positive and negative data values.
      chartData = ChartData(
      dataRows: const [
      [2000.0, 1800.0, 2200.0, 2300.0, 1700.0, 1800.0],
      [1100.0, 1000.0, 1200.0, 800.0, 700.0, 800.0],
      [0.0, 100.0, -200.0, 150.0, -100.0, -150.0],
      [-800.0, -400.0, -300.0, -400.0, -200.0, -250.0],
      ],
      xUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
      dataRowsLegends: const [
      'Big Corp',
      'Medium Corp',
      'Print Shop',
      'Bar',
      ],
      chartOptions: chartOptions,
      );
      var lineChartContainer = LineChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var lineChart = LineChart(
        painter: LineChartPainter(
          lineChartContainer: lineChartContainer,
        ),
      );
      return lineChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex31SomeNegativeValues_lineChart.png "Line Chart caption")


<a id="org3432df0"></a>

## ex31SomeNegativeValues\_barChart <a id="orgb5f44f1"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example shows a mix of positive and negative data values.
      chartData = ChartData(
      dataRows: const [
      [2000.0, 1800.0, 2200.0, 2300.0, 1700.0, 1800.0],
      [1100.0, 1000.0, 1200.0, 800.0, 700.0, 800.0],
      [0.0, 100.0, -200.0, 150.0, -100.0, -150.0],
      [-800.0, -400.0, -300.0, -400.0, -200.0, -250.0],
      ],
      xUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
      dataRowsLegends: const [
      'Big Corp',
      'Medium Corp',
      'Print Shop',
      'Bar',
      ],
      chartOptions: chartOptions,
      );
      var barChartContainer = BarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var barChart = BarChart(
        painter: BarChartPainter(
          barChartContainer: barChartContainer,
        ),
      );
      return barChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex31SomeNegativeValues_barChart.png "Line Chart caption")


<a id="org763be56"></a>

## ex32AllPositiveYsYAxisStartsAbove0\_lineChart <a id="orgbd56dc9"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example shows how to create ChartOptions instance
      //   which will request to start Y axis at data minimum.
      // Even though startYAxisAtDataMinRequested is set to true, this will not be granted on bar chart,
      //   as it does not make sense there.
      chartOptions = const ChartOptions(
      dataContainerOptions: DataContainerOptions(
      startYAxisAtDataMinRequested: true,
      ),
      );
      chartData = ChartData(
      dataRows: const [
      [20.0, 25.0, 30.0, 35.0, 40.0, 20.0],
      [35.0, 40.0, 20.0, 25.0, 30.0, 20.0],
      ],
      xUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
      dataRowsLegends: const [
      'Off zero 1',
      'Off zero 2',
      ],
      chartOptions: chartOptions,
      );
      var lineChartContainer = LineChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var lineChart = LineChart(
        painter: LineChartPainter(
          lineChartContainer: lineChartContainer,
        ),
      );
      return lineChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex32AllPositiveYsYAxisStartsAbove0_lineChart.png "Line Chart caption")


<a id="orgfe5d568"></a>

## ex32AllPositiveYsYAxisStartsAbove0\_barChart <a id="orge19a63d"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example shows how to create ChartOptions instance
      //   which will request to start Y axis at data minimum.
      // Even though startYAxisAtDataMinRequested is set to true, this will not be granted on bar chart,
      //   as it does not make sense there.
      chartOptions = const ChartOptions(
      dataContainerOptions: DataContainerOptions(
      startYAxisAtDataMinRequested: true,
      ),
      );
      chartData = ChartData(
      dataRows: const [
      [20.0, 25.0, 30.0, 35.0, 40.0, 20.0],
      [35.0, 40.0, 20.0, 25.0, 30.0, 20.0],
      ],
      xUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
      dataRowsLegends: const [
      'Off zero 1',
      'Off zero 2',
      ],
      chartOptions: chartOptions,
      );
      var barChartContainer = BarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var barChart = BarChart(
        painter: BarChartPainter(
          barChartContainer: barChartContainer,
        ),
      );
      return barChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex32AllPositiveYsYAxisStartsAbove0_barChart.png "Line Chart caption")


<a id="org86b4136"></a>

## ex33AllNegativeYsYAxisEndsBelow0\_lineChart <a id="orgd322ff6"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example shows how to create ChartOptions instance
      //   which will request to end Y axis at maximum data (as all data negative).
      // Even though startYAxisAtDataMinRequested is set to true, this will not be granted on bar chart,
      //   as it does not make sense there.
      chartOptions = const ChartOptions(
      dataContainerOptions: DataContainerOptions(
      startYAxisAtDataMinRequested: true,
      ),
      );
      chartData = ChartData(
      dataRows: const [
      [-20.0, -25.0, -30.0, -35.0, -40.0, -20.0],
      [-35.0, -40.0, -20.0, -25.0, -30.0, -20.0],
      ],
      xUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
      dataRowsLegends: const [
      'Off zero 1',
      'Off zero 2',
      ],
      chartOptions: chartOptions,
      );
      var lineChartContainer = LineChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var lineChart = LineChart(
        painter: LineChartPainter(
          lineChartContainer: lineChartContainer,
        ),
      );
      return lineChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex33AllNegativeYsYAxisEndsBelow0_lineChart.png "Line Chart caption")


<a id="org260cba6"></a>

## ex34OptionsDefiningUserTextStyleOnLabels\_lineChart <a id="orgcdf5631"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example shows how to use user-defined font in the chart labels.
      // In fact, same approach can be used more generally, to set any property
      //   in user-defined TextStyle (font, font color, etc - any property available on TextStyle) on labels.
      // To achieve setting custom fonts and/or any member of TextStyle,
      //   client can declare their own extension of 'LabelCommonOptions', and override the `labelTextStyle` getter.
      // A sample declaration of the class MyLabelCommonOptions, is given here as a comment.
      // ```dart
      //      /// An example user-defined extension of [LabelCommonOptions] overrides the [LabelCommonOptions.labelTextStyle]
      //      /// which is the source for user-specific font on labels.
      //      class MyLabelCommonOptions extends LabelCommonOptions {
      //        const MyLabelCommonOptions(
      //        ) : super ();
      //
      //        /// Override [labelTextStyle] with a new font, color, etc.
      //        @override
      //        get labelTextStyle => GoogleFonts.comforter(
      //          textStyle: const TextStyle(
      //          color: ui.Color(0xFF757575),
      //          fontSize: 14.0,
      //          fontWeight: FontWeight.w400, // Regular
      //          ),
      //        );
      //
      //        /* This alternative works in an app as well, but not in the integration test. All style set in options defaults.
      //        get labelTextStyle =>
      //          const ChartOptions().labelCommonOptions.labelTextStyle.copyWith(
      //            fontFamily: GoogleFonts.comforter().fontFamily,
      //          );
      //        */
      //      }
      // ```
      // Given such extended class, declare ChartOptions as follows:
      chartOptions = const ChartOptions(
      labelCommonOptions: MyLabelCommonOptions(),
      );
      // Then proceed as usual
      chartData = ChartData(
      dataRows: const [
      [20.0, 25.0, 30.0, 35.0, 40.0, 20.0],
      [35.0, 40.0, 20.0, 25.0, 30.0, 20.0],
      ],
      xUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
      dataRowsLegends: const [
      'Font Test Series1',
      'Font Test Series2',
      ],
      chartOptions: chartOptions,
      );
      var lineChartContainer = LineChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var lineChart = LineChart(
        painter: LineChartPainter(
          lineChartContainer: lineChartContainer,
        ),
      );
      return lineChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex34OptionsDefiningUserTextStyleOnLabels_lineChart.png "Line Chart caption")


<a id="org3d3c134"></a>

## ex35AnimalsBySeasonNoLabelsShown\_lineChart <a id="orgd400995"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Set chart options to show no labels
      chartOptions = const ChartOptions.noLabels();
    
      chartData = ChartData(
      dataRows: const [
      [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
      [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
      [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
      [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
      ],
      xUserLabels: const ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'],
      dataRowsLegends: const [
      'Spring',
      'Summer',
      'Fall',
      'Winter',
      ],
      chartOptions: chartOptions,
      );
      var lineChartContainer = LineChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var lineChart = LineChart(
        painter: LineChartPainter(
          lineChartContainer: lineChartContainer,
        ),
      );
      return lineChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex35AnimalsBySeasonNoLabelsShown_lineChart.png "Line Chart caption")


<a id="org7a1ade3"></a>

## ex35AnimalsBySeasonNoLabelsShown\_barChart <a id="org9227186"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Set chart options to show no labels
      chartOptions = const ChartOptions.noLabels();
    
      chartData = ChartData(
      dataRows: const [
      [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
      [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
      [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
      [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
      ],
      xUserLabels: const ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'],
      dataRowsLegends: const [
      'Spring',
      'Summer',
      'Fall',
      'Winter',
      ],
      chartOptions: chartOptions,
      );
      var barChartContainer = BarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var barChart = BarChart(
        painter: BarChartPainter(
          barChartContainer: barChartContainer,
        ),
      );
      return barChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex35AnimalsBySeasonNoLabelsShown_barChart.png "Line Chart caption")


<a id="orgc6be307"></a>

## ex40LanguagesWithYOrdinalUserLabelsAndUserColors\_lineChart <a id="orgd962a15"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // User-Provided Data (Y values), User-Provided X Labels, User-Provided Data Rows Legends, User-Provided Y Labels, User-Provided Colors
      // This example shows user defined Y Labels that derive order from data.
      //   When setting Y labels by user, the dataRows value scale
      //   is irrelevant. User can use for example interval <0, 1>,
      //   <0, 10>, or any other, even negative ranges. Here we use <0-10>.
      //   The only thing that matters is  the relative values in the data Rows.
      // Current implementation sets
      //   the minimum of dataRows range (1.0 in this example)
      //     on the level of the first Y Label ("Low" in this example),
      //   and the maximum  of dataRows range (10.0 in this example)
      //     on the level of the last Y Label ("High" in this example).
      chartData = ChartData(
      dataRows: const [
      [9.0, 4.0, 3.0, 9.0],
      [7.0, 6.0, 7.0, 6.0],
      [4.0, 9.0, 6.0, 8.0],
      [3.0, 9.0, 10.0, 1.0],
      ],
      xUserLabels: const ['Speed', 'Readability', 'Level of Novel', 'Usage'],
      dataRowsColors: const [
      Colors.blue,
      Colors.yellow,
      Colors.green,
      Colors.amber,
      ],
      dataRowsLegends: const ['Java', 'Dart', 'Python', 'Newspeak'],
      yUserLabels: const [
      'Low',
      'Medium',
      'High',
      ],
      chartOptions: chartOptions,
      );
    
      var lineChartContainer = LineChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var lineChart = LineChart(
        painter: LineChartPainter(
          lineChartContainer: lineChartContainer,
        ),
      );
      return lineChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex40LanguagesWithYOrdinalUserLabelsAndUserColors_lineChart.png "Line Chart caption")


<a id="org91f6516"></a>

## ex50StocksWithNegativesWithUserColors\_barChart <a id="org6246d9c"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // User-Provided Data (Y values), User-Provided X Labels, User-Provided Data Rows Legends, Data-Based Y Labels, User-Provided Colors,
      //        This shows a bug where negatives go below X axis.
      // If we want the chart to show User-Provided textual Y labels with
      // In each column, adding it's absolute values should add to same number:
      // todo-04-examples 100 would make more sense, to represent 100% of stocks in each category. Also columns should add to the same number?
    
      chartData = ChartData(
      // each column should add to same number. everything else is relative.
      dataRows: const [
      [-9.0, -8.0, -8.0, -5.0, -8.0],
      [-1.0, -2.0, -4.0, -1.0, -1.0],
      [7.0, 8.0, 7.0, 11.0, 9.0],
      [3.0, 2.0, 1.0, 3.0, 3.0],
      ],
      xUserLabels: const ['Energy', 'Health', 'Finance', 'Chips', 'Oil'],
      dataRowsLegends: const [
      '-2% or less',
      '-2% to 0%',
      '0% to +2%',
      'more than +2%',
      ],
      dataRowsColors: const [
      Colors.red,
      Colors.grey,
      Colors.greenAccent,
      Colors.black,
      ],
      chartOptions: chartOptions,
      );
      var barChartContainer = BarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var barChart = BarChart(
        painter: BarChartPainter(
          barChartContainer: barChartContainer,
        ),
      );
      return barChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex50StocksWithNegativesWithUserColors_barChart.png "Line Chart caption")


<a id="org77e5f4f"></a>

## ex52AnimalsBySeasonLogarithmicScale\_lineChart <a id="org673ceb3"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      chartOptions = const ChartOptions(
      dataContainerOptions: DataContainerOptions(
      yTransform: log10,
      yInverseTransform: inverseLog10,
      ),
      );
      chartData = ChartData(
      dataRows: const [
      [10.0, 600.0, 1000000.0],
      [20.0, 1000.0, 1500000.0],
      ],
      xUserLabels: const ['Wolf', 'Deer', 'Mouse'],
      dataRowsLegends: const [
      'Spring',
      'Summer',
      ],
      chartOptions: chartOptions,
      );
      var lineChartContainer = LineChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var lineChart = LineChart(
        painter: LineChartPainter(
          lineChartContainer: lineChartContainer,
        ),
      );
      return lineChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex52AnimalsBySeasonLogarithmicScale_lineChart.png "Line Chart caption")


<a id="org042b202"></a>

## ex52AnimalsBySeasonLogarithmicScale\_barChart <a id="org807928e"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      chartOptions = const ChartOptions(
      dataContainerOptions: DataContainerOptions(
      yTransform: log10,
      yInverseTransform: inverseLog10,
      ),
      );
      chartData = ChartData(
      dataRows: const [
      [10.0, 600.0, 1000000.0],
      [20.0, 1000.0, 1500000.0],
      ],
      xUserLabels: const ['Wolf', 'Deer', 'Mouse'],
      dataRowsLegends: const [
      'Spring',
      'Summer',
      ],
      chartOptions: chartOptions,
      );
      var barChartContainer = BarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var barChart = BarChart(
        painter: BarChartPainter(
          barChartContainer: barChartContainer,
        ),
      );
      return barChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex52AnimalsBySeasonLogarithmicScale_barChart.png "Line Chart caption")


<a id="orgada2279"></a>

## ex60LabelsIteration1\_barChart <a id="orgbdb2c57"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example with side effects cannot be simply pasted to your code, as the _ExampleSideEffects is private
      // This example shows the result with sufficient space to show all labels
      chartData = ChartData(
      dataRows: const [
      [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
      [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
      ],
      xUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
      dataRowsLegends: const [
      'Owl count',
      'Hawk count',
      ],
      chartOptions: chartOptions,
      );
      exampleSideEffects = _ExampleSideEffects()..leftSqueezeText=''.. rightSqueezeText='';
      var barChartContainer = BarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var barChart = BarChart(
        painter: BarChartPainter(
          barChartContainer: barChartContainer,
        ),
      );
      return barChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex60LabelsIteration1_barChart.png "Line Chart caption")


<a id="orgd3771d7"></a>

## ex60LabelsIteration2\_barChart <a id="orgfe51f7b"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example with side effects cannot be simply pasted to your code, as the _ExampleSideEffects is private
      // This example shows the result with sufficient space to show all labels, but not enough to be horizontal;
      // The iterative layout strategy makes the labels to tilt but show fully.
      chartData = ChartData(
      dataRows: const [
      [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
      [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
      ],
      xUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
      dataRowsLegends: const [
      'Owl count',
      'Hawk count',
      ],
      chartOptions: chartOptions,
      );
      exampleSideEffects = _ExampleSideEffects()..leftSqueezeText='>>'.. rightSqueezeText='<' * 3;
      var barChartContainer = BarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var barChart = BarChart(
        painter: BarChartPainter(
          barChartContainer: barChartContainer,
        ),
      );
      return barChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex60LabelsIteration2_barChart.png "Line Chart caption")


<a id="org547dcea"></a>

## ex60LabelsIteration3\_barChart <a id="orga666d35"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example with side effects cannot be simply pasted to your code, as the _ExampleSideEffects is private
      // This example shows the result with sufficient space to show all labels, not even tilted;
      // The iterative layout strategy causes some labels to be skipped.
      chartData = ChartData(
      dataRows: const [
      [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
      [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
      ],
      xUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
      dataRowsLegends: const [
      'Owl count',
      'Hawk count',
      ],
      chartOptions: chartOptions,
      );
      exampleSideEffects = _ExampleSideEffects()..leftSqueezeText='>>'.. rightSqueezeText='<' * 6;
      var barChartContainer = BarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var barChart = BarChart(
        painter: BarChartPainter(
          barChartContainer: barChartContainer,
        ),
      );
      return barChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex60LabelsIteration3_barChart.png "Line Chart caption")


<a id="org95e404c"></a>

## ex60LabelsIteration4\_barChart <a id="org8f86d1f"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Example with side effects cannot be simply pasted to your code, as the _ExampleSideEffects is private
      // This example shows the result with sufficient space to show all labels, not even tilted;
      // The iterative layout strategy causes more labels to be skipped.
      chartData = ChartData(
      dataRows: const [
      [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
      [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
      ],
      xUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
      dataRowsLegends: const [
      'Owl count',
      'Hawk count',
      ],
      chartOptions: chartOptions,
      );
      exampleSideEffects = _ExampleSideEffects()..leftSqueezeText='>>'.. rightSqueezeText='<' * 30;
      var barChartContainer = BarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var barChart = BarChart(
        painter: BarChartPainter(
          barChartContainer: barChartContainer,
        ),
      );
      return barChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex60LabelsIteration4_barChart.png "Line Chart caption")


<a id="orgc87cb9f"></a>

## ex900ErrorFixUserDataAllZero\_lineChart <a id="org429502d"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
    
      /// Currently, setting [ChartDate.dataRows] requires to also set all of
      /// [chartData.xUserLabels], [chartData.dataRowsLegends], [chartData.dataRowsColors]
      // Fix was: Add default legend to ChartData constructor AND fix scaling util_dart.dart scaleValue.
      chartData = ChartData(
      dataRows: const [
      [0.0, 0.0, 0.0],
      ],
      // Note: When ChartData is defined,
      //       ALL OF  xUserLabels,  dataRowsLegends, dataRowsColors
      //       must be set by client
      xUserLabels: const ['Wolf', 'Deer', 'Mouse'],
      dataRowsLegends: const [
      'Row 1',
      ],
      dataRowsColors: const [
      Colors.blue,
      ],
      chartOptions: chartOptions,
      );
      var lineChartContainer = LineChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var lineChart = LineChart(
        painter: LineChartPainter(
          lineChartContainer: lineChartContainer,
        ),
      );
      return lineChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex900ErrorFixUserDataAllZero_lineChart.png "Line Chart caption")


<a id="orgeaf773f"></a>

# Latest release changes

The latest release is 0.5.0

The <CHANGELOG.md> document describes new features and bug fixes in this and older versions.


<a id="org03b46dd"></a>

# Installation


<a id="org30b6b7c"></a>

## Installing flutter\_charts as a library package into your app

If you want to use the `flutter_charts` library package in your app, please follow instructions in <https://pub.dev/packages/flutter_charts/install>. This will result in ability of your app to use  `flutter_charts`.


<a id="org03fe7ad"></a>

## Installing the flutter\_charts project as a local clone from Github

The advantage of installing the source of the `flutter_charts` project locally from Github is that you can run the packaged example application and also run the integration and widget tests.

To install (clone) the `flutter_charts` project from Github to your local system, follow these steps:

-   Install Flutter, and items such as Android emulator. Instructions are on the Flutter website <https://docs.flutter.dev/get-started/install>.
-   Go to <https://github.com/mzimmerm/flutter_charts>, click on the "Code" button, and follow the instuctions to checkout flutter\_charts. A summary of one installation method (download method):
-   Click the "Download zip" link <https://github.com/mzimmerm/flutter_charts/archive/refs/heads/master.zip>
-   When prompted, save the file `flutter_charts-master.zip` one level above where you want the project. We will use `$HOME/dev`
-   Unzip the file `flutter_charts-master.zip`
-   The project will be in the `$HOME/dev/flutter_charts-master/` directory


<a id="org0430cd4"></a>

# Running the examples included in flutter\_charts

This section assumes you installed the flutter\_charts project as a local clone from Github, as described in [4](#org0430cd4)

There is an example application in flutter\_charts: `example/main_run_doc_example.dart`. It shows how the Flutter Charts library can be included in a Flutter application.

To run the example application, Android emulator or iOS emulator need to be installed. You can use an IDE or command line. Instructions here are for the command line. Start in the unzipped directory, and follow the steps below:

-   Important: Make sure an Android or iOS emulator is running, or you have a physical device connected. See the [3.2](#org03fe7ad) section.
-   `cd $HOME/dev/flutter_charts-master/`
-   Paste any of the lines below to the command line.
    -   To run the example chart in examples/main_run_doc_example.dart:
            tool/demo/run_example.sh


Sample screenshot from running the example app

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_lineChart.png "Line Chart caption")


<a id="org84b6d75"></a>

# Illustration of the "iterative auto layout" feature

This section illustrates how the auto layout behaves when less and less horizontal space is available to display the chart. 

Flutter chart library automatically checks for the X label overlap, and follows with rule-based iterative re-layout, to prevent labels running into each other.

To illustrate "stressed" horizontal space for the chart, we are gradually adding a text widget containing and increasing number of '<' characters on the right of the chart.


<a id="org13982d7"></a>

## Autolayout step 1

Let's say there are six labels on a chart, and there is sufficient space to display labels horizontally. The result may look like this:
We can see all x axis labels displayed it full, horizontally oriented.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-1.png)


<a id="orgc1d8a8f"></a>

## Autolayout step 2

Next, let us make less available space by taking away some space on the right with a wider text label such as '<<<<<<'
We can see the labels were automatically tilted by the angle `LabelLayoutStrategy.labelTiltRadians` for the labels to fit.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-2.png)


<a id="org030cb34"></a>

## Autolayout step 3

Next, let us make even less available space by taking away some space on the right with a wider text label such as '<<<<<<<<<<<'.
We can see that labels are not only tilted, but also automatically skipped for labels not to overlap (every 2nd label is skipped, see option `ChartOptions.iterativeLayoutOptions.showEveryNthLabel`).

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-3.png)


<a id="orga7d9ad4"></a>

## Autolayout step 4

Next, let us make even less available space some more compared to step 3, with even a wider text label such as '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'.
We can see even more labels were skipped for labels to prevent overlap, the chart is showing every 5th label.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-4.png)


<a id="org435b9c8"></a>

## Autolayout step 5

Last, let us take away extreme amount of horizontal space by using '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<',
Here we can see the "default auto layout" finally gave up, and overlaps labels. Also, the legend is now hidded, as the amount of horizontal space is not sufficient.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-5.png)


<a id="org269d91a"></a>

# Known packages, libraries and apps that use this flutter\_charts package

1.  Michael R. Fairhurst's **Language reader app** - see <https://github.com/MichaelRFairhurst/flutter-language-reader-app>


<a id="org44f7bdf"></a>

# TODO Todos

1.  [X] During construction of DataRows, enforce default values of Legend names and colors for rows. This fixes issues such as <https://github.com/mzimmerm/flutter_charts/issues/18>, when users do not set them and expect (reasonably) a default chart to show anyway.
2.  [ ] Replace \`reduce(fn)\` with \`fold(initialValue, fn)\` throughout code to deal with exceptions when lists are empty.
3.  [X] Allow scaling y values using a function.


<a id="org91e5332"></a>

# Internal notes for exporting this document

Before a new release, perform these steps:

1.  Run the following babel script which refreshes the 'expected' screenshots and also creates a 150px wide version. Do so by clicking C-c twice in the begin\_src section. The `tool/demo/run_example.sh` runs the chart example within; it is also used to generate images gallery with links to code in this README file on top.
    
    Convert expected screenshots to readme\_images, while converting to 2 versions, one with width=150, one with 300  
    
        for file in https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex*; do
            rm $file
        done
        for file in integration_test/screenshots_expected/ex*; do
            # cp $file https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images
            convert $file -resize 300 https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/$(basename $file)
        done
        for file in https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex*; do
            copy_name="$(basename $file)"
            copy_name="${copy_name/%.*/}"
            convert  $file -resize 150 $(dirname $file)/${copy_name}_w150.png
        done

2.  Delete the section AFTER the end\_src in [1](#org70673f2), all the way to above the heading [2](#orgeaf773f)

3.  Run once the script in [1](#org70673f2). If generates examples from code. Should be run once, manually, before export to MD. Before export to MD, delete the line "RESULTS". The manually generated sections will be exported to MD during export. Before running again, go to Step 2, as the example sections would accumulate.

4.  Remove the "RESULTS:" generated in the step before.

