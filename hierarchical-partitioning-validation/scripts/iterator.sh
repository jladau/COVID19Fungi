#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1
iValidationDataSetID=$2
sResponseDataPath=$sValidationDataDir/simulated-correlated-response-data-$iValidationDataSetID.csv

cd $sIODir

#running partitioning
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=hierarchical_partitioning \
	--sOutputPath=$sIODir/temp.2.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=$iOrderingsHierarchical \
	--iNullIterations=$iNullIterationsHierarchical \
	--sBIOMPath=$sBIOMPath \
	--sResponseDataPath=$sResponseDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sTaxonGroupsAllTaxaPath \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'

#calculating significance and standardized effect sizes
java -cp $sJavaDir/Utilities.jar edu.ucsf.StandardizedEffectSizes.StandardizedEffectSizesLauncher \
	--sDataPath=$sIODir/temp.2.csv \
	--rgsCategoryHeaders=TAXON \
	--sValueHeader=MARGINAL_PERFORMANCE_INCREASE \
	--sRandomizationHeader=INITIAL_RANDOMIZATION \
	--iNullIterations=$iNullIterationsHierarchical \
	--sOutputPath=$sIODir/standardized-effect-sizes-$iValidationDataSetID.csv
