#!/usr/bin/env bash

# Creates a set of directories and empty dart files for a new chart type.
echo Usage: $0 newChartType

chartType=${1:-UNSET}

echo chartType = $chartType

mkdir {$chartType}

for file in \
  $chartType/layouters.dart  \
  $chartType/chart.dart \
  $chartType/painter.dart  \
  $chartType/presenters.dart \
  $chartType/options.dart
do
  echo "" >> $file
done