#!/bin/bash
source $1

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

sed "1 s|GROUP|GROUPX|g" $sTaxonGroupsSelectedTaxaPath > temp.1.csv
rm -f temp.2.db
sqlite3 temp.2.db ".import $sIODir/temp.1.csv tbl1"

#outputting data: transformed, EAW+E+AM
sqlite3 temp.2.db "select * from tbl1 where TAXON_ID_SHORT in ('uni1835', 'Alt29', 'Asp109', 'Eur511', 'Wal1582', 'Epi494');" > temp.3.csv
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_transformed_data \
	--sOutputPath=$sIODir/temp.4.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=$iOrderingsHierarchical \
	--iNullIterations=$iNullIterationsHierarchical \
	--sBIOMPath=$sBIOMPath \
	--sResponseDataPath=$sPairedDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sIODir/temp.3.csv \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'
	
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_predicted_values \
	--sOutputPath=$sIODir/temp.6.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=$iOrderingsHierarchical \
	--iNullIterations=$iNullIterationsHierarchical \
	--sBIOMPath=$sBIOMPath \
	--sResponseDataPath=$sPairedDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sIODir/temp.3.csv \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'

paste -d\, temp.4.csv temp.6.csv | sed "s|^\,|,,,|g" > temp.8.csv

#outputting data: transformed, T
sqlite3 temp.2.db "select * from tbl1 where TAXON_ID_SHORT='Tox1500';" > temp.3.csv
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_transformed_data \
	--sOutputPath=$sIODir/temp.5.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=$iOrderingsHierarchical \
	--iNullIterations=$iNullIterationsHierarchical \
	--sBIOMPath=$sBIOMPath \
	--sResponseDataPath=$sPairedDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sIODir/temp.3.csv \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'
	
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/interaction-scatterplot-trend-template.xml temp.8.csv figure-interaction-scatterplot-EAW+E+AM.xml
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/interaction-scatterplot-no-trend-template.xml temp.5.csv figure-interaction-scatterplot-T.xml
	
rm temp.*.*
