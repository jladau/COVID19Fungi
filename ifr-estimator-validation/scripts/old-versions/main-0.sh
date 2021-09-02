#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

sStateDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/results-genus/ifr-estimation-johns-hopkins-through-february-2021/state-data.db
sCountyDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/results-genus/ifr-estimation-johns-hopkins-through-february-2021/county-data.db

cd $sIODir

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

exit

rm -f temp.6.db
sqlite3 temp.6.db ".import $sIODir/temp.5.csv tbl1"
sqlite3 temp.6.db "select 'country' as REGION, * from tbl1 where COUNTY_FIPS='NA' and STATE_FIPS='NA';" > temp.7.csv
sqlite3 temp.6.db "select 'state' as REGION, * from tbl1 where COUNTY_FIPS='NA' and not(STATE_FIPS='NA');" | tail -n+2 >> temp.7.csv
sqlite3 temp.6.db "select 'county' as REGION, * from tbl1 where not(COUNTY_FIPS='NA') and not(STATE_FIPS='NA');" | tail -n+2 >> temp.7.csv
rm -f temp.8.db
sqlite3 temp.8.db ".import $sIODir/temp.7.csv tbl1"
mv temp.8.db estimator-validation-results.db

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
