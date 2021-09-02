#!/bin/bash
source $1

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

#finding bootstrap resamples
echo 'BOOTSTRAP_ID,THRESHOLD,RANDOMIZATION,VALUE' > temp.6.csv
for i in {1..100}
do

	echo 'Bootstrap '$i' of 100...'

	java -cp $sJavaDir/Utilities.jar edu.ucsf.ResampleWithReplacement.ResampleWithReplacementLauncher \
		--sDataPath=$sPairedDataPath \
		--iRandomSeed=$(($i*7+1234)) \
		--sOutputPath=$sIODir/temp.1.csv
	sed -i "1 s|RESAMPLE_ID|SAMPLE_PAIR_ALIAS|g" temp.1.csv
	
	#finding bootstrap significance values
	java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
		--sRegressionType=windowed_quantile \
		--bRemoveUnclassified=true \
		--sMode=significance_slope \
		--sOutputPath=$sIODir/temp.5.csv \
		--iWindowSize=20 \
		--sMetric=bray_curtis \
		--sTaxonRank=$sTaxonRank \
		--iPartitioningOrders=$iOrderingsHierarchical \
		--iNullIterations=0 \
		--sBIOMPath=$sBIOMPath \
		--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
		--sSample1Header=SAMPLE_INDOOR \
		--sSample2Header=SAMPLE_OUTDOOR \
		--sResponse=IFR_COUNTY \
		--sMergeHeader=COUNTY_FIPS \
		--sTaxonGroupsMapPath=$sTaxonGroupsAllTaxaPath \
		--rgdThresholds='10,12.5,15,17.5,20,22.5,25,27.5,30,32.5,35,37.5,40,42.5,45,47.5,50,52.5,55,57.5,60,62.5,65,67.5,70,72.5,75,77.5,80,82.5,85,87.5,90' \
		--dObservedValueThreshold='0.01' \
		--bRange=false	\
		--sResponseDataPath=$sIODir/temp.1.csv		
	tail -n+2 temp.5.csv | sed "s|^|bootstrap_$i\,|g" >> temp.6.csv
done

#finding observed values
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=significance_slope \
	--sOutputPath=$sIODir/temp.5.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=$iOrderingsHierarchical \
	--iNullIterations=0 \
	--sBIOMPath=$sBIOMPath \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sTaxonGroupsAllTaxaPath \
	--rgdThresholds='10,12.5,15,17.5,20,22.5,25,27.5,30,32.5,35,37.5,40,42.5,45,47.5,50,52.5,55,57.5,60,62.5,65,67.5,70,72.5,75,77.5,80,82.5,85,87.5,90' \
	--dObservedValueThreshold='0.01' \
	--bRange=false	\
	--sResponseDataPath=$sPairedDataPath
tail -n+2 temp.5.csv | sed "s|^|observation,|g" >> temp.6.csv

#converting to histogram
rm -f temp.7.db
sqlite3 temp.7.db ".import $sIODir/temp.6.csv tbl1"
sqlite3 temp.7.db "select THRESHOLD as THRESHOLD_BOOTSTRAP, 1*cast(VALUE as real) as VALUE_BOOTSTRAP from tbl1 where not(BOOTSTRAP_ID='observation');" > temp.8.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.TwoDimensionalHistogram.TwoDimensionalHistogramLauncher \
	--sDataPath=$sIODir/temp.8.csv \
	--sXHeader=THRESHOLD_BOOTSTRAP \
	--sYHeader=VALUE_BOOTSTRAP \
	--dDistanceThreshold='0.1' \
	--sOutputPath=$sIODir/temp.9.csv \
	--rgsCategories=THRESHOLD_BOOTSTRAP
java -cp $sJavaDir/Utilities.jar edu.ucsf.IdenticalObservationNoise.IdenticalObservationNoiseLauncher \
	--sDataPath=$sIODir/temp.9.csv \
	--sCategoryHeader=THRESHOLD_BOOTSTRAP \
	--sValueHeader=THRESHOLD_BOOTSTRAP \
	--dOffset='5' \
	--sOutputPath=$sIODir/temp.9.csv
sqlite3 temp.7.db "select THRESHOLD as THRESHOLD_OBSERVED, 1*cast(VALUE as real) as VALUE_OBSERVED from tbl1 where BOOTSTRAP_ID='observation';" > temp.10.csv
paste -d\, <(cut -d\, -f2- temp.9.csv) <(cat temp.10.csv) > temp.11.csv

#finding significance
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=significance_slope \
	--sOutputPath=$sIODir/temp.12.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=$iOrderingsHierarchical \
	--iNullIterations=1000 \
	--sBIOMPath=$sBIOMPath \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
	--sResponseDataPath=$sPairedDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sTaxonGroupsAllTaxaPath \
	--rgdThresholds='10,12.5,15,17.5,20,22.5,25,27.5,30,32.5,35,37.5,40,42.5,45,47.5,50,52.5,55,57.5,60,62.5,65,67.5,70,72.5,75,77.5,80,82.5,85,87.5,90' \
	--dObservedValueThreshold='0.01' \
	--bRange=false
	
java -cp $sJavaDir/Utilities.jar edu.ucsf.StandardizedEffectSizes.StandardizedEffectSizesLauncher \
	--sDataPath=$sIODir/temp.12.csv \
	--rgsCategoryHeaders=THRESHOLD \
	--sValueHeader=VALUE \
	--sRandomizationHeader=RANDOMIZATION \
	--iNullIterations=1000 \
	--sOutputPath=$sIODir/temp.13.csv

#finding observations with ses greater than 3
rm -f temp.14.db
sqlite3 temp.14.db ".import $sIODir/temp.13.csv tbl1"
sqlite3 temp.14.db "select THRESHOLD, 1*cast(OBSERVED as real) as OBSERVED_SES_GT_3 from tbl1 where cast(SES as real)>3;" > temp.15.csv
paste -d\, <(sed "s|\r||g" temp.11.csv) temp.15.csv > temp.16.csv

#creating graph
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/figure-ifr-vs-beta-diversity-significance-template.xml temp.16.csv figure-ifr-vs-beta-diversity-significance.xml

#cleaning up
rm temp.*.*
