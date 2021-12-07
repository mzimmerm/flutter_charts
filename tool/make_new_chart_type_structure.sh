#!/usr/bin/env bash

# Creates a set of directories and empty dart files for a new chart type.
echo Usage: $0 newChartType

chartType=${1:-UNSET}

if [[ -z "$chartType" ]]; then
  echo Invalid chartType="$chartType", exiting
  exit 1
fi

echo chartType = $chartType

mkdir {$chartType}

for file in \
  $chartType/chart.dart \
  $chartType/container.dart \
  $chartType/options.dart \
  $chartType/painter.dart  \
  $chartType/presenters.dart
do
  echo "" >> $file
done