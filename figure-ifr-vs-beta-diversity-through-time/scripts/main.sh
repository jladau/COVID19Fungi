#!/bin/bash
source $1

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

#finding values
echo 'DATE_START,DATE_END,THRESHOLD,RANDOMIZATION,VALUE' > temp.2.csv
for i in {0..9}
do
	sStartDate=${rgsIFRBetaStartDates[i]}
	sEndDate=${rgsIFRBetaEndDates[i]}
	sDataPath=$sPairedDataDir/compiled-covid-data-$sStartDate'_'$sEndDate-paired.csv
	java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
		--sRegressionType=windowed_quantile \
		--bRemoveUnclassified=true \
		--sMode=significance_slope \
		--sOutputPath=$sIODir/temp.1.csv \
		--iWindowSize=20 \
		--sMetric=bray_curtis \
		--sTaxonRank=$sTaxonRank \
		--iPartitioningOrders=$iOrderingsHierarchical \
		--iNullIterations=$iNullIterationsHierarchical \
		--sBIOMPath=$sBIOMPath \
		--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
		--sResponseDataPath=$sDataPath \
		--sSample1Header=SAMPLE_INDOOR \
		--sSample2Header=SAMPLE_OUTDOOR \
		--sResponse=IFR_COUNTY \
		--sMergeHeader=COUNTY_FIPS \
		--sTaxonGroupsMapPath=$sTaxonGroupsAllTaxaPath \
		--rgdThresholds='10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90' \
		--dObservedValueThreshold='0.01' \
		--bRange=false
	tail -n+2 temp.1.csv | sed "s|^|$sStartDate,$sEndDate,|g" >> temp.2.csv
done

#finding significance
java -cp $sJavaDir/Utilities.jar edu.ucsf.StandardizedEffectSizes.StandardizedEffectSizesLauncher \
	--sDataPath=$sIODir/temp.2.csv \
	--rgsCategoryHeaders='DATE_START,DATE_END,THRESHOLD' \
	--sValueHeader=VALUE \
	--sRandomizationHeader=RANDOMIZATION \
	--iNullIterations=$iNullIterationsHierarchical \
	--sOutputPath=$sIODir/temp.3.csv
	
#selecting observations that are significant
rm -f temp.4.db
sqlite3 temp.4.db ".import $sIODir/temp.3.csv tbl1"
sqlite3 temp.4.db "select DATE_START as DATE_START_SIGNIFICANT, THRESHOLD as THRESHOLD_SIGNIFICANT from tbl1 where cast(SES as real)>2;" > temp.5.csv
paste -d\, temp.3.csv temp.5.csv > temp.6.csv

#creating graph
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/figure-ifr-vs-beta-diversity-through-time-template.xml temp.6.csv figure-ifr-vs-beta-diversity-through-time.xml

#cleaning up
rm temp.*.*
