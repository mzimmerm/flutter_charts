
# Table of Contents

1.  [Examples with code](#org6344630)
    1.  [ex10RandomData\_lineChart ](#orga85576b)
    2.  [ex10RandomData\_verticalBarChart ](#org8039dc8)
    3.  [ex11RandomDataWithLabelLayoutStrategy\_lineChart ](#org9cc984a)
    4.  [ex11RandomDataWithLabelLayoutStrategy\_verticalBarChart ](#org0257f0a)
    5.  [ex30AnimalsBySeasonWithLabelLayoutStrategy\_lineChart ](#org49e03da)
    6.  [ex30AnimalsBySeasonWithLabelLayoutStrategy\_verticalBarChart ](#orgbd3d2e6)
    7.  [ex31SomeNegativeValues\_lineChart ](#orge024393)
    8.  [ex31SomeNegativeValues\_verticalBarChart ](#orgca0acaf)
    9.  [ex32AllPositiveYsYAxisStartsAbove0\_lineChart ](#orgf257df2)
    10. [ex32AllPositiveYsYAxisStartsAbove0\_verticalBarChart ](#org7340164)
    11. [ex33AllNegativeYsYAxisEndsBelow0\_lineChart ](#orgdb72a53)
    12. [ex35AnimalsBySeasonNoLabelsShown\_lineChart ](#org3c3f79a)
    13. [ex35AnimalsBySeasonNoLabelsShown\_verticalBarChart ](#org5c33865)
    14. [ex40LanguagesWithYOrdinalUserLabelsAndUserColors\_lineChart ](#org75e1070)
    15. [ex50StocksWithNegativesWithUserColors\_verticalBarChart ](#org5ca70ba)
    16. [ex52AnimalsBySeasonLogarithmicScale\_lineChart ](#org369cbfd)
    17. [ex52AnimalsBySeasonLogarithmicScale\_verticalBarChart ](#org9f514f4)
    18. [ex900ErrorFixUserDataAllZero\_lineChart ](#orga660e4f)
2.  [Latest release changes](#org6e7cb91)
3.  [Installation](#orga756f82)
    1.  [Installing flutter\_charts as a library package into your app](#orgd4d6a89)
    2.  [Installing the flutter\_charts project as a local clone from Github](#org17224c8)
4.  [Running the examples included in flutter\_charts](#org979d6b4)
5.  [Old Examples with code: LineChart and VerticalBarChart. Code and resulting charts](#org909b0d0)
    1.  [Example with Random Data (Y values), Random X Labels, Random Colors, Random Data Rows Legends, Data-Generated Y Labels.](#org7b2efca)
    2.  [User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, Data-Generated Y Labels,](#orgd99805d)
    3.  [User-Provided Data (Y values), User-Provided X Labels, Random Colors, User-Provided Data Rows Legends, User-Provided Y Labels](#org41177fa)
    4.  [VerticalBar Chart - one more example, showing positive/negative stacks:](#org7f9f07a)
        1.  [User-Provided Data (Y values), User-Provided X Labels, User-Provided Colors, User-Provided Data Rows Legends, User-Provided Y Labels](#org5fe04ed)
6.  [Illustration of the "iterative auto layout" feature](#orgdc3548e)
    1.  [Autolayout step 1](#orga391b02)
    2.  [Autolayout step 2](#orgf33a27c)
    3.  [Autolayout step 3](#org4d9d6d5)
    4.  [Autolayout step 4](#org3d59435)
    5.  [Autolayout step 5](#orge8a31a7)
7.  [Known packages, libraries and apps that use this flutter\_charts package](#orgd25de53)
8.  [Todos](#orge152000)
9.  [Internal notes for exporting this document](#orge4e2be8)



<a id="org6344630"></a>

# Examples with code

This section contains sample results from flutter\_charts. 

Click on an image to see the code that generated it.

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<tbody>
<tr>
<td class="org-left"><a href="#org5b3fdbd"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org5418f4a"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex10RandomData_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org00f2332"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex11RandomDataWithLabelLayoutStrategy_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgd06ae42"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex11RandomDataWithLabelLayoutStrategy_verticalBarChart_w150.png" alt="nil"/></a></td>
</tr>


<tr>
<td class="org-left"><a href="#org69cf24e"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex30AnimalsBySeasonWithLabelLayoutStrategy_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgf212270"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex30AnimalsBySeasonWithLabelLayoutStrategy_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org4e130c6"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex31SomeNegativeValues_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgc4c3f43"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex31SomeNegativeValues_verticalBarChart_w150.png" alt="nil"/></a></td>
</tr>


<tr>
<td class="org-left"><a href="#org18b9b8a"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex32AllPositiveYsYAxisStartsAbove0_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org335c5b0"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex32AllPositiveYsYAxisStartsAbove0_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org9deb58a"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex33AllNegativeYsYAxisEndsBelow0_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgb8eb7c3"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex35AnimalsBySeasonNoLabelsShown_lineChart_w150.png" alt="nil"/></a></td>
</tr>


<tr>
<td class="org-left"><a href="#orgba9b600"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex35AnimalsBySeasonNoLabelsShown_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#orgece23b5"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex40LanguagesWithYOrdinalUserLabelsAndUserColors_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org966fdea"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex50StocksWithNegativesWithUserColors_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org17dc892"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex52AnimalsBySeasonLogarithmicScale_lineChart_w150.png" alt="nil"/></a></td>
</tr>


<tr>
<td class="org-left"><a href="#orgf6276cd"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex52AnimalsBySeasonLogarithmicScale_verticalBarChart_w150.png" alt="nil"/></a></td>
<td class="org-left"><a href="#org9b555c9"><img src="https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/ex900ErrorFixUserDataAllZero_lineChart_w150.png" alt="nil"/></a></td>
<td class="org-left">&#xa0;</td>
<td class="org-left">&#xa0;</td>
</tr>
</tbody>
</table>


<a id="orga85576b"></a>

## ex10RandomData\_lineChart <a id="org5b3fdbd"></a>

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


<a id="org8039dc8"></a>

## ex10RandomData\_verticalBarChart <a id="org5418f4a"></a>

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


<a id="org9cc984a"></a>

## ex11RandomDataWithLabelLayoutStrategy\_lineChart <a id="org00f2332"></a>

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


<a id="org0257f0a"></a>

## ex11RandomDataWithLabelLayoutStrategy\_verticalBarChart <a id="orgd06ae42"></a>

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


<a id="org49e03da"></a>

## ex30AnimalsBySeasonWithLabelLayoutStrategy\_lineChart <a id="org69cf24e"></a>

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


<a id="orgbd3d2e6"></a>

## ex30AnimalsBySeasonWithLabelLayoutStrategy\_verticalBarChart <a id="orgf212270"></a>

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


<a id="orge024393"></a>

## ex31SomeNegativeValues\_lineChart <a id="org4e130c6"></a>

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


<a id="orgca0acaf"></a>

## ex31SomeNegativeValues\_verticalBarChart <a id="orgc4c3f43"></a>

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


<a id="orgf257df2"></a>

## ex32AllPositiveYsYAxisStartsAbove0\_lineChart <a id="org18b9b8a"></a>

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


<a id="org7340164"></a>

## ex32AllPositiveYsYAxisStartsAbove0\_verticalBarChart <a id="org335c5b0"></a>

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


<a id="orgdb72a53"></a>

## ex33AllNegativeYsYAxisEndsBelow0\_lineChart <a id="org9deb58a"></a>

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


<a id="org3c3f79a"></a>

## ex35AnimalsBySeasonNoLabelsShown\_lineChart <a id="orgb8eb7c3"></a>

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


<a id="org5c33865"></a>

## ex35AnimalsBySeasonNoLabelsShown\_verticalBarChart <a id="orgba9b600"></a>

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


<a id="org75e1070"></a>

## ex40LanguagesWithYOrdinalUserLabelsAndUserColors\_lineChart <a id="orgece23b5"></a>

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


<a id="org5ca70ba"></a>

## ex50StocksWithNegativesWithUserColors\_verticalBarChart <a id="org966fdea"></a>

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


<a id="org369cbfd"></a>

## ex52AnimalsBySeasonLogarithmicScale\_lineChart <a id="org17dc892"></a>

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


<a id="org9f514f4"></a>

## ex52AnimalsBySeasonLogarithmicScale\_verticalBarChart <a id="orgf6276cd"></a>

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


<a id="orga660e4f"></a>

## ex900ErrorFixUserDataAllZero\_lineChart <a id="org9b555c9"></a>

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


<a id="org6e7cb91"></a>

# Latest release changes

The latest release is 0.4.0

The <CHANGELOG.md> document describes new features and bug fixes in this and older versions.


<a id="orga756f82"></a>

# Installation


<a id="orgd4d6a89"></a>

## Installing flutter\_charts as a library package into your app

If you want to use the `flutter_charts` library package in your app, please follow instructions in <https://pub.dev/packages/flutter_charts/install>. This will result in ability of your app to use  `flutter_charts`.


<a id="org17224c8"></a>

## Installing the flutter\_charts project as a local clone from Github

The advantage of installing the source of the `flutter_charts` project locally from Github is that you can run the packaged example application and also run the integration and widget tests.

To install (clone) the `flutter_charts` project from Github to your local system, follow these steps:

-   Install Flutter, and items such as Android emulator. Instructions are on the Flutter website <https://docs.flutter.dev/get-started/install>.
-   Go to <https://github.com/mzimmerm/flutter_charts>, click on the "Code" button, and follow the instuctions to checkout flutter\_charts. A summary of one installation method (download method):
-   Click the "Download zip" link <https://github.com/mzimmerm/flutter_charts/archive/refs/heads/master.zip>
-   When prompted, save the file `flutter_charts-master.zip` one level above where you want the project. We will use `$HOME/dev`
-   Unzip the file `flutter_charts-master.zip`
-   The project will be in the `$HOME/dev/flutter_charts-master/` directory


<a id="org979d6b4"></a>

# Running the examples included in flutter\_charts

This section assumes you installed the flutter\_charts project as a local clone from Github, as described in [4](#org979d6b4)

There is an example application in flutter\_charts: `example1/lib/main.dart`. It shows how the Flutter Charts library can be included in a Flutter application.

To run the example application, Android emulator or iOS emulator need to be installed. You can use an IDE or command line. Instructions here are for the command line. Start in the unzipped directory, and follow the steps below:

-   Important: Make sure an Android or iOS emulator is running, or you have a physical device connected. See the [3.2](#org17224c8) section.
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


# Illustration of the "iterative auto layout" feature

This section illustrates how the auto layout behaves when less and less horizontal space is available to display the chart. 

Flutter chart library automatically checks for the X label overlap, and follows with rule-based iterative re-layout, to prevent labels running into each other.

To illustrate "stressed" horizontal space for the chart, we are gradually adding a text widget containing and increasing number of '<' characters on the right of the chart.


<a id="orga391b02"></a>

## Autolayout step 1

Let's say there are six labels on a chart, and there is sufficient space to display labels horizontally. The result may look like this:
We can see all x axis labels displayed it full, horizontally oriented.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-1.png)


<a id="orgf33a27c"></a>

## Autolayout step 2

Next, let us make less available space by taking away some space on the right with a wider text label such as '<<<<<<'
We can see the labels were automatically tilted by the angle `LabelLayoutStrategy.labelTiltRadians` for the labels to fit.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-2.png)


<a id="org4d9d6d5"></a>

## Autolayout step 3

Next, let us make even less available space by taking away some space on the right with a wider text label such as '<<<<<<<<<<<'.
We can see that labels are not only tilted, but also automatically skipped for labels not to overlap (every 2nd label is skipped, see option `ChartOptions.iterativeLayoutOptions.showEveryNthLabel`).

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-3.png)


<a id="org3d59435"></a>

## Autolayout step 4

Next, let us make even less available space some more compared to step 3, with even a wider text label such as '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'.
We can see even more labels were skipped for labels to prevent overlap, the chart is showing every 5th label.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-4.png)


<a id="orge8a31a7"></a>

## Autolayout step 5

Last, let us take away extreme amount of horizontal space by using '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<',
Here we can see the "default auto layout" finally gave up, and overlaps labels. Also, the legend is now hidded, as the amount of horizontal space is not sufficient.

![img](https://github.com/mzimmerm/flutter_charts/raw/master/doc/readme_images/README.org_iterative-layout-step-5.png)

![img](/doc/readme_images/README.org_iterative-layout-step-5.png)


<a id="orgd25de53"></a>

# Known packages, libraries and apps that use this flutter\_charts package

1.  Michael R. Fairhurst's **Language reader app** - see <https://github.com/MichaelRFairhurst/flutter-language-reader-app>


<a id="orge152000"></a>

# TODO Todos

1.  [X] During construction of DataRows, enforce default values of Legend names and colors for rows. This fixes issues such as <https://github.com/mzimmerm/flutter_charts/issues/18>, when users do not set them and expect (reasonably) a default chart to show anyway.
2.  [ ] Replace \`reduce(fn)\` with \`fold(initialValue, fn)\` throughout code to deal with exceptions when lists are empty.
3.  [X] Allow scaling y values using a function.


<a id="orge4e2be8"></a>

# Internal notes for exporting this document

1.  Before a release, run the following script to refresh the 'expected' screenshots. If the test `tool/demo/run_all_examples.sh` succeeds, it is quarenteed the 'expected' screenshots are same as those produced by the code in `example1/lib/main.dart`, which is used to generate code in this README file.

Convert all images to width=150  

    for file in doc/readme_images/ex*; do
        rm $file
    done
    for file in integration_test/screenshots_expected/ex*; do
        # cp $file doc/readme_images
        convert $file -resize 300 doc/readme_images/$(basename $file)
    done
    for file in doc/readme_images/ex*; do
        copy_name="$(basename $file)"
        copy_name="${copy_name/%.*/}"
        convert  $file -resize 150 $(dirname $file)/${copy_name}_w150.png
    done

1.  Before release, run once the script in heading [1](#org6344630). If generates examples from code. Should be run once, manually, before export to MD. Before export to MD, delete the line "RESULTS". The manually generated sections will be exported to MD during export. Before running again, delete the generated examples header sections, as they would accumulate. ALSO, make the table with small images 4 cells per row (do this by editing in text mode)

