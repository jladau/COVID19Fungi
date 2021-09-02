#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

bash $sIODir/scripts/format-data.sh $1
bash $sIODir/scripts/extract-data-windowed-summed.sh $1
bash $sIODir/scripts/run-analysis.sh $1
