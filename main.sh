#!/bin/bash

sIODir=`dirname $0`
sConfigPath=$sIODir/settings.config

source $sConfigPath

cd $sIODir

function runAnalysis {
	bash $sIODir/$1/scripts/main.sh $sConfigPath
	mkdir -p $sResultsDir/$1
	mv $sIODir/$1/*.* $sResultsDir/$1
}

#estimating infection fatality rates
runAnalysis ifr-estimation-johns-hopkins-through-february-2021

#estimating r0
runAnalysis r-naught-estimation

#compiling covid data
runAnalysis compile-covid-data

#creating taxon abbreviations
runAnalysis taxon-abbreviations

#finding list of paired samples with complete data
runAnalysis samples-with-complete-data

#finding taxon abundance and prevalence
runAnalysis taxon-abundance-prevalence

#generating simulated data for validating method
runAnalysis validation-data

#finding clusters of correlated taxa
runAnalysis taxon-correlation-clusters

#creating taxon groups map for all taxa
runAnalysis groups-map-all-taxa

#validation analysis for hierarchical partitioning method
runAnalysis hierarchical-partitioning-validation

#running hierarchical partitioning
runAnalysis hierarchical-partitioning

#running effects analysis looking at all subsets of genera selected by hierarchical partitioning
runAnalysis effects-and-interactions

#creating taxon groups map for selected taxa
runAnalysis groups-map-selected-taxa

#printing beta-diversity data
runAnalysis print-beta-diversity-data

#printing 2-d quantile regression data
runAnalysis 2d-quantile-regression-data

#creating example pairwise interaction graphs
runAnalysis figure-interaction-examples

#creating interaction network
runAnalysis figure-interaction-network

#creating interaction scatterplots
runAnalysis figure-interaction-scatterplot

#creating plot of ifr vs beta-diversity (including quantile predictions)
runAnalysis figure-ifr-vs-beta-diversity

#creating figure of ifr vs beta diversity significance (includes bootstrap output)
runAnalysis figure-ifr-vs-beta-diversity-significance

#creating figure showing trends in ifr vs beta-diversity relationship through time
runAnalysis figure-ifr-vs-beta-diversity-through-time

#creating hierarchical partitioning figure
runAnalysis figure-hierarchical-partitioning

#creating map of predicted range of ifr
runAnalysis figure-predictions-map

#creating map of population stability vs predictive power
runAnalysis figure-population-transience

#creating plots of numbers of tests vs population and number of cases
runAnalysis figure-tests-vs-population-cases

#creating plots showing importance of variables
runAnalysis variable-importance-figure

#ifr estimator validation
runAnalysis ifr-estimator-validation

#ifr estimator validation maps
runAnalysis ifr-estimator-validation-estimates

#hierarchical partitioning validation
runAnalysis figure-hierarchical-partitioning-validation
