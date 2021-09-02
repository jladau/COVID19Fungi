#!/bin/bash

source $1

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

sDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/results-genus/hierarchical-partitioning-validation/error-rates.csv

bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/error-rates-taxon-template.xml $sDataPath figure-error-rates-taxon.xml
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/error-rates-cluster-template.xml $sDataPath figure-error-rates-cluster.xml



