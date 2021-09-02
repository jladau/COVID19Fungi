#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

sStateDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/results-genus/ifr-estimation-johns-hopkins-through-february-2021/state-data.db
sCountyDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/results-genus/ifr-estimation-johns-hopkins-through-february-2021/county-data.db

cd $sIODir

function makeCountyGraphsAndMaps {
	
	sVar=$1
	sEst=$sVar'_ESTIMATE'
	sObs=$sVar'_OBSERVATION'
	sStdev=$sVar'_STDEV'
	sMsd=$sVar'_MSD'
	sRmse=$sVar'_RMSE'
	
	sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, 'C-' || COUNTY_FIPS as FIPS_STRING, avg(cast($sEst as real)) as $sEst, avg(cast($sObs as real)) as $sObs from tbl1 where REGION='county' group by COUNTY_FIPS order by $sObs;" > temp.14.csv
	joiner 'COUNTY_FIPS,STATE_FIPS,FIPS_STRING' county-estimates-observations.csv temp.14.csv | sponge county-estimates-observations.csv
	sed "s|sQuantityUC|COVID-19\ infections\n(number\ of\ people)|g" graph-templates/county-scatterplot-template.xml > temp.13.xml
	bash $sScriptsDir/UpdateGnumericGraph.sh temp.13.xml temp.14.csv county-infections-estimates-vs-observations.xml

	#variance
	sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, stdev(cast($sEst as real)) as $sStdev from tbl1 where REGION='county' group by COUNTY_FIPS, STATE_FIPS;" > temp.12.csv
	joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

	#bias
	sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, avg((EST - OBS)) as $sMsd from (select COUNTY_FIPS, STATE_FIPS, cast($sEst as real) as EST, cast($sObs as real) as OBS from tbl1 where REGION='county') group by STATE_FIPS, COUNTY_FIPS;" > temp.12.csv
	joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

	#rmse
	sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, sqrt(avg((EST-OBS)*(EST-OBS))) as $sRmse from (select COUNTY_FIPS, STATE_FIPS, cast($sEst as real) as EST, cast($sObs as real) as OBS from tbl1 where REGION='county') group by STATE_FIPS, COUNTY_FIPS;" > temp.12.csv
	joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

}


<<COMMENT0

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
	--iStartTime=$iStartTime \
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

COMMENT0

rm -f temp.6.db
sqlite3 temp.6.db ".import $sIODir/temp.5.csv tbl1"
sqlite3 temp.6.db "select 'country' as REGION, COUNTY_FIPS, ITERATION, STATE_FIPS, TIME, CASES_OBSERVED_OBSERVATION, CASES_TOTAL_ESTIMATE as INFECTIONS_ESTIMATE, CASES_TOTAL_OBSERVATION as INFECTIONS_OBSERVATION, INFECTION_FATALITY_RATE_ESTIMATE, MORTALITY_OBSERVATION, TESTS_ESTIMATE, TESTS_OBSERVATION, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real) as INFECTION_FATALITY_RATE_OBSERVATION from tbl1 where COUNTY_FIPS='NA' and STATE_FIPS='NA';" > temp.7.csv
sqlite3 temp.6.db "select 'state' as REGION, COUNTY_FIPS, ITERATION, STATE_FIPS, TIME, CASES_OBSERVED_OBSERVATION, CASES_TOTAL_ESTIMATE as INFECTIONS_ESTIMATE, CASES_TOTAL_OBSERVATION as INFECTIONS_OBSERVATION, INFECTION_FATALITY_RATE_ESTIMATE, MORTALITY_OBSERVATION, TESTS_ESTIMATE, TESTS_OBSERVATION, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real) as INFECTION_FATALITY_RATE_OBSERVATION from tbl1 where COUNTY_FIPS='NA' and not(STATE_FIPS='NA');" | tail -n+2 >> temp.7.csv
sqlite3 temp.6.db "select 'county' as REGION, COUNTY_FIPS, ITERATION, STATE_FIPS, TIME, CASES_OBSERVED_OBSERVATION, CASES_TOTAL_ESTIMATE as INFECTIONS_ESTIMATE, CASES_TOTAL_OBSERVATION as INFECTIONS_OBSERVATION, INFECTION_FATALITY_RATE_ESTIMATE, MORTALITY_OBSERVATION, TESTS_ESTIMATE, TESTS_OBSERVATION, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real) as INFECTION_FATALITY_RATE_OBSERVATION from tbl1 where not(COUNTY_FIPS='NA') and not(STATE_FIPS='NA');" | tail -n+2 >> temp.7.csv
rm -f temp.8.db
sqlite3 temp.8.db ".import $sIODir/temp.7.csv tbl1"
mv temp.8.db estimator-validation-results.db

#initializing output
sqlite3 estimator-validation-results.db "select distinct COUNTY_FIPS, STATE_FIPS from tbl1 where REGION='county';" > county-stdev-bias-rmse.csv
echo '"String","String","Real","Real","Real","Real","Real","Real","Real","Real","Real"' > county-stdev-bias-rmse.csvt

sqlite3 estimator-validation-results.db "select distinct COUNTY_FIPS, STATE_FIPS, 'C-' || COUNTY_FIPS as FIPS_STRING from tbl1 where REGION='county';" > county-estimates-observations.csv
echo '"String","String","String","Real","Real","Real","Real","Real","Real"' > county-estimates-observations.csvt

sqlite3 estimator-validation-results.db "select distinct STATE_FIPS from tbl1 where REGION='state';" > state-stdev-bias-rmse.csv
echo '"String","Real","Real","Real","Real","Real","Real"' > state-stdev-bias-rmse.csvt

sqlite3 estimator-validation-results.db "select distinct STATE_FIPS, 'S-' || STATE_FIPS as FIPS_STRING from tbl1 where REGION='state';" > state-estimates-observations.csv
echo '"String","String","Real","Real","Real","Real"' > state-estimates-observations.csvt

#TODO output log values after unlogged values with nested query --> update csvt files

#-------------------------------------------------------
#COUNTY: INFECTIONS
#-------------------------------------------------------

makeCountyGraphsAndMaps 'INFECTIONS'

exit

#observed vs estimated
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, 'C-' || COUNTY_FIPS as FIPS_STRING, avg(cast(CASES_TOTAL_ESTIMATE as real)) as INFECTIONS_ESTIMATE, avg(cast(CASES_TOTAL_OBSERVATION as real)) as INFECTIONS_OBSERVATION from tbl1 where REGION='county' group by COUNTY_FIPS order by INFECTIONS_OBSERVATION;" > temp.14.csv
joiner 'COUNTY_FIPS,STATE_FIPS,FIPS_STRING' county-estimates-observations.csv temp.14.csv | sponge county-estimates-observations.csv
sed "s|sQuantityUC|COVID-19\ infections\n(number\ of\ people)|g" graph-templates/county-scatterplot-template.xml > temp.13.xml
bash $sScriptsDir/UpdateGnumericGraph.sh temp.13.xml temp.14.csv county-infections-estimates-vs-observations.xml

#variance
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, stdev(cast(CASES_TOTAL_ESTIMATE as real)) as INFECTIONS_STDEV from tbl1 where REGION='county' group by COUNTY_FIPS, STATE_FIPS;" > temp.12.csv
joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

#bias
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, avg((EST - OBS)) as INFECTIONS_MSD from (select COUNTY_FIPS, STATE_FIPS, cast(CASES_TOTAL_ESTIMATE as real) as EST, cast(CASES_TOTAL_OBSERVATION as real) as OBS from tbl1 where REGION='county') group by STATE_FIPS, COUNTY_FIPS;" > temp.12.csv
joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

#rmse
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, sqrt(avg((EST-OBS)*(EST-OBS))) as INFECTIONS_RMSE from (select COUNTY_FIPS, STATE_FIPS, cast(CASES_TOTAL_ESTIMATE as real) as EST, cast(CASES_TOTAL_OBSERVATION as real) as OBS from tbl1 where REGION='county') group by STATE_FIPS, COUNTY_FIPS;" > temp.12.csv
joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

#-------------------------------------------------------
#COUNTY: INFECTION FATALITY RATE
#-------------------------------------------------------

#observed vs estimated
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, 'C-' || COUNTY_FIPS as FIPS_STRING, avg(cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_ESTIMATE as real)) as IFR_ESTIMATE, avg(cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real)) as IFR_OBSERVATION from tbl1 where REGION='county' group by COUNTY_FIPS order by IFR_OBSERVATION;" > temp.14.csv
joiner 'COUNTY_FIPS,STATE_FIPS,FIPS_STRING' county-estimates-observations.csv temp.14.csv | sponge county-estimates-observations.csv
sed "s|sQuantityUC|COVID-19\ infection\ fatality\ rate\n(deaths\/1000\ infections)|g" graph-templates/county-scatterplot-template.xml > temp.13.xml
bash $sScriptsDir/UpdateGnumericGraph.sh temp.13.xml temp.14.csv county-ifr-estimates-vs-observations.xml

#variance
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, stdev(cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_ESTIMATE as real)) as IFR_STDEV from tbl1 where REGION='county' group by COUNTY_FIPS, STATE_FIPS;" > temp.12.csv
joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

#bias
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, avg((EST - OBS)) as IFR_MSD from (select COUNTY_FIPS, STATE_FIPS, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_ESTIMATE as real) as EST, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real) as OBS from tbl1 where REGION='county') group by STATE_FIPS, COUNTY_FIPS;" > temp.12.csv
joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

#rmse
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, sqrt(avg((EST-OBS)*(EST-OBS))) as IFR_RMSE from (select COUNTY_FIPS, STATE_FIPS, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_ESTIMATE as real) as EST, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real) as OBS from tbl1 where REGION='county') group by STATE_FIPS, COUNTY_FIPS;" > temp.12.csv
joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

#-------------------------------------------------------
#COUNTY: TESTS
#-------------------------------------------------------

#observed vs estimated
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, 'C-' || COUNTY_FIPS as FIPS_STRING, avg(cast(TESTS_ESTIMATE as real)) as TESTS_ESTIMATE, avg(cast(TESTS_OBSERVATION as real)) as TESTS_OBSERVATION from tbl1 where REGION='county' group by COUNTY_FIPS order by TESTS_OBSERVATION;" > temp.14.csv
joiner 'COUNTY_FIPS,STATE_FIPS,FIPS_STRING' county-estimates-observations.csv temp.14.csv | sponge county-estimates-observations.csv
sed "s|sQuantityUC|Number\ of\ tests|g" graph-templates/county-scatterplot-template.xml > temp.13.xml
bash $sScriptsDir/UpdateGnumericGraph.sh temp.13.xml temp.14.csv county-tests-estimates-vs-observations.xml

#variance
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, stdev(cast(TESTS_ESTIMATE as real)) as TESTS_STDEV from tbl1 where REGION='county' group by COUNTY_FIPS, STATE_FIPS;" > temp.12.csv
joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

#bias
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, avg((EST - OBS)) as TESTS_MSD from (select COUNTY_FIPS, STATE_FIPS, cast(TESTS_ESTIMATE as real) as EST, cast(TESTS_OBSERVATION as real) as OBS from tbl1 where REGION='county') group by STATE_FIPS, COUNTY_FIPS;" > temp.12.csv
joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

#rmse
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, STATE_FIPS, sqrt(avg((EST-OBS)*(EST-OBS))) as TESTS_RMSE from (select COUNTY_FIPS, STATE_FIPS, cast(TESTS_ESTIMATE as real) as EST, cast(TESTS_OBSERVATION as real) as OBS from tbl1 where REGION='county') group by STATE_FIPS, COUNTY_FIPS;" > temp.12.csv
joiner 'COUNTY_FIPS,STATE_FIPS' county-stdev-bias-rmse.csv temp.12.csv | sponge county-stdev-bias-rmse.csv

#-------------------------------------------------------
#STATE: INFECTIONS
#-------------------------------------------------------

#observed vs estimated
sqlite3 estimator-validation-results.db "select STATE_FIPS, 'S-' || STATE_FIPS as FIPS_STRING, avg(cast(CASES_TOTAL_ESTIMATE as real)) as INFECTIONS_ESTIMATE, avg(cast(CASES_TOTAL_OBSERVATION as real)) as INFECTIONS_OBSERVATION from tbl1 where REGION='state' group by STATE_FIPS order by INFECTIONS_OBSERVATION;" > temp.14.csv
joiner 'STATE_FIPS,FIPS_STRING' state-estimates-observations.csv temp.14.csv | sponge state-estimates-observations.csv
sed "s|sQuantityUC|COVID-19\ infections\n(number\ of\ people)|g" graph-templates/state-scatterplot-template.xml > temp.13.xml
bash $sScriptsDir/UpdateGnumericGraph.sh temp.13.xml temp.14.csv state-infections-estimates-vs-observations.xml

#variance
sqlite3 estimator-validation-results.db "select STATE_FIPS, stdev(cast(CASES_TOTAL_ESTIMATE as real)) as INFECTIONS_STDEV from tbl1 where REGION='state' group by STATE_FIPS;" > temp.12.csv
joiner 'STATE_FIPS' state-stdev-bias-rmse.csv temp.12.csv | sponge state-stdev-bias-rmse.csv

#bias
sqlite3 estimator-validation-results.db "select STATE_FIPS, avg((EST - OBS)) as INFECTIONS_MSD from (select STATE_FIPS, cast(CASES_TOTAL_ESTIMATE as real) as EST, cast(CASES_TOTAL_OBSERVATION as real) as OBS from tbl1 where REGION='state') group by STATE_FIPS;" > temp.12.csv
joiner 'STATE_FIPS' state-stdev-bias-rmse.csv temp.12.csv | sponge state-stdev-bias-rmse.csv

#rmse
sqlite3 estimator-validation-results.db "select STATE_FIPS, sqrt(avg((EST-OBS)*(EST-OBS))) as INFECTIONS_RMSE from (select STATE_FIPS, cast(CASES_TOTAL_ESTIMATE as real) as EST, cast(CASES_TOTAL_OBSERVATION as real) as OBS from tbl1 where REGION='state') group by STATE_FIPS;" > temp.12.csv
joiner 'STATE_FIPS' state-stdev-bias-rmse.csv temp.12.csv | sponge state-stdev-bias-rmse.csv

#-------------------------------------------------------
#STATE: INFECTION FATALITY RATE
#-------------------------------------------------------

#observed vs estimated
sqlite3 estimator-validation-results.db "select STATE_FIPS, 'S-' || STATE_FIPS as FIPS_STRING, avg(cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_ESTIMATE as real)) as IFR_ESTIMATE, avg(cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real)) as IFR_OBSERVATION from tbl1 where REGION='state' group by STATE_FIPS order by IFR_OBSERVATION;" > temp.14.csv
joiner 'STATE_FIPS,FIPS_STRING' state-estimates-observations.csv temp.14.csv | sponge state-estimates-observations.csv
sed "s|sQuantityUC|COVID-19\ infection\ fatality\ rate\n(deaths\/1000\ infections)|g" graph-templates/state-scatterplot-template.xml > temp.13.xml
bash $sScriptsDir/UpdateGnumericGraph.sh temp.13.xml temp.14.csv state-ifr-estimates-vs-observations.xml

#variance
sqlite3 estimator-validation-results.db "select STATE_FIPS, stdev(cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_ESTIMATE as real)) as IFR_STDEV from tbl1 where REGION='state' group by STATE_FIPS;" > temp.12.csv
joiner 'STATE_FIPS' state-stdev-bias-rmse.csv temp.12.csv | sponge state-stdev-bias-rmse.csv

#bias
sqlite3 estimator-validation-results.db "select STATE_FIPS, avg((EST - OBS)) as IFR_MSD from (select STATE_FIPS, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_ESTIMATE as real) as EST, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real) as OBS from tbl1 where REGION='state') group by STATE_FIPS;" > temp.12.csv
joiner 'STATE_FIPS' state-stdev-bias-rmse.csv temp.12.csv | sponge state-stdev-bias-rmse.csv

#rmse
sqlite3 estimator-validation-results.db "select STATE_FIPS, sqrt(avg((EST-OBS)*(EST-OBS))) as IFR_RMSE from (select STATE_FIPS, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_ESTIMATE as real) as EST, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real) as OBS from tbl1 where REGION='state') group by STATE_FIPS;" > temp.12.csv
joiner 'STATE_FIPS' state-stdev-bias-rmse.csv temp.12.csv | sponge state-stdev-bias-rmse.csv









exit


#country: estimated vs true odds ratios
sqlite3 estimator-validation-results.db "select date(TIME) as Date, ODDS_RATIO_OBSERVATION as 'Odds ratio', ODDS_RATIO_ESTIMATE as 'Odds ratio (estimate)' from tbl1 where REGION='country' order by cast(ODDS_RATIO_OBSERVATION as real);" > temp.9.csv
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/time-series-log-y-template.xml temp.9.csv country-odds-ratio-time-series.xml

#county: estimated vs true infections
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, sum(cast(CASES_TOTAL_OBSERVATION as real)) as Infections, sum(cast(CASES_TOTAL_ESTIMATE as real)) as 'Estimated infections' from tbl1 where REGION='county' group by COUNTY_FIPS order by Infections;" > temp.10.csv
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/scatterplot-template.xml temp.10.csv county-estimated-vs-true-infections.xml

#county: observed cases vs true infections 
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, sum(cast(CASES_TOTAL_OBSERVATION as real)) as Infections, sum(cast(CASES_OBSERVED_OBSERVATION as real)) as 'Observed cases' from tbl1 where REGION='county' group by COUNTY_FIPS order by Infections;" > temp.11.csv
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/scatterplot-template.xml temp.11.csv county-cases-vs-true-infections.xml

#county: estimated vs true tests
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, sum(cast(TESTS_OBSERVATION as real)) as 'Tests', sum(cast(TESTS_ESTIMATE as real)) as 'Estimated tests' from tbl1 where REGION='county' group by COUNTY_FIPS order by Tests;" > temp.12.csv
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/scatterplot-template.xml temp.12.csv county-estimated-vs-true-tests.xml

#country: infection fatality rate (true and estimated) through time
sqlite3 estimator-validation-results.db "select date(TIME) as Date, cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_OBSERVATION as real) as 'Infection fatality rate', cast(MORTALITY_OBSERVATION as real)/cast(CASES_TOTAL_ESTIMATE as real) as 'Estimated infection fatality rate' from tbl1  where REGION='country' order by cast(TIME as real);" > temp.13.csv
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/time-series-template.xml temp.13.csv country-infection-fatality-rate-time-series.xml

#county: estimated vs true infection fatality rate
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, MORTALITY/INFECTIONS_TRUE as 'Infection fatality rate', MORTALITY/INFECTIONS_ESTIMATE as 'Estimated infection fatality rate' from (select COUNTY_FIPS, sum(cast(MORTALITY_OBSERVATION as real)) as MORTALITY, sum(cast(CASES_TOTAL_OBSERVATION as real)) as INFECTIONS_TRUE, sum(cast(CASES_TOTAL_ESTIMATE as real)) as INFECTIONS_ESTIMATE from tbl1 where REGION='county' group by COUNTY_FIPS) order by MORTALITY/INFECTIONS_TRUE;" > temp.14.csv
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/scatterplot-template.xml temp.14.csv county-estimated-vs-ifr.xml

#county: case fatality rate vs true infection fatality rate
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, MORTALITY/INFECTIONS_TRUE as 'Infection fatality rate', min(MORTALITY/CASES_OBSERVED,1) as 'Case fatality rate' from (select COUNTY_FIPS, sum(cast(MORTALITY_OBSERVATION as real)) as MORTALITY, sum(cast(CASES_TOTAL_OBSERVATION as real)) as INFECTIONS_TRUE, sum(cast(CASES_OBSERVED_OBSERVATION as real)) as CASES_OBSERVED from tbl1 where REGION='county' group by COUNTY_FIPS) order by MORTALITY/INFECTIONS_TRUE;" > temp.15.csv
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/scatterplot-template.xml temp.15.csv county-cfr-vs-ifr.xml

#state: estimated vs true infections
sqlite3 estimator-validation-results.db "select STATE_FIPS, sum(cast(CASES_TOTAL_OBSERVATION as real)) as Infections, sum(cast(CASES_TOTAL_ESTIMATE as real)) as 'Estimated infections' from tbl1 where REGION='state' group by STATE_FIPS order by Infections;" > temp.16.csv
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/scatterplot-template.xml temp.16.csv state-estimated-vs-true-infections.xml

#state: observed cases vs true infections 
sqlite3 estimator-validation-results.db "select STATE_FIPS, sum(cast(CASES_TOTAL_OBSERVATION as real)) as Infections, sum(cast(CASES_OBSERVED_OBSERVATION as real)) as 'Observed cases' from tbl1 where REGION='state' group by STATE_FIPS order by Infections;" > temp.17.csv
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/scatterplot-template.xml temp.17.csv state-cases-vs-true-infections.xml

#county: different infection fatality rate estimates, both estimate types
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, MORTALITY/INFECTIONS_ESTIMATE as 'Estimated IFR' from (select COUNTY_FIPS, sum(cast(MORTALITY_OBSERVATION as real)) as MORTALITY, sum(cast(CASES_TOTAL_OBSERVATION as real)) as INFECTIONS_TRUE, sum(cast(CASES_TOTAL_ESTIMATE as real)) as INFECTIONS_ESTIMATE from tbl1 where REGION='county' group by COUNTY_FIPS) order by MORTALITY/INFECTIONS_TRUE;" | sed "s|\r||g" > temp.18.csv
sqlite3 estimator-validation-results.db "select COUNTY_FIPS, INFECTION_FATALITY_RATE_ESTIMATE as 'Estimated IFR old' from tbl1 where REGION='county' and not(INFECTION_FATALITY_RATE_ESTIMATE='NA');" > temp.19.csv
joiner 'COUNTY_FIPS' temp.18.csv temp.19.csv > temp.20.csv
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/scatterplot-template.xml temp.20.csv county-new-vs-old-ifr-estimates.xml

#cleaning up
rm temp.*.*
