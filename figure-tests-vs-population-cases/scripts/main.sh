#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1
	
cd $sIODir

sStateCovidDataDBPath=/home/jladau/Desktop/covid-19-microbiome/final-version/results-genus/ifr-estimation-johns-hopkins-through-february-2021/state-data.db
sCountyCovidDataDBPath=/home/jladau/Desktop/covid-19-microbiome/final-version/results-genus/ifr-estimation-johns-hopkins-through-february-2021/county-data.db

sqlite3 $sStateCovidDataDBPath "select STATE_FIPS, DATE, VALUE as TESTS from tbl1 where cast(VALUE as real)>0 and julianday(DATE)>=julianday('2020-03-01') and julianday(DATE)<=julianday('2021-01-31');" > temp.1.csv
sqlite3 $sCountyCovidDataDBPath "select STATE_FIPS, sum(cast(VALUE as real)) as POPULATION_LOG from tbl1 where VARIABLE='population' group by STATE_FIPS;" > temp.2.csv
sqlite3 $sCountyCovidDataDBPath "select STATE_FIPS, DATE, sum(cast(VALUE as real)) as CASES_OBSERVED from tbl1 where VARIABLE='cases_observed' and julianday(DATE)>=julianday('2020-03-01') and julianday(DATE)<=julianday('2021-01-31') group by STATE_FIPS, DATE;" > temp.3.csv

joiner 'STATE_FIPS,DATE' temp.1.csv temp.3.csv > temp.4.csv
joiner 'STATE_FIPS' temp.4.csv temp.2.csv | sed "s|\,NA|,0|g" > temp.5.csv

rm -f temp.6.db
sqlite3 temp.6.db ".import $sIODir/temp.5.csv tbl1"
sqlite3 temp.6.db "select * from tbl1 where cast(CASES_OBSERVED as real)<=cast(TESTS as real);" > temp.7.csv

bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/template-tests-vs-population.xml temp.7.csv tests-vs-population.xml
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/template-tests-vs-cases.xml temp.7.csv tests-vs-cases.xml

rm -f temp.*.*
