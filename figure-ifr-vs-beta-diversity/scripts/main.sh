#!/bin/bash
source $1

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

sed "1 s|GROUP|GROUPX|g" $sTaxonGroupsSelectedTaxaPath > temp.1.csv
rm -f temp.2.db
sqlite3 temp.2.db ".import $sIODir/temp.1.csv tbl1"

#outputting predictions: EAW+E+AM, quantile
sqlite3 temp.2.db "select * from tbl1 where TAXON_ID_SHORT in ('uni1835', 'Alt29', 'Asp109', 'Eur511', 'Wal1582', 'Epi494');" > temp.3.csv
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_predicted_values \
	--sOutputPath=$sIODir/temp.5.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=$iOrderingsHierarchical \
	--iNullIterations=$iNullIterationsHierarchical \
	--sBIOMPath=$sBIOMPath \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
	--sResponseDataPath=$sPairedDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sIODir/temp.3.csv \
	--rgdThresholds='10,25,50,75,90' \
	--dObservedValueThreshold='0.01'
rm -f temp.8.db
sqlite3 temp.8.db ".import $sIODir/temp.5.csv tbl1"
sqlite3 temp.8.db "select THRESHOLD, min(cast(PREDICTOR as real))-0.02 as PREDICTOR, 1*cast(PREDICTION as real) from tbl1 group by THRESHOLD;" > temp.9.csv
sqlite3 temp.8.db "select THRESHOLD, max(cast(PREDICTOR as real))+0.02 as PREDICTOR, 1*cast(PREDICTION as real) from tbl1 group by THRESHOLD;" | tail -n+2 >> temp.9.csv
rm -f temp.10.db
sqlite3 temp.10.db ".import $sIODir/temp.9.csv tbl1"
sqlite3 temp.10.db "select * from tbl1 order by cast(THRESHOLD as real), cast(PREDICTOR as real);" > temp.11.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.EmptyRowsBetweenCategories.EmptyRowsBetweenCategoriesLauncher \
	--sCategoryField=THRESHOLD \
	--sDataPath=$sIODir/temp.11.csv \
	--sOutputPath=$sIODir/temp.11.csv

#outputting merged data
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_data_merged \
	--sOutputPath=$sIODir/temp.6.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=$iOrderingsHierarchical \
	--iNullIterations=$iNullIterationsHierarchical \
	--sBIOMPath=$sBIOMPath \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
	--sResponseDataPath=$sPairedDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sIODir/temp.3.csv \
	--rgdThresholds='10,25,50,75,90' \
	--dObservedValueThreshold='0.01'
java -cp $sJavaDir/Utilities.jar edu.ucsf.TwoDimensionalHistogram.TwoDimensionalHistogramLauncher \
	--sDataPath=$sIODir/temp.6.csv \
	--sXHeader=BETA_DIVERSITY \
	--sYHeader=RESPONSE \
	--dDistanceThreshold='0.1' \
	--sOutputPath=$sIODir/temp.7.csv
rm -f temp.13.db
sqlite3 temp.13.db ".import $sIODir/temp.7.csv tbl1"
sqlite3 temp.13.db "select BETA_DIVERSITY, 1*cast(RESPONSE as real) as INFECTION_FATALITY_RATE, FREQUENCY from tbl1;" | sed "s|\r||g" > temp.7.csv

paste -d\, temp.7.csv temp.11.csv > temp.12.csv

#creating graph
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/figure-ifr-vs-beta-diversity-template.xml temp.12.csv figure-ifr-vs-beta-diversity.xml

#cleaning up
rm temp.*.*

