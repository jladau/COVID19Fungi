#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

#--------------------------------------------------------------
#INITIALIZING
bash $sIODir/scripts/format-hopkins-data.sh $1

sqlite3 formatted-covid-data.db "select * from tbl1 where not(fips like '%000') and not(fips like '00%') and not(fips like '6%') and not(fips like '7%') and not(fips like '8%') and not(fips like '9%') order by fips, julianday(date);" > temp.2.csv
rm -f formatted-covid-data.db
sqlite3 formatted-covid-data.db ".import $sIODir/temp.2.csv tbl1"
echo 'COUNTY_FIPS,STATE_FIPS,DATE,SMOOTHING,VARIABLE,VALUE' > temp.output.csv
#--------------------------------------------------------------

#--------------------------------------------------------------
#FINDING MORTALITY
sqlite3 formatted-covid-data.db "select date as DATE, fips as COUNTY_FIPS, deaths as MORTALITY_CUMULATIVE from tbl1;" > temp.3.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.RowNumbers.RowNumbersLauncher \
	--sDataPath=$sIODir/temp.3.csv \
	--sOutputPath=$sIODir/temp.3.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.DifferencesBetweenRows.DifferencesBetweenRowsLauncher \
	--sDataPath=$sIODir/temp.3.csv \
	--sCategoryField=COUNTY_FIPS \
	--sValueField=MORTALITY_CUMULATIVE \
	--sOutputPath=$sIODir/temp.4.csv
sed -i "s|START_ROW\,CATEGORY\,VALUE_DIFFERENCE|ROW_NUMBER,COUNTY_FIPS,MORTALITY|g" temp.4.csv
joiner 'ROW_NUMBER,COUNTY_FIPS' temp.4.csv temp.3.csv > temp.5.csv

rm -f temp.6.db
sqlite3 temp.6.db ".import $sIODir/temp.5.csv tbl1"
sqlite3 temp.6.db "select COUNTY_FIPS, substr(COUNTY_FIPS,0,3) as STATE_FIPS, DATE, 'raw' as SMOOTHING, 'mortality' as VARIABLE, cast(MORTALITY as integer) as VALUE from tbl1 where cast(MORTALITY as real)>0;" | tail -n+2 >> temp.output.csv
#--------------------------------------------------------------

#--------------------------------------------------------------
#FINDING OBSERVED CASES
sqlite3 formatted-covid-data.db "select date as DATE, fips as COUNTY_FIPS, cases as CASES_OBSERVED_CUMULATIVE from tbl1;" > temp.3.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.RowNumbers.RowNumbersLauncher \
	--sDataPath=$sIODir/temp.3.csv \
	--sOutputPath=$sIODir/temp.3.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.DifferencesBetweenRows.DifferencesBetweenRowsLauncher \
	--sDataPath=$sIODir/temp.3.csv \
	--sCategoryField=COUNTY_FIPS \
	--sValueField=CASES_OBSERVED_CUMULATIVE \
	--sOutputPath=$sIODir/temp.4.csv
sed -i "s|START_ROW\,CATEGORY\,VALUE_DIFFERENCE|ROW_NUMBER,COUNTY_FIPS,CASES_OBSERVED|g" temp.4.csv
joiner 'ROW_NUMBER,COUNTY_FIPS' temp.4.csv temp.3.csv > temp.5.csv
rm -f temp.6.db
sqlite3 temp.6.db ".import $sIODir/temp.5.csv tbl1"
sqlite3 temp.6.db "select COUNTY_FIPS, substr(COUNTY_FIPS,0,3) as STATE_FIPS, DATE, 'raw' as SMOOTHING, 'cases_observed' as VARIABLE, cast(CASES_OBSERVED as integer) as VALUE from tbl1 where cast(CASES_OBSERVED as real)>0;" | tail -n+2 >> temp.output.csv
#--------------------------------------------------------------

#--------------------------------------------------------------
#APPENDING POPULATION DATA

rm -f temp.9.db
sqlite3 temp.9.db ".import $sPopulationDataPath tbl1"
sqlite3 temp.9.db "select STATE || COUNTY as COUNTY_FIPS, STATE as STATE_FIPS, 'NA' as DATE, 'raw' as SMOOTHING, 'population' as VARIABLE, POPESTIMATE2019 as VALUE from tbl1 where cast(POPESTIMATE2019 as real)>0 and not(COUNTY_FIPS like '%000') and not(COUNTY_FIPS like '00%') and not(COUNTY_FIPS like '6%') and not(COUNTY_FIPS like '7%') and not(COUNTY_FIPS like '8%') and not(COUNTY_FIPS like '9%');" | tail -n+2 >> temp.output.csv
#--------------------------------------------------------------

#--------------------------------------------------------------
#REMOVING OUTLIERS
rm -f temp.7.db
sqlite3 temp.7.db ".import $sIODir/temp.output.csv tbl1"
sqlite3 temp.7.db "select * from tbl1 where VARIABLE='mortality' and not(STATE_FIPS='36' and DATE='2020-05-17') and not(STATE_FIPS='34' and DATE='2020-06-24');" > temp.8.csv
sqlite3 temp.7.db "select * from tbl1 where VARIABLE='cases_observed' and not(COUNTY_FIPS='48201' and DATE='2020-09-20');" | tail -n+2 >> temp.8.csv
sqlite3 temp.7.db "select * from tbl1 where VARIABLE='population';" | tail -n+2 >> temp.8.csv
rm -f county-data.db
sqlite3 county-data.db ".import $sIODir/temp.8.csv tbl1"
#--------------------------------------------------------------

#--------------------------------------------------------------
#NUMBER OF TESTS -- STATE LEVEL

#formatting na's and data quality grades
sed -e "s|\"||g" -e "s|\,\,|\,NA\,|g" $sRawStateDataPath | sed "s|\,\,|\,NA\,|g" | sed "s|\,A+\,|\,0\,|g" | sed -e "s|\,A\,|\,1\,|g" -e "s|\,B\,|\,2\,|g" -e "s|\,C\,|\,3\,|g" -e "s|\,D\,|\,3\,|g" -e "s|\,F\,|\,4\,|g" > temp.1.csv

#formatting dates
#paste -d\- <(cut -d\, -f1 temp.1.csv | sed "s|0[0-9][0-9][0-9]$||g") <(cut -d\, -f1 temp.1.csv | sed "s|^2020||g" | sed "s|[0-9][0-9]$||g" ) <(cut -d\, -f1 temp.1.csv | sed "s|^20200[0-9]||g") | tail -n+2 | sed "1,1 s|^|DATE_FORMATTED\n|g" > temp.4.csv
cut -d\, -f1 temp.1.csv | sed "1 s|date|DATE_FORMATTED|g" > temp.4.csv
paste -d\, temp.1.csv temp.4.csv > temp.5.csv

#appending population data
rm -f temp.4.db
sqlite3 temp.4.db ".import $sStatePopulationDataPath tbl1"
sqlite3 temp.4.db "select STNAME as STATE, STATE as STATE_FIPS, sum(cast(POPESTIMATE2019 as real)) as POPULATION_ESTIMATE_2019 from tbl1 group by STNAME;" > temp.6.csv
joiner 'STATE' temp.6.csv $sPostalCodesPath > temp.7.csv
sed -i "1,1 s|\,state\,|\,ABBREVIATION\,|g" temp.5.csv
joiner 'ABBREVIATION' temp.5.csv temp.7.csv > temp.8.csv

rm -f temp.6.db
sqlite3 temp.6.db ".import $sIODir/temp.8.csv tbl1"
echo 'STATE_FIPS,DATE,SMOOTHING,VARIABLE,VALUE' > temp.output.csv

sqlite3 temp.6.db "select STATE_FIPS, julianday(DATE_FORMATTED) as TIME, totalTestResults as VALUE from tbl1 where not(STATE_FIPS='NA') order by STATE_FIPS, TIME;" | sed "s|\r||g" > temp.9.csv

#finding daily data
java -cp $sJavaDir/Utilities.jar edu.ucsf.RowNumbers.RowNumbersLauncher \
	--sDataPath=$sIODir/temp.9.csv \
	--sOutputPath=$sIODir/temp.12.csv	
java -cp $sJavaDir/Utilities.jar edu.ucsf.DifferencesBetweenRows.DifferencesBetweenRowsLauncher \
	--sDataPath=$sIODir/temp.12.csv \
	--sCategoryField=STATE_FIPS \
	--sValueField=VALUE \
	--sOutputPath=$sIODir/temp.13.csv
sed -i "s|START_ROW\,CATEGORY\,VALUE_DIFFERENCE|ROW_NUMBER,STATE_FIPS,TESTS|g" temp.13.csv
joiner 'ROW_NUMBER,STATE_FIPS' temp.13.csv temp.12.csv > temp.14.csv

rm -f temp.11.db
sqlite3 temp.11.db ".import $sIODir/temp.14.csv tbl1"
sqlite3 temp.11.db "select STATE_FIPS, date(TIME) as DATE, 'raw' as SMOOTHING, 'tests' as VARIABLE, TESTS as VALUE from tbl1 where cast(TESTS as real)>0;" | tail -n+2 >> temp.output.csv
rm -f state-data.db
sqlite3 state-data.db ".import $sIODir/temp.output.csv tbl1"
#--------------------------------------------------------------

#--------------------------------------------------------------
#CLEANING UP
rm -f temp.*.*
#--------------------------------------------------------------

