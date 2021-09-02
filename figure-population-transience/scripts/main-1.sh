#!/bin/bash
source $1

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

#rgiStartRanks=(0 100 200 300 400)
#rgiEndRanks=(100 200 300 400 500)

rgiStartRanks=(0 330)
rgiEndRanks=(209 539)


sCensusDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/in-progress/population-transience/raw-data/co-est2019-alldata.csv

<<COMMENT0

#finding per-county population trends
rm -f temp.1.db
sqlite3 temp.1.db ".import $sCensusDataPath tbl1"
sqlite3 temp.1.db "select STATE || COUNTY as COUNTY_FIPS, RNETMIG2011, RNETMIG2012, RNETMIG2013, RNETMIG2014, RNETMIG2015, RNETMIG2016, RNETMIG2017, RNETMIG2018, RNETMIG2019 from tbl1;" > temp.2.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.PivotTableToFlatFile.PivotTableToFlatFileLauncher \
	--sDataPath=$sIODir/temp.2.csv \
	--lstColumnsNotToFlatten=COUNTY_FIPS \
	--sOutputPath=$sIODir/temp.3.csv
sed -i "1 s|FLAT_VAR_KEY\,FLAT_VAR_VALUE|VARIABLE,VALUE|g" temp.3.csv
rm -f temp.4.db
sqlite3 temp.4.db ".import $sIODir/temp.3.csv tbl1"

#loading database with measures of growth
sqlite3 temp.4.db "select COUNTY_FIPS, sum(VALUE_SIGN) as COUNT_YEARS_POSITIVE_GROWTH, avg(VALUE) as GROWTH_MEAN, median(VALUE) as GROWTH_MEDIAN from (select COUNTY_FIPS, cast(VALUE as real) as VALUE, (case when cast(VALUE as real)>0 then 1 else 0 end) as VALUE_SIGN from tbl1) group by COUNTY_FIPS;" > temp.5.csv
joiner 'COUNTY_FIPS' $sPairedDataPath temp.5.csv | grep -v "\,NA" > temp.6.csv
rm -f temp.7.db
sqlite3 temp.7.db ".import $sIODir/temp.6.csv tbl1"
sqlite3 temp.7.db "select SAMPLE_INDOOR as SAMPLE_ID, COUNTY_FIPS, COUNT_YEARS_POSITIVE_GROWTH, GROWTH_MEAN, GROWTH_MEDIAN from tbl1;" > temp.8.csv
sqlite3 temp.7.db "select SAMPLE_OUTDOOR as SAMPLE_ID, COUNTY_FIPS, COUNT_YEARS_POSITIVE_GROWTH, GROWTH_MEAN, GROWTH_MEDIAN from tbl1;" | tail -n+2 >> temp.8.csv
rm -f temp.11.db
sqlite3 temp.11.db ".import $sIODir/temp.8.csv tbl1"


COMMENT0

#making groups file

#sed "1 s|CLUSTER|GROUP|g" $sSelectedClustersPath | sed -e "1 s|$|,INCLUDE|g" -e "2,$ s|$|,true|g" | sed "s|\;\ |;|g" > temp.12.csv
#joiner 'TAXON_ID_SHORT' temp.12.csv $sTaxonAbbreviationsPath > temp.13.csv

cp $sTaxonGroupsAllTaxaPath temp.13.csv


#ranking counties by growth
sqlite3 temp.11.db "select COUNTY_FIPS, rank() over (order by GROWTH_MEDIAN desc) as GROWTH_RANK from (select distinct COUNTY_FIPS, cast(GROWTH_MEDIAN as real) as GROWTH_MEDIAN from tbl1);" > temp.14.csv
joiner 'COUNTY_FIPS' temp.8.csv temp.14.csv > temp.15.csv
rm -f temp.16.db
sqlite3 temp.16.db ".import $sIODir/temp.15.csv tbl1"

#echo 'RANK_START,RANK_END,THRESHOLD,OBSERVED,NULL_MEAN,NULL_STDEV,SES,PR_GTE,PR_LTE' > temp.18.csv
rm -f temp.18.csv
for i in {0..1}
do

	iStartRank=${rgiStartRanks[i]}
	iEndRank=${rgiEndRanks[i]}
	
	sqlite3 temp.16.db "select SAMPLE_ID from tbl1 where cast(GROWTH_RANK as integer)>=$iStartRank and cast(GROWTH_RANK as integer)<$iEndRank;" > temp.17.csv
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
		--rgdThresholds='75' \
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
