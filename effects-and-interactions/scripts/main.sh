#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

#making groups file
sed "1 s|CLUSTER|GROUP|g" $sSelectedClustersPath | sed -e "1 s|$|,INCLUDE|g" -e "2,$ s|$|,true|g" | sed "s|\;\ |;|g" > temp.12.csv
joiner 'TAXON_ID_SHORT' temp.12.csv $sTaxonAbbreviationsPath > temp.13.csv

#running partitioning
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=effects \
	--sOutputPath=$sIODir/temp.2.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=$iOrderingsHierarchical \
	--iNullIterations=100 \
	--sBIOMPath=$sBIOMPath \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
	--sResponseDataPath=$sPairedDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sIODir/temp.13.csv \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'

#calculating significance and standardized effect sizes
java -cp $sJavaDir/Utilities.jar edu.ucsf.StandardizedEffectSizes.StandardizedEffectSizesLauncher \
	--sDataPath=$sIODir/temp.2.csv \
	--rgsCategoryHeaders='TAXA,NUMBER_INDIVIDUAL_TAXA,REMAINING_COMMUNITY' \
	--sValueHeader=PERFORMANCE \
	--sRandomizationHeader=RANDOMIZATION \
	--iNullIterations=100 \
	--sOutputPath=$sIODir/temp.19.csv

#finding interactions
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=two_factor_interactions \
	--sOutputPath=$sIODir/temp.17.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=$iOrderingsHierarchical \
	--iNullIterations=100 \
	--sBIOMPath=$sBIOMPath \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
	--sResponseDataPath=$sPairedDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sIODir/temp.13.csv \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'

#creating interactions database
java -cp $sJavaDir/Utilities.jar edu.ucsf.StandardizedEffectSizes.StandardizedEffectSizesLauncher \
	--sDataPath=$sIODir/temp.17.csv \
	--rgsCategoryHeaders='FACTOR_1,FACTOR_2,FACTOR_1_SIZE,FACTOR_2_SIZE' \
	--sValueHeader=INTERACTION \
	--sRandomizationHeader=RANDOMIZATION \
	--iNullIterations=100 \
	--sOutputPath=$sIODir/temp.21.csv
rm -f interactions.db
sqlite3 interactions.db ".import $sIODir/temp.21.csv tbl1"

#creating effects database
echo 'none,0,false,0,0,0,na,1,1' >> temp.19.csv
rm -f effects.db
sqlite3 effects.db ".import $sIODir/temp.19.csv tbl1"

rm temp.*.*
