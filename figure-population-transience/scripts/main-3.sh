#!/bin/bash
source $1

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

#TODO moving window of start and end ranks -- then take average effect for each point (within windows)

iTotalObservations=539

#rgiStartRanks=(1 270)
#rgiEndRanks=(269 539)

#sCensusDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/in-progress/population-transience/raw-data/co-est2019-alldata.csv
sMigrationDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/in-progress/population-transience/raw-data/CtyxCty_US.txt

<<COMMENT0

#formatting migration data
cat $sMigrationDataPath | sed "s|\ \ |+|g" | tr -s '+' | sed "s|\+\ |+|g" | sed "s|\+|,|g" | sed "s|\ |,|1" > temp.1.csv
paste -d\, <(cut -c1-6 temp.1.csv) <(cut -d\, -f32 temp.1.csv) | cut -c1- | sed "1 s|^|COUNTY_FIPS,IMMIGRATION_RAW\n|g" > temp.2.csv

#finding total immigration for each county
rm -f temp.3.db
sqlite3 temp.3.db ".import $sIODir/temp.2.csv tbl1"
sqlite3 temp.3.db "select substr(COUNTY_FIPS,2,7) as COUNTY_FIPS, sum(cast(IMMIGRATION_RAW as integer)) as IMMIGRATION_RAW from tbl1 group by COUNTY_FIPS;" > temp.4.csv

#normalizing immigration by population
cut -d\, -f4,5,14  $sStatePopulationDataPath | tail -n+2 | sed "1 s|^|COUNTY_FIPS,POPULATION_2014\n|g" | sed "2,$ s|\,||1" > temp.5.csv
joiner 'COUNTY_FIPS' temp.4.csv temp.5.csv > temp.6.csv
rm -f temp.7.db
sqlite3 temp.7.db ".import $sIODir/temp.6.csv tbl1"
sqlite3 temp.7.db "select *, cast(IMMIGRATION_RAW as real)/cast(POPULATION_2014 as real) as IMMIGRATION_RATE from tbl1;" > temp.8.csv

#creating database
joiner 'COUNTY_FIPS' $sPairedDataPath temp.8.csv | grep -v "\,NA" > temp.6.csv
rm -f temp.7.db
sqlite3 temp.7.db ".import $sIODir/temp.6.csv tbl1"
sqlite3 temp.7.db "select SAMPLE_INDOOR as SAMPLE_ID, COUNTY_FIPS, IMMIGRATION_RATE from tbl1;" > temp.9.csv
sqlite3 temp.7.db "select SAMPLE_OUTDOOR as SAMPLE_ID, COUNTY_FIPS, IMMIGRATION_RATE from tbl1;" | tail -n+2 >> temp.9.csv
rm -f temp.11.db
sqlite3 temp.11.db ".import $sIODir/temp.9.csv tbl1"

#making groups file
cp $sTaxonGroupsAllTaxaPath temp.13.csv

#ranking counties by growth
sqlite3 temp.11.db "select COUNTY_FIPS, rank() over (order by IMMIGRATION_RATE asc) as IMMIGRATION_RANK from (select distinct COUNTY_FIPS, cast(IMMIGRATION_RATE as real) as IMMIGRATION_RATE from tbl1);" > temp.14.csv
joiner 'COUNTY_FIPS' temp.9.csv temp.14.csv > temp.15.csv
rm -f temp.16.db
sqlite3 temp.16.db ".import $sIODir/temp.15.csv tbl1"

echo 'RANK_START,RANK_END,THRESHOLD,OBSERVED,NULL_MEAN,NULL_STDEV,SES,PR_GTE,PR_LTE' > temp.18.csv
#for i in $(seq 1 10 290)
for i in $(seq 0 5 270)
do

	iStartRank=$i
	iEndRank=$((i+269))
	
	echo 'Analyzing observations '$iStartRank' to '$iEndRank'...'
	
	sqlite3 temp.16.db "select SAMPLE_ID from tbl1 where cast(IMMIGRATION_RANK as integer)>=$iStartRank and cast(IMMIGRATION_RANK as integer)<$iEndRank;" > temp.17.csv
	java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
		--sRegressionType=windowed_quantile \
		--bRemoveUnclassified=true \
		--sMode=significance \
		--sOutputPath=$sIODir/temp.9.csv \
		--iWindowSize=20 \
		--sMetric=bray_curtis \
		--sTaxonRank=genus \
		--iPartitioningOrders=$iOrderingsHierarchical \
		--iNullIterations=$iNullIterationsHierarchical \
		--sBIOMPath=$sBIOMPath \
		--sResponseDataPath=$sPairedDataPath \
		--sSample1Header=SAMPLE_INDOOR \
		--sSample2Header=SAMPLE_OUTDOOR \
		--sResponse=IFR_COUNTY \
		--sMergeHeader=COUNTY_FIPS \
		--sTaxonGroupsMapPath=$sIODir/temp.13.csv \
		--rgdThresholds='50,55,60,65,70,75,80,85,90,95' \
		--dObservedValueThreshold='0.01' \
		--sSamplesToKeepPath=$sIODir/temp.17.csv
	java -cp $sJavaDir/Utilities.jar edu.ucsf.StandardizedEffectSizes.StandardizedEffectSizesLauncher \
		--sDataPath=$sIODir/temp.9.csv \
		--rgsCategoryHeaders=THRESHOLD \
		--sValueHeader=VALUE \
		--sRandomizationHeader=RANDOMIZATION \
		--iNullIterations=$iNullIterationsHierarchical \
		--sOutputPath=$sIODir/temp.10.csv
	tail -n+2 temp.10.csv | sed "s|^|$iStartRank,$iEndRank,|g" >> temp.18.csv
done

COMMENT0

#creating data for scatterplot
joiner 'IMMIGRATION_RANK' temp.18.csv temp.15.csv > temp.28.csv

exit

#finding values for first and last halves
echo 'IMMIGRATION_RANK,RANK_START,RANK_END,THRESHOLD,OBSERVED,NULL_MEAN,NULL_STDEV,SES,PR_GTE,PR_LTE' > temp.20.csv
rm -f temp.19.db
sqlite3 temp.19.db ".import $sIODir/temp.18.csv tbl1"
for i in {1..539}
do
	sqlite3 temp.19.db "select '$i' as IMMIGRATION_RANK, * from tbl1 where cast(RANK_START as real)<=$i and $i<=cast(RANK_END as real) and (cast(RANK_START as integer)=0 or cast(RANK_END as integer)=539);" | tail -n+2 >> temp.20.csv
done

rm -f temp.21.db
sqlite3 temp.21.db ".import $sIODir/temp.20.csv tbl1"
sqlite3 temp.21.db "select IMMIGRATION_RANK, THRESHOLD, OBSERVED, SES from tbl1;" > temp.22.csv 
joiner 'IMMIGRATION_RANK' temp.22.csv temp.15.csv > temp.23.csv

#joining latitudes and longitudes
java -cp $sJavaDir/Utilities.jar edu.ucsf.BIOM.PrintMetadata.PrintMetadataLauncher \
	--sBIOMPath=$sBIOMPath \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
	--sAxis=sample \
	--sOutputPath=$sIODir/temp.24.csv \
	--sTaxonRank=$sTaxonRank
rm -f temp.10.db
sqlite3 temp.10.db ".import $sIODir/temp.24.csv tbl1"
sqlite3 temp.10.db "select sample as SAMPLE_ID, latitude as LATITUDE, longitude as LONGITUDE from tbl1;" | sed "s|\r||g" > temp.25.csv
joiner 'SAMPLE_ID' temp.23.csv temp.25.csv | grep -v "\,NA" > temp.26.csv

rm -f temp.27.db
sqlite3 temp.27.db ".import $sIODir/temp.26.csv tbl1"
sqlite3 temp.27.db "select SAMPLE_ID, COUNTY_FIPS, LATITUDE, LONGITUDE, IMMIGRATION_RATE, OBSERVED, THRESHOLD from tbl1;" > temp.27.csv

java -cp $sJavaDir/Utilities.jar edu.ucsf.FlatFileToPivotTable.FlatFileToPivotTableLauncher \
	--sDataPath=$sIODir/temp.27.csv \
	--sValueHeader=OBSERVED \
	--rgsExpandHeaders=THRESHOLD \
	--sOutputPath=$sIODir/population-transience-data.csv
	
sed -i -e "1 s|THRESHOLD\=|THRESHOLD_|g" -e "1 s|\.0||g" population-transience-data.csv
