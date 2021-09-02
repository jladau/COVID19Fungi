#!/bin/bash

sIODir=/home/jladau/Desktop/covid-19-microbiome/final-version/in-progress/hierarchical-partitioning-validation

cd $sIODir

for f in output-*.csv
do
	sOutputPath=`echo $f | sed "s|\.csv|\.xml|g"`
	bash /home/jladau/Desktop/research/Scripts/Utilities/UpdateGnumericGraph.sh /home/jladau/Desktop/covid-19-microbiome/final-version/in-progress/hierarchical-partitioning-validation/validation-output.xml $f $sOutputPath
done
