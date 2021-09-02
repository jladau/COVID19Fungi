#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

sStateDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/results-genus/ifr-estimation-johns-hopkins-through-february-2021/state-data.db
sCountyDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/results-genus/ifr-estimation-johns-hopkins-through-february-2021/county-data.db

cd $sIODir

function makeCountyCaseGraphs {

	sEstVar=$1
	sEst=$sEstVar'_TRUE'
	sEstLog=$sEstVar'_TRUE_LOG'
	sTrueVar=$2
	sTrue=$sTrueVar'_TRUE'
	sTrueLog=$sTrueVar'_TRUE_LOG'
	sYLabel=$3

	sqlite3 estimator-validation-results.db "select *, (case when $sEst=0 then 'na' else log10($sEst) end) as $sEstLog, (case when $sTrue=0 then 'na' else log10($sTrue) end) as $sTrueLog from (select COUNTY_FIPS, STATE_FIPS, 'C-' || COUNTY_FIPS as FIPS_STRING, avg(cast($sEst as real)) as $sEst, avg(cast($sTrue as real)) as $sTrue from tbl1 where REGION='county' group by COUNTY_FIPS order by $sTrue);" > temp.14.csv
	sed "s|sQuantityUC|$sYLabel|g" graph-templates/county-cases-scatterplot-template.xml > temp.13.xml
	bash $sScriptsDir/UpdateGnumericGraph.sh temp.13.xml temp.14.csv county-${sEstVar,,}-estimates-vs-observations.xml
}

function makeStateCaseGraphs {

	sEstVar=$1
	sEst=$sEstVar'_TRUE'
	sEstLog=$sEstVar'_TRUE_LOG'
	sTrueVar=$2
	sTrue=$sTrueVar'_TRUE'
	sTrueLog=$sTrueVar'_TRUE_LOG'
	sYLabel=$3

	sqlite3 estimator-validation-results.db "select *, (case when $sEst=0 then 'na' else log10($sEst) end) as $sEstLog, (case when $sTrue=0 then 'na' else log10($sTrue) end) as $sTrueLog from (select STATE_FIPS, 'S-' || STATE_FIPS as FIPS_STRING, avg(cast($sEst as real)) as $sEst, avg(cast($sTrue as real)) as $sTrue from tbl1 where REGION='county' group by STATE_FIPS order by $sTrue);" > temp.14.csv
	sed "s|sQuantityUC|$sYLabel|g" graph-templates/state-cases-scatterplot-template.xml > temp.13.xml
	bash $sScriptsDir/UpdateGnumericGraph.sh temp.13.xml temp.14.csv state-${sEstVar,,}-estimates-vs-observations.xml
}

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

#generating simulated data set and estimates
sStartDate='2020-03-01'
sEndDate='2020-10-31'
iStartTime=`sqlite3 temp.0.db "select cast(julianday('$sStartDate') as integer);" | tail -n+2 | sed "s|\r||g"`
iEndTime=`sqlite3 temp.0.db "select cast(julianday('$sEndDate') as integer);" | tail -n+2 | sed "s|\r||g"`
sOutputSuffix=$sStartDate'_'$sEndDate

java -cp $sJavaDir/Covid.jar gov.lbnl.Estimator.EstimatorLauncher \
	--sDataPath=$sIODir/temp.2.csv \
	--iRandomSeed=$((1234+i)) \
	--iStartTime=$iStartTime \/
	--iEndTime=$iEndTime \
	--iWindowSize='-1' \
	--sMode=validation_simulation \
	--sOutputPath=$sIODir/temp.3.csv \
	--bTimeIntegrated=true \
	--iIterations=100
		
java -cp $sJavaDir/Utilities.jar edu.ucsf.FlatFileToPivotTable.FlatFileToPivotTableLauncher \
	--sDataPath=$sIODir/temp.3.csv \
	--sValueHeader=VALUE \
	--rgsExpandHeaders='VARIABLE,TYPE' \
	--sOutputPath=$sIODir/temp.4.csv

s1=`head --lines=1 temp.4.csv | sed -e "s|VARIABLE\=||g" -e "s|TYPE\=||g" | sed "s|\;|_|g"`
echo ${s1^^} > temp.5.csv
tail -n+2 temp.4.csv | sed "s|\,null|\,NA|g" >> temp.5.csv

rm -f temp.6.db
sqlite3 temp.6.db ".import $sIODir/temp.5.csv tbl1"

sqlite3 temp.6.db "select 'country' as REGION, COUNTY_FIPS, ITERATION, STATE_FIPS, TIME, CASES_OBSERVED_OBSERVATION as CASES_TRUE, CASES_TOTAL_ESTIMATE as INFECTIONS_ESTIMATE, CASES_TOTAL_OBSERVATION as INFECTIONS_TRUE, INFECTION_FATALITY_RATE_ESTIMATE, MORTALITY_OBSERVATION as MORTALITY_TRUE, TESTS_ESTIMATE, TESTS_OBSERVATION as TESTS_TRUE, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real) as INFECTION_FATALITY_RATE_TRUE, min(1, cast(MORTALITY_OBSERVATION as real)/cast(CASES_OBSERVED_OBSERVATION as real)) as CASE_FATALITY_RATE_TRUE from tbl1 where COUNTY_FIPS='NA' and STATE_FIPS='NA';" > temp.7.csv

sqlite3 temp.6.db "select 'state' as REGION, COUNTY_FIPS, ITERATION, STATE_FIPS, TIME, CASES_OBSERVED_OBSERVATION as CASES_TRUE, CASES_TOTAL_ESTIMATE as INFECTIONS_ESTIMATE, CASES_TOTAL_OBSERVATION as INFECTIONS_TRUE, INFECTION_FATALITY_RATE_ESTIMATE, MORTALITY_OBSERVATION as MORTALITY_TRUE, TESTS_ESTIMATE, TESTS_OBSERVATION as TESTS_TRUE, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real) as INFECTION_FATALITY_RATE_TRUE, min(1, cast(MORTALITY_OBSERVATION as real)/cast(CASES_OBSERVED_OBSERVATION as real)) as CASE_FATALITY_RATE_TRUE from tbl1 where COUNTY_FIPS='NA' and not(STATE_FIPS='NA');" | tail -n+2 >> temp.7.csv

sqlite3 temp.6.db "select 'county' as REGION, COUNTY_FIPS, ITERATION, STATE_FIPS, TIME, CASES_OBSERVED_OBSERVATION as CASES_TRUE, CASES_TOTAL_ESTIMATE as INFECTIONS_ESTIMATE, CASES_TOTAL_OBSERVATION as INFECTIONS_TRUE, INFECTION_FATALITY_RATE_ESTIMATE, MORTALITY_OBSERVATION as MORTALITY_TRUE, TESTS_ESTIMATE, TESTS_OBSERVATION as TESTS_TRUE, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real) as INFECTION_FATALITY_RATE_TRUE, min(1, cast(MORTALITY_OBSERVATION as real)/cast(CASES_OBSERVED_OBSERVATION as real)) as CASE_FATALITY_RATE_TRUE from tbl1 where not(COUNTY_FIPS='NA') and not(STATE_FIPS='NA');" | tail -n+2 >> temp.7.csv

rm -f temp.8.db
sqlite3 temp.8.db ".import $sIODir/temp.7.csv tbl1"
mv temp.8.db estimator-validation-results.db

#initializing output
sqlite3 estimator-validation-results.db "select distinct COUNTY_FIPS, STATE_FIPS from tbl1 where REGION='county';" > county-coefficient-of-variation.csv
echo '"String","String","Real","Real","Real"' > county-coefficient-of-variation.csvt

sqlite3 estimator-validation-results.db "select distinct COUNTY_FIPS, STATE_FIPS, 'C-' || COUNTY_FIPS as FIPS_STRING from tbl1 where REGION='county';" > county-estimates-observations.csv
echo '"String","String","String","Real","Real","Real","Real","Real","Real","Real","Real","Real","Real","Real","Real","Real","Real","Real","Real"' > county-estimates-observations.csvt

sqlite3 estimator-validation-results.db "select distinct STATE_FIPS from tbl1 where REGION='state';" > state-coefficient-of-variation.csv
echo '"String","Real","Real","Real"' > state-coefficient-of-variation.csvt

sqlite3 estimator-validation-results.db "select distinct STATE_FIPS, 'S-' || STATE_FIPS as FIPS_STRING from tbl1 where REGION='state';" > state-estimates-observations.csv
echo '"String","String","Real","Real","Real","Real","Real","Real","Real","Real","Real","Real","Real","Real"' > state-estimates-observations.csvt

#county case fatality rate and cases results
makeCountyCaseGraphs 'CASES' 'INFECTIONS' 'COVID-19\ infections\n(number\ of\ people)'
makeCountyCaseGraphs 'CASE_FATALITY_RATE' 'INFECTION_FATALITY_RATE' 'COVID-19\ infection\ fatality\ rate\n(deaths\/1000\ infections)'

#state case fatality rate and cases results
makeStateCaseGraphs 'CASES' 'INFECTIONS' 'COVID-19\ infections\n(number\ of\ people)'
makeStateCaseGraphs 'CASE_FATALITY_RATE' 'INFECTION_FATALITY_RATE' 'COVID-19\ infection\ fatality\ rate\n(deaths\/1000\ infections)'

#county estimation results
makeCountyEstimationGraphsAndMaps 'INFECTIONS' 'COVID-19\ infections\n(number\ of\ people)'
makeCountyEstimationGraphsAndMaps 'INFECTION_FATALITY_RATE' 'COVID-19\ infection\ fatality\ rate\n(deaths\/1000\ infections)'
makeCountyEstimationGraphsAndMaps 'TESTS' 'Number\ of\ tests\n\ '

#state estimation results
makeStateEstimationGraphsAndMaps 'INFECTIONS' 'COVID-19\ infections\n(number\ of\ people)'
makeStateEstimationGraphsAndMaps 'INFECTION_FATALITY_RATE' 'COVID-19\ infection\ fatality\ rate\n(deaths\/1000\ infections)'

#cleaning up
rm temp.*.*
