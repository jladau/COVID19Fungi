#!/bin/bash
source $1

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

rgiStartRanks=(1 270)
rgiEndRanks=(269 539)

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

echo 'BOOTSTRAP_ID,RANK_START,RANK_END,THRESHOLD,OBSERVED,NULL_MEAN,NULL_STDEV,SES,PR_GTE,PR_LTE' > raw-output-data.csv
for i in $(seq 0 1)
do

	iStartRank=${rgiStartRanks[i]}
	iEndRank=${rgiEndRanks[i]}
	
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
	tail -n+2 temp.10.csv | sed "s|^|observation,$iStartRank,$iEndRank,|g" >> raw-output-data.csv
done

for k in {1..100}
do

	echo 'Bootstrap '$k' of 100...'
	java -cp $sJavaDir/Utilities.jar edu.ucsf.ResampleWithReplacement.ResampleWithReplacementLauncher \
		--sDataPath=$sPairedDataPath \
		--iRandomSeed=$(($k*7+1234)) \
		--sOutputPath=$sIODir/temp.29.csv
	sed -i "1 s|RESAMPLE_ID|SAMPLE_PAIR_ALIAS|g" temp.29.csv
	
	for i in $(seq 0 1)
	do

		iStartRank=${rgiStartRanks[i]}
		iEndRank=${rgiEndRanks[i]}
		
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
			--sResponseDataPath=$sIODir/temp.29.csv \
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
		tail -n+2 temp.10.csv | sed "s|^|bootstrap_$k,$iStartRank,$iEndRank,|g" >> raw-output-data.csv
	done
done

#formatting data for scatterplot
java -cp $sJavaDir/Utilities.jar edu.ucsf.AppendRandomNumbers.AppendRandomNumbersLauncher \
	--iRandomSeed=1234 \
	--sDataPath=$sIODir/raw-output-data.csv \
	--sOutputPath=$sIODir/temp.34.csv
rm -f temp.30.db
sqlite3 temp.30.db ".import $sIODir/temp.34.csv tbl1"
sqlite3 temp.30.db "select 0.2*cast(RANDOM_VALUE as real) + 0.9  as X_BOOTSTRAP_LOW, OBSERVED as BOOTSTRAP_LOW from tbl1 where BOOTSTRAP_ID like '%bootstrap%' and cast(RANK_START as real)>1 and cast(THRESHOLD as real)=75;" | sed "s|\r||g" > temp.31.csv
sqlite3 temp.30.db "select 0.2*cast(RANDOM_VALUE as real) + 1.9 as X_BOOTSTRAP_HIGH, OBSERVED as BOOTSTRAP_HIGH from tbl1 where BOOTSTRAP_ID like '%bootstrap%' and cast(RANK_START as real)=1 and cast(THRESHOLD as real)=75;" | sed "s|\r||g" > temp.32.csv
paste -d\, temp.31.csv temp.32.csv > temp.33.csv
sqlite3 temp.30.db "select '1' as X_OBSERVED_LOW, OBSERVED as OBSERVED_LOW from tbl1 where BOOTSTRAP_ID='observation' and cast(RANK_START as real)>1 and cast(THRESHOLD as real)=75;" | sed "s|\r||g" > temp.35.csv
sqlite3 temp.30.db "select '2' as X_OBSERVED_HIGH, OBSERVED as OBSERVED_HIGH from tbl1 where BOOTSTRAP_ID='observation' and cast(RANK_START as real)=1 and cast(THRESHOLD as real)=75;" | sed "s|\r||g" > temp.37.csv
paste -d\, temp.35.csv temp.37.csv > temp.38.csv
paste -d\, temp.33.csv temp.38.csv > temp.36.csv

#creating scatterplot
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/figure-population-transience-scatterplot-template.xml temp.36.csv figure-population-transience-scatterplot.xml

#finding values for first and last halves
echo 'IMMIGRATION_RANK,RANK_START,RANK_END,THRESHOLD,OBSERVED,NULL_MEAN,NULL_STDEV,SES,PR_GTE,PR_LTE' > temp.20.csv
rm -f temp.19.db
sqlite3 temp.19.db ".import $sIODir/raw-output-data.csv tbl1"
for i in {1..539}
do
	sqlite3 temp.19.db "select '$i' as IMMIGRATION_RANK, RANK_START, RANK_END, THRESHOLD, OBSERVED, NULL_MEAN, NULL_STDEV, SES, PR_GTE, PR_LTE from tbl1 where cast(RANK_START as real)<=$i and $i<=cast(RANK_END as real) and (cast(RANK_START as integer)=1 or cast(RANK_END as integer)=539) and BOOTSTRAP_ID='observation';" | tail -n+2 >> temp.20.csv
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

#cleaning up
rm temp.*.*
