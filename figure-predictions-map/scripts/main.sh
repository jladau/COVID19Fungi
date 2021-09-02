#!/bin/bash
source $1

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

#outputting predicted 10th and 90th percentiles (EAW+E+AM)
sed "1 s|GROUP|GROUPX|g" $sTaxonGroupsSelectedTaxaPath > temp.1.csv
rm -f temp.2.db
sqlite3 temp.2.db ".import $sIODir/temp.1.csv tbl1"
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
	--rgdThresholds='10,90' \
	--dObservedValueThreshold='0.01'

#finding differences (degree of microbial constraint)
rm -f temp.6.db
sqlite3 temp.6.db ".import $sIODir/temp.5.csv tbl1"
sqlite3 temp.6.db "select SAMPLE_ID, PREDICTOR, RESPONSE, PREDICTION as PREDICTION_10 from tbl1 where cast(THRESHOLD as real)=10;" > temp.7.csv
sqlite3 temp.6.db "select SAMPLE_ID, PREDICTOR, RESPONSE, PREDICTION as PREDICTION_90 from tbl1 where cast(THRESHOLD as real)=90;" > temp.8.csv
joiner 'SAMPLE_ID,PREDICTOR,RESPONSE' temp.7.csv temp.8.csv > temp.9.csv
rm -f temp.10.db
sqlite3 temp.10.db ".import $sIODir/temp.9.csv tbl1"
sqlite3 temp.10.db "select SAMPLE_ID as COUNTY_FIPS, PREDICTOR as BETA_DIVERSITY, RESPONSE, PREDICTION_10, PREDICTION_90, 1/(cast(PREDICTION_90 as real)-cast(PREDICTION_10 as real)) as MICROBIAL_CONSTRAINT from tbl1;" > temp.11.csv

#appending latitudes and longitudes
joiner 'COUNTY_FIPS' $sPairedDataPath temp.11.csv > temp.6.csv
rm -f temp.7.db
sqlite3 temp.7.db ".import $sIODir/temp.6.csv tbl1"
sqlite3 temp.7.db "select SAMPLE_INDOOR as SAMPLE_ID, COUNTY_FIPS, BETA_DIVERSITY, RESPONSE as IFR_COUNTY, PREDICTION_10, PREDICTION_90, MICROBIAL_CONSTRAINT from tbl1 where not(MICROBIAL_CONSTRAINT='NA');" | sed "s|\r||g" > temp.8.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.BIOM.PrintMetadata.PrintMetadataLauncher \
	--sBIOMPath=$sBIOMPath \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
	--sAxis=sample \
	--sOutputPath=$sIODir/temp.9.csv \
	--sTaxonRank=$sTaxonRank
rm -f temp.10.db
sqlite3 temp.10.db ".import $sIODir/temp.9.csv tbl1"
sqlite3 temp.10.db "select sample as SAMPLE_ID, latitude as LATITUDE, longitude as LONGITUDE from tbl1;" | sed "s|\r||g" > temp.11.csv
joiner 'SAMPLE_ID' temp.8.csv temp.11.csv | grep -v "\,NA" > figure-prediction-map-data.csv

#cleaning up
rm temp.*.*
