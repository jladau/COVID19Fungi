#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

sStateDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/results-genus/ifr-estimation-johns-hopkins-through-february-2021/state-data.db
sCountyDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/results-genus/ifr-estimation-johns-hopkins-through-february-2021/county-data.db

cd $sIODir

function makeCountyEstimationGraphsAndMaps {
	
	sVar=$1
	sEst=$sVar'_ESTIMATE'
	sTrue=$sVar'_TRUE'
	sEstLog=$sVar'_ESTIMATE_LOG'
	sTrueLog=$sVar'_TRUE_LOG'
	sCv=$sVar'_CV'
	sCvLog=$sVar'_CV_LOG'
	sYLabel=$2
	
	sqlite3 estimator-validation-results.db "select *, (case when $sEst=0 then 'na' else log10($sEst) end) as $sEstLog, (case when $sTrue=0 then 'na' else log10($sTrue) end) as $sTrueLog from (select COUNTY_FIPS, STATE_FIPS, 'C-' || COUNTY_FIPS as FIPS_STRING, avg(cast($sEst as real)) as $sEst, avg(cast($sTrue as real)) as $sTrue from tbl1 where REGION='county' group by COUNTY_FIPS order by $sTrue);" > temp.14.csv
	joiner 'COUNTY_FIPS,STATE_FIPS,FIPS_STRING' county-estimates-observations.csv temp.14.csv | sponge county-estimates-observations.csv
	sed "s|sQuantityUC|$sYLabel|g" graph-templates/county-scatterplot-template.xml > temp.13.xml
	bash $sScriptsDir/UpdateGnumericGraph.sh temp.13.xml temp.14.csv county-${sVar,,}-estimates-vs-observations.xml

	#coefficient of variation
	#sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, STDEV/MEAN as $sCv from (select COUNTY_FIPS, STATE_FIPS, stdev(cast($sEst as real)) as STDEV, avg(cast($sTrue as real)) as MEAN from tbl1 where REGION='county' group by COUNTY_FIPS, STATE_FIPS);" > temp.12.csv
	sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, log10(STDEV/MEAN) as $sCvLog from (select COUNTY_FIPS, STATE_FIPS, stdev(cast($sEst as real)) as STDEV, avg(cast($sTrue as real)) as MEAN from tbl1 where REGION='county' group by COUNTY_FIPS, STATE_FIPS);" > temp.12.csv
	joiner 'COUNTY_FIPS,STATE_FIPS' county-coefficient-of-variation.csv temp.12.csv | sponge county-coefficient-of-variation.csv
}


function makeStateEstimationGraphsAndMaps {
	
	sVar=$1
	sEst=$sVar'_ESTIMATE'
	sTrue=$sVar'_TRUE'
	sEstLog=$sVar'_ESTIMATE_LOG'
	sTrueLog=$sVar'_TRUE_LOG'
	sCv=$sVar'_CV'
	sCvLog=$sVar'_CV_LOG'
	sYLabel=$2
	
	sqlite3 estimator-validation-results.db "select *, (case when $sEst=0 then 'na' else log10($sEst) end) as $sEstLog, (case when $sTrue=0 then 'na' else log10($sTrue) end) as $sTrueLog from (select STATE_FIPS, 'S-' || STATE_FIPS as FIPS_STRING, avg(cast($sEst as real)) as $sEst, avg(cast($sTrue as real)) as $sTrue from tbl1 where REGION='state' group by STATE_FIPS order by $sTrue);" > temp.14.csv
	joiner 'STATE_FIPS,FIPS_STRING' state-estimates-observations.csv temp.14.csv | sponge state-estimates-observations.csv
	sed "s|sQuantityUC|$sYLabel|g" graph-templates/state-scatterplot-template.xml > temp.13.xml
	bash $sScriptsDir/UpdateGnumericGraph.sh temp.13.xml temp.14.csv state-${sVar,,}-estimates-vs-observations.xml

	#coefficient of variation
	#sqlite3 estimator-validation-results.db "select STATE_FIPS, STDEV/MEAN as $sCv from (select STATE_FIPS, stdev(cast($sEst as real)) as STDEV, avg(cast($sTrue as real)) as MEAN from tbl1 where REGION='state' group by STATE_FIPS);" > temp.12.csv
	sqlite3 estimator-validation-results.db "select STATE_FIPS, log10(STDEV/MEAN) as $sCvLog from (select STATE_FIPS, stdev(cast($sEst as real)) as STDEV, avg(cast($sTrue as real)) as MEAN from tbl1 where REGION='state' group by STATE_FIPS);" > temp.12.csv
	joiner 'STATE_FIPS' state-coefficient-of-variation.csv temp.12.csv | sponge state-coefficient-of-variation.csv
}

echo 'STATE_FIPS,COUNTY_FIPS,VARIABLE,TIME,VALUE' > temp.1.csv

sqlite3 $sCountyDataPath "select STATE_FIPS, COUNTY_FIPS, VARIABLE, julianday(DATE)-0.5 as TIME, VALUE from tbl1 where STATE_FIPS in ('01', '02', '04', '05', '06', '08', '09', '10', '12', '13', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '44', '45', '46', '47', '48', '49', '50', '51', '53', '54', '55', '56') and VARIABLE='mortality' and $iTimeStart<=TIME and TIME<=$iTimeEnd and SMOOTHING='raw';" | tail -n+2 >> temp.1.csv

sqlite3 $sCountyDataPath "select STATE_FIPS, COUNTY_FIPS, VARIABLE, julianday(DATE)-0.5 as TIME, VALUE from tbl1 where STATE_FIPS in ('01', '02', '04', '05', '06', '08', '09', '10', '12', '13', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '44', '45', '46', '47', '48', '49', '50', '51', '53', '54', '55', '56') and VARIABLE='cases_observed' and $iTimeStart<=TIME and TIME<=$iTimeEnd and SMOOTHING='raw';" | tail -n+2 >> temp.1.csv

sqlite3 $sStateDataPath "select STATE_FIPS, 'NA' as COUNTY_FIPS, VARIABLE, julianday(DATE)-0.5 as TIME, VALUE from tbl1 where STATE_FIPS in ('01', '02', '04', '05', '06', '08', '09', '10', '12', '13', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '44', '45', '46', '47', '48', '49', '50', '51', '53', '54', '55', '56') and VARIABLE='tests' and $iTimeStart<=TIME and TIME<=$iTimeEnd and SMOOTHING='raw';" | tail -n+2 >> temp.1.csv

sed -i "s|\,|;|1" temp.1.csv
sed -i "s|\,|;|1" temp.1.csv

java -cp $sJavaDir/Utilities.jar edu.ucsf.TimeWindowSums.TimeWindowSumsLauncher \
	--sDataPath=$sIODir/temp.1.csv \
	--sCategory='STATE_FIPS;COUNTY_FIPS;VARIABLE' \
	--sValue=VALUE \
	--iStartTime=$iTimeStart \
	--iEndTime=$iTimeEnd \
	--iWindowSize=$iWindowSize \
	--sOutputPath=$sIODir/temp.2.csv
sed -i "s|\;|,|g" temp.2.csv

sqlite3 $sCountyDataPath "select STATE_FIPS, COUNTY_FIPS, VARIABLE, 'NA' as TIME, VALUE from tbl1 where STATE_FIPS in ('01', '02', '04', '05', '06', '08', '09', '10', '12', '13', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '44', '45', '46', '47', '48', '49', '50', '51', '53', '54', '55', '56') and VARIABLE='population' and not(COUNTY_FIPS like '%000') and SMOOTHING='raw';" | tail -n+2 >> temp.2.csv

#finding estimates
sStartDate='2020-03-01'
sEndDate='2020-10-31'
iStartTime=`sqlite3 temp.0.db "select cast(julianday('$sStartDate') as integer);" | tail -n+2 | sed "s|\r||g"`
iEndTime=`sqlite3 temp.0.db "select cast(julianday('$sEndDate') as integer);" | tail -n+2 | sed "s|\r||g"`
sOutputSuffix=$sStartDate'_'$sEndDate

java -cp $sJavaDir/Covid.jar gov.lbnl.Estimator.EstimatorLauncher \
	--sDataPath=$sIODir/temp.2.csv \
	--iRandomSeed=$((1234+i)) \
	--iStartTime=$iStartTime \
	--iEndTime=$iEndTime \
	--iWindowSize='-1' \
	--sMode=all_estimates \
	--sOutputPath=$sIODir/temp.3.csv \
	--bTimeIntegrated=true \
	--iIterations=100
	
rm -f temp.20.db
sqlite3 temp.20.db ".import $sIODir/temp.3.csv tbl1"
sqlite3 temp.20.db "select (case when (COUNTY_FIPS='NA' and STATE_FIPS='NA') then 'country' when (COUNTY_FIPS='NA' and not(STATE_FIPS='NA')) then 'state' else 'county' end) as REGION, * from tbl1;" > temp.21.csv
rm -f temp.22.db
sqlite3 temp.22.db ".import $sIODir/temp.21.csv tbl1"
sqlite3 temp.22.db "select REGION, VARIABLE, TYPE, avg(log10(cast(VALUE as real))) as LOG_MEAN from tbl1 where cast(VALUE as real)>0 group by REGION, VARIABLE, TYPE;" > mean-log-values.csv
joiner 'REGION,VARIABLE,TYPE' temp.21.csv temp.23.csv > temp.24.csv
rm -f temp.25.db
sqlite3 temp.25.db ".import $sIODir/temp.24.csv tbl1"
sqlite3 temp.25.db "select REGION, COUNTY_FIPS, STATE_FIPS, VARIABLE, TYPE, TIME, log10(cast(VALUE as real)) - cast(LOG_MEAN as real) as VALUE_CENTERED from tbl1 where cast(VALUE as real)>0;" > temp.26.csv
sqlite3 temp.25.db "select REGION, VARIABLE, TYPE, min(log10(cast(VALUE as real))) - cast(LOG_MEAN as real) as VALUE_CENTERED_MIN from tbl1 where cast(VALUE as real)>0 group by REGION, VARIABLE, TYPE;" > temp.27.csv
sqlite3 temp.25.db "select REGION, COUNTY_FIPS, STATE_FIPS, VARIABLE, TYPE, TIME from tbl1 where cast(VALUE as real)=0;" > temp.28.csv
joiner 'REGION,VARIABLE,TYPE' temp.28.csv temp.27.csv | tail -n+2 >> temp.26.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.FlatFileToPivotTable.FlatFileToPivotTableLauncher \
	--sDataPath=$sIODir/temp.26.csv \
	--sValueHeader=VALUE_CENTERED \
	--rgsExpandHeaders='VARIABLE,TYPE' \
	--sOutputPath=$sIODir/temp.4.csv

#outputting minimum and maximum values (for map scales)
sqlite3 temp.22.db "select REGION, VARIABLE, TYPE, min(log10(cast(VALUE as real))) as LOG_MIN, max(log10(cast(VALUE as real))) as LOG_MAX, (max(log10(cast(VALUE as real)))+min(log10(cast(VALUE as real))))/2 as LOG_MID from tbl1 where cast(VALUE as real)>0 and (REGION='county' or REGION='state') group by REGION, VARIABLE, TYPE;" > map-scale-bar-ranges.csv

s1=`head --lines=1 temp.4.csv | sed -e "s|VARIABLE\=||g" -e "s|TYPE\=||g" | sed "s|\;|_|g"`
echo ${s1^^} > temp.5.csv
tail -n+2 temp.4.csv | sed "s|\,null|\,NA|g" >> temp.5.csv

rm -f estimates-and-observations.db
sqlite3 estimates-and-observations.db ".import $sIODir/temp.5.csv tbl1"

#county mapping data
sqlite3 estimates-and-observations.db "select COUNTY_FIPS, STATE_FIPS, 
	CASES_OBSERVED_OBSERVATION as CASES_OBSERVATION_LOG_CENTERED, 
	CASES_TOTAL_ESTIMATE as INFECTIONS_ESTIMATE_LOG_CENTERED, 
	INFECTION_FATALITY_RATE_ESTIMATE as INFECTION_FATALITY_RATE_ESTIMATE_LOG_CENTERED, 
	MORTALITY_OBSERVATION as MORTALITY_OBSERVATION_LOG_CENTERED, 
	TESTS_ESTIMATE as TESTS_ESTIMATE_LOG_CENTERED 
	from tbl1 where REGION='county';" > county-mapping-data.csv
echo '"String","String","Real","Real","Real","Real","Real"' > county-mapping-data.csvt

sqlite3 estimates-and-observations.db "select STATE_FIPS, 
	CASES_OBSERVED_OBSERVATION as CASES_OBSERVATION_LOG_CENTERED, 
	CASES_TOTAL_ESTIMATE as INFECTIONS_ESTIMATE_LOG_CENTERED, 
	INFECTION_FATALITY_RATE_ESTIMATE as INFECTION_FATALITY_RATE_ESTIMATE_LOG_CENTERED, 
	MORTALITY_OBSERVATION as MORTALITY_OBSERVATION_LOG_CENTERED, 
	TESTS_OBSERVATION as TESTS_OBSERVATION_LOG_CENTERED 
	from tbl1 where COUNTY_FIPS='NA' and not(STATE_FIPS='NA');" > state-mapping-data.csv
echo '"String","Real","Real","Real","Real","Real"' > state-mapping-data.csvt

#cleaning up
rm temp.*.*
