
<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Examples with code](#examples-with-code)
    - [ex10RandomData\_lineChart](#ex10randomdata_linechart-a-idorg50b005fa)
    - [ex10RandomData\_verticalBarChart](#ex10randomdata_verticalbarchart-a-idorg2f3ebfea)
    - [ex11RandomDataWithLabelLayoutStrategy\_lineChart](#ex11randomdatawithlabellayoutstrategy_linechart-a-idorg90deb4ca)
    - [ex11RandomDataWithLabelLayoutStrategy\_verticalBarChart](#ex11randomdatawithlabellayoutstrategy_verticalbarchart-a-idorgc3429a1a)
    - [ex30AnimalsBySeasonWithLabelLayoutStrategy\_lineChart](#ex30animalsbyseasonwithlabellayoutstrategy_linechart-a-idorg66f86fea)
    - [ex30AnimalsBySeasonWithLabelLayoutStrategy\_verticalBarChart](#ex30animalsbyseasonwithlabellayoutstrategy_verticalbarchart-a-idorg3ff846ca)
    - [ex31SomeNegativeValues\_lineChart](#ex31somenegativevalues_linechart-a-idorg10807daa)
    - [ex31SomeNegativeValues\_verticalBarChart](#ex31somenegativevalues_verticalbarchart-a-idorg7eae7eea)
    - [ex32AllPositiveYsYAxisStartsAbove0\_lineChart](#ex32allpositiveysyaxisstartsabove0_linechart-a-idorgb1baa90a)
    - [ex32AllPositiveYsYAxisStartsAbove0\_verticalBarChart](#ex32allpositiveysyaxisstartsabove0_verticalbarchart-a-idorg4f23297a)
    - [ex33AllNegativeYsYAxisEndsBelow0\_lineChart](#ex33allnegativeysyaxisendsbelow0_linechart-a-idorg5271609a)
    - [ex35AnimalsBySeasonNoLabelsShown\_lineChart](#ex35animalsbyseasonnolabelsshown_linechart-a-idorg91f29f8a)
    - [ex35AnimalsBySeasonNoLabelsShown\_verticalBarChart](#ex35animalsbyseasonnolabelsshown_verticalbarchart-a-idorg7ec3a49a)
    - [ex40LanguagesWithYOrdinalUserLabelsAndUserColors\_lineChart](#ex40languageswithyordinaluserlabelsandusercolors_linechart-a-idorg2971be6a)
    - [ex50StocksWithNegativesWithUserColors\_verticalBarChart](#ex50stockswithnegativeswithusercolors_verticalbarchart-a-idorga95d16da)
    - [ex52AnimalsBySeasonLogarithmicScale\_lineChart](#ex52animalsbyseasonlogarithmicscale_linechart-a-idorg68eb351a)
    - [ex52AnimalsBySeasonLogarithmicScale\_verticalBarChart](#ex52animalsbyseasonlogarithmicscale_verticalbarchart-a-idorg78f5272a)
    - [ex900ErrorFixUserDataAllZero\_lineChart](#ex900errorfixuserdataallzero_linechart-a-idorgfd7b37ea)
- [Latest release changes](#latest-release-changes)
- [Installation](#installation)
    - [Installing flutter\_charts as a library package into your app](#installing-flutter_charts-as-a-library-package-into-your-app)
    - [Installing the flutter\_charts project as a local clone from Github](#installing-the-flutter_charts-project-as-a-local-clone-from-github)
- [Running the examples included in flutter\_charts](#running-the-examples-included-in-flutter_charts)
- [Old Examples with code: LineChart and VerticalBarChart. Code and resulting charts](#old-examples-with-code-linechart-and-verticalbarchart-code-and-resulting-charts)
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
- [TODO Todos](#todo-todos)
- [Internal notes for exporting this document](#internal-notes-for-exporting-this-document)

<!-- markdown-toc end -->


# Examples with code

This section contains sample results from flutter\_charts. Click on the images to see the code that generated them, with a larger image.

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<tbody>
<tr>
<td class="org-left"><a href="#org50b005f"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org2f3ebfe"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org90deb4c"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex11RandomDataWithLabelLayoutStrategy_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgc3429a1"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex11RandomDataWithLabelLayoutStrategy_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org66f86fe"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex30AnimalsBySeasonWithLabelLayoutStrategy_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org3ff846c"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex30AnimalsBySeasonWithLabelLayoutStrategy_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org10807da"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex31SomeNegativeValues_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org7eae7ee"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex31SomeNegativeValues_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgb1baa90"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex32AllPositiveYsYAxisStartsAbove0_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org4f23297"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex32AllPositiveYsYAxisStartsAbove0_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org5271609"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex33AllNegativeYsYAxisEndsBelow0_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org91f29f8"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex35AnimalsBySeasonNoLabelsShown_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org7ec3a49"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex35AnimalsBySeasonNoLabelsShown_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org2971be6"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex40LanguagesWithYOrdinalUserLabelsAndUserColors_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orga95d16d"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex50StocksWithNegativesWithUserColors_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org68eb351"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex52AnimalsBySeasonLogarithmicScale_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org78f5272"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex52AnimalsBySeasonLogarithmicScale_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgfd7b37e"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex900ErrorFixUserDataAllZero_lineChart_w150.png" alt="nil"/></a></td>
</tr>
</tbody>
</table>



## ex10RandomData\_lineChart <a id="org50b005f"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
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



## ex10RandomData\_verticalBarChart <a id="org2f3ebfe"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      chartData = RandomChartData.generated(chartOptions: chartOptions);
      var verticalBarChartContainer = VerticalBarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var verticalBarChart = VerticalBarChart(
        painter: VerticalBarChartPainter(
          verticalBarChartContainer: verticalBarChartContainer,
        ),
      );
      return verticalBarChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_verticalBarChart.png "Line Chart caption")



## ex11RandomDataWithLabelLayoutStrategy\_lineChart <a id="org90deb4c"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      xContainerLabelLayoutStrategy = DefaultIterativeLabelLayoutStrategy(
      options: chartOptions,
      );
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

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex11RandomDataWithLabelLayoutStrategy_lineChart.png "Line Chart caption")



## ex11RandomDataWithLabelLayoutStrategy\_verticalBarChart <a id="orgc3429a1"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      xContainerLabelLayoutStrategy = DefaultIterativeLabelLayoutStrategy(
      options: chartOptions,
      );
      chartData = RandomChartData.generated(chartOptions: chartOptions);
      var verticalBarChartContainer = VerticalBarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var verticalBarChart = VerticalBarChart(
        painter: VerticalBarChartPainter(
          verticalBarChartContainer: verticalBarChartContainer,
        ),
      );
      return verticalBarChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex11RandomDataWithLabelLayoutStrategy_verticalBarChart.png "Line Chart caption")



## ex30AnimalsBySeasonWithLabelLayoutStrategy\_lineChart <a id="org66f86fe"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Shows explicit use of DefaultIterativeLabelLayoutStrategy with Random values and labels.
      // The xContainerLabelLayoutStrategy, if set to null or not set at all, defaults to DefaultIterativeLabelLayoutStrategy
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



## ex30AnimalsBySeasonWithLabelLayoutStrategy\_verticalBarChart <a id="org3ff846c"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Shows explicit use of DefaultIterativeLabelLayoutStrategy with Random values and labels.
      // The xContainerLabelLayoutStrategy, if set to null or not set at all, defaults to DefaultIterativeLabelLayoutStrategy
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
      var verticalBarChartContainer = VerticalBarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var verticalBarChart = VerticalBarChart(
        painter: VerticalBarChartPainter(
          verticalBarChartContainer: verticalBarChartContainer,
        ),
      );
      return verticalBarChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex30AnimalsBySeasonWithLabelLayoutStrategy_verticalBarChart.png "Line Chart caption")



## ex31SomeNegativeValues\_lineChart <a id="org10807da"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
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



## ex31SomeNegativeValues\_verticalBarChart <a id="org7eae7ee"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
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
      var verticalBarChartContainer = VerticalBarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var verticalBarChart = VerticalBarChart(
        painter: VerticalBarChartPainter(
          verticalBarChartContainer: verticalBarChartContainer,
        ),
      );
      return verticalBarChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex31SomeNegativeValues_verticalBarChart.png "Line Chart caption")



## ex32AllPositiveYsYAxisStartsAbove0\_lineChart <a id="orgb1baa90"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Set option which will ask to start Y axis at data minimum.
      // Even though startYAxisAtDataMinRequested set to true, will not be granted on bar chart
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



## ex32AllPositiveYsYAxisStartsAbove0\_verticalBarChart <a id="org4f23297"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Set option which will ask to start Y axis at data minimum.
      // Even though startYAxisAtDataMinRequested set to true, will not be granted on bar chart
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
      var verticalBarChartContainer = VerticalBarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var verticalBarChart = VerticalBarChart(
        painter: VerticalBarChartPainter(
          verticalBarChartContainer: verticalBarChartContainer,
        ),
      );
      return verticalBarChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex32AllPositiveYsYAxisStartsAbove0_verticalBarChart.png "Line Chart caption")



## ex33AllNegativeYsYAxisEndsBelow0\_lineChart <a id="org5271609"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // Ask to end Y axis at maximum data (as all data negative)
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



## ex35AnimalsBySeasonNoLabelsShown\_lineChart <a id="org91f29f8"></a>

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



## ex35AnimalsBySeasonNoLabelsShown\_verticalBarChart <a id="org7ec3a49"></a>

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
      var verticalBarChartContainer = VerticalBarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var verticalBarChart = VerticalBarChart(
        painter: VerticalBarChartPainter(
          verticalBarChartContainer: verticalBarChartContainer,
        ),
      );
      return verticalBarChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex35AnimalsBySeasonNoLabelsShown_verticalBarChart.png "Line Chart caption")



## ex40LanguagesWithYOrdinalUserLabelsAndUserColors\_lineChart <a id="org2971be6"></a>

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



## ex50StocksWithNegativesWithUserColors\_verticalBarChart <a id="orga95d16d"></a>

Code

    Widget chartToRun() {
      LabelLayoutStrategy? xContainerLabelLayoutStrategy;
      ChartData chartData;
      ChartOptions chartOptions = const ChartOptions();
      // User-Provided Data (Y values), User-Provided X Labels, User-Provided Data Rows Legends, Data-Based Y Labels, User-Provided Colors,
      //        This shows a bug where negatives go below X axis.
      // If we want the chart to show User-Provided textual Y labels with
      // In each column, adding it's absolute values should add to same number:
      // todo-11-examples 100 would make more sense, to represent 100% of stocks in each category.
    
      chartData = ChartData(
      // each column should add to same number. everything else is relative. todo-11-examples maybe no need to add to same number.
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
      var verticalBarChartContainer = VerticalBarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var verticalBarChart = VerticalBarChart(
        painter: VerticalBarChartPainter(
          verticalBarChartContainer: verticalBarChartContainer,
        ),
      );
      return verticalBarChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex50StocksWithNegativesWithUserColors_verticalBarChart.png "Line Chart caption")



## ex52AnimalsBySeasonLogarithmicScale\_lineChart <a id="org68eb351"></a>

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



## ex52AnimalsBySeasonLogarithmicScale\_verticalBarChart <a id="org78f5272"></a>

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
      var verticalBarChartContainer = VerticalBarChartTopContainer(
        chartData: chartData,
        xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
      );
    
      var verticalBarChart = VerticalBarChart(
        painter: VerticalBarChartPainter(
          verticalBarChartContainer: verticalBarChartContainer,
        ),
      );
      return verticalBarChart;
    }

Result

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex52AnimalsBySeasonLogarithmicScale_verticalBarChart.png "Line Chart caption")



## ex900ErrorFixUserDataAllZero\_lineChart <a id="orgfd7b37e"></a>

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



# Latest release changes

The latest release is 0.4.0

The <CHANGELOG.md> document describes new features and bug fixes in this and older versions.



# Installation



## Installing flutter\_charts as a library package into your app

If you want to use the `flutter_charts` library package in your app, please follow instructions in <https://pub.dev/packages/flutter_charts/install>. This will result in ability of your app to use  `flutter_charts`.



## Installing the flutter\_charts project as a local clone from Github

The advantage of installing the source of the `flutter_charts` project locally from Github is that you can run the packaged example application and also run the integration and widget tests.

To install (clone) the `flutter_charts` project from Github to your local system, follow these steps:

-   Install Flutter, and items such as Android emulator. Instructions are on the Flutter website <https://docs.flutter.dev/get-started/install>.
-   Go to <https://github.com/mzimmerm/flutter_charts>, click on the "Code" button, and follow the instuctions to checkout flutter\_charts. A summary of one installation method (download method):
-   Click the "Download zip" link <https://github.com/mzimmerm/flutter_charts/archive/refs/heads/master.zip>
-   When prompted, save the file `flutter_charts-master.zip` one level above where you want the project. We will use `$HOME/dev`
-   Unzip the file `flutter_charts-master.zip`
-   The project will be in the `$HOME/dev/flutter_charts-master/` directory



# Running the examples included in flutter\_charts

This section assumes you installed the flutter\_charts project as a local clone from Github, as described in [4](#org0581faf)

There is an example application in flutter\_charts: `example1/lib/main.dart`. It shows how the Flutter Charts library can be included in a Flutter application.

To run the example application, Android emulator or iOS emulator need to be installed. You can use an IDE or command line. Instructions here are for the command line. Start in the unzipped directory, and follow the steps below:

-   Important: Make sure an Android or iOS emulator is running, or you have a physical device connected. See the [3.2](#orgaa26b5f) section.
-   `cd $HOME/dev/flutter_charts-master/`
-   Paste any of the lines below to the command line.
    -   To run one example (actually two, first line chart, next vertical bar chart), run:
        
            tool/demo/run_all_examples.sh ex10RandomData
        
        (press q in the terminal to quit the current example and run next)
    -   To run all examples 
        
            tool/demo/run_all_examples.sh
        
        (press q in the terminal to quit the current example and run next)

Sample screenshot from running the example app

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_lineChart.png "Line Chart caption")



# Old Examples with code: LineChart and VerticalBarChart. Code and resulting charts

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

See the section [4](#org0581faf) on how to run the code that created the images below.  The code snippets are from the method `Widget createRequestedChart()` in `example1/lib/main.dart` 



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



## User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, User-Provided Y Labels

This example show how to use the option `useUserProvidedYLabels`, and scaling of data to the Y labels range.

For code, please refer to the function `Widget createRequestedChart()` in <https://github.com/mzimmerm/flutter_charts/blob/master/example1/lib/main.dart>, section `ExamplesEnum.ex40LanguagesWithYOrdinalUserLabelsAndUserColors`

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex40LanguagesWithYOrdinalUserLabelsAndUserColors_lineChart.png "Line Chart caption")



## VerticalBar Chart - one more example, showing positive/negative stacks:



### User-Provided Data (Y values), User-Provided X Labels, User-Provided Colors, User-Provided Data Rows Legends, User-Provided Y Labels

This example has again user defined Y Labels, with a bar chart, using the smart auto-layout of user defined Y Labels. The chart shows negative and positive values similar to %down/%up stock charts.

For code, please refer to the function `Widget createRequestedChart()` in <https://github.com/mzimmerm/flutter_charts/blob/master/example1/lib/main.dart>, section `ExamplesEnum.ex50StocksWithNegativesWithUserColors`

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex50StocksWithNegativesWithUserColors_verticalBarChart.png "Line Chart caption")

(there is a bug here,see Known Bugs)



# Illustration of the "iterative auto layout" feature

This section illustrates how the auto layout behaves when less and less horizontal space is available to display the chart. 

Flutter chart library automatically checks for the X label overlap, and follows with rule-based iterative re-layout, to prevent labels running into each other.

To illustrate "stressed" horizontal space for the chart, we are gradually adding a text widget containing and increasing number of '<' characters on the right of the chart.



## Autolayout step 1

Let's say there are six labels on a chart, and there is sufficient space to display labels horizontally. The result may look like this:
We can see all x axis labels displayed it full, horizontally oriented.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-1.png)



## Autolayout step 2

Next, let us make less available space by taking away some space on the right with a wider text label such as '<<<<<<'
We can see the labels were automatically tilted by the angle `LabelLayoutStrategy.labelTiltRadians` for the labels to fit.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-2.png)



## Autolayout step 3

Next, let us make even less available space by taking away some space on the right with a wider text label such as '<<<<<<<<<<<'.
We can see that labels are not only tilted, but also automatically skipped for labels not to overlap (every 2nd label is skipped, see option `ChartOptions.iterativeLayoutOptions.showEveryNthLabel`).

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-3.png)



## Autolayout step 4

Next, let us make even less available space some more compared to step 3, with even a wider text label such as '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'.
We can see even more labels were skipped for labels to prevent overlap, the chart is showing every 5th label.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-4.png)



## Autolayout step 5

Last, let us take away extreme amount of horizontal space by using '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<',
Here we can see the "default auto layout" finally gave up, and overlaps labels. Also, the legend is now hidded, as the amount of horizontal space is not sufficient.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-5.png)



# Known packages, libraries and apps that use this flutter\_charts package

1.  Michael R. Fairhurst's **Language reader app** - see <https://github.com/MichaelRFairhurst/flutter-language-reader-app>



# TODO Todos

1.  [X] During construction of DataRows, enforce default values of Legend names and colors for rows. This fixes issues such as <https://github.com/mzimmerm/flutter_charts/issues/18>, when users do not set them and expect (reasonably) a default chart to show anyway.
2.  [ ] Replace \`reduce(fn)\` with \`fold(initialValue, fn)\` throughout code to deal with exceptions when lists are empty.
3.  [X] Allow scaling y values using a function.



# Internal notes for exporting this document

1.  Before a release, run the following script to refresh the 'expected' screenshots. If the test `tool/demo/run_all_examples.sh` succeeds, it is quarenteed the 'expected' screenshots are same as those produced by the code in `example1/lib/main.dart`, which is used to generate code in this README file.

Convert all images to width=150  

    for file in doc/readme_images/ex*; do
        rm $file
    done
    for file in integration_test/screenshots_expected/ex*; do
        cp $file doc/readme_images
    done
    for file in doc/readme_images/ex*; do
        copy_name="$(basename $file)"
        copy_name="${copy_name/%.*/}"
        convert  $file -resize 150 $(dirname $file)/${copy_name}_w150.png
    done

1.  Before release, run once the script in heading [1](#org1b0969e). If generates examples from code. Should be run once, manually, before export to MD. Before export to MD, delete the line "RESULTS". The manually generated sections will be exported to MD during export. Before running again, delete the generated examples header sections, as they would accumulate.

