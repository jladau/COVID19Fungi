#!/bin/bash

sIODir=/home/jladau/Desktop

sFilePath=/home/jladau/Desktop/covid-19-microbiome/final-version/in-progress/ifr-estimator-validation/temp.3.csv

cd $sIODir

rm -f temp.1.db
sqlite3 temp.1.db ".import $sFilePath tbl1"

#county-state validation
sqlite3 temp.1.db "select STATE_FIPS, TYPE, VARIABLE, TIME, sum(cast(VALUE as real)) as VALUE_SUM from tbl1 where not(COUNTY_FIPS='NA') and not(STATE_FIPS='NA') group by STATE_FIPS, TYPE, VARIABLE, TIME;" > temp.2.csv
sqlite3 temp.1.db "select STATE_FIPS, TYPE, VARIABLE, TIME, VALUE from tbl1 where COUNTY_FIPS='NA' and not(STATE_FIPS='NA');" > temp.3.csv
joiner 'STATE_FIPS,TYPE,VARIABLE,TIME' temp.2.csv temp.3.csv > temp.4.csv
rm -f temp.5.db
sqlite3 temp.5.db ".import $sIODir/temp.4.csv tbl1"
sqlite3 temp.5.db "select TYPE, VARIABLE, sum(abs(cast(VALUE as real)-cast(VALUE_SUM as real))) as SUM_DEVIATIONS_COUNTY_STATE from tbl1 group by TYPE, VARIABLE;"

sqlite3 temp.5.db "select * from tbl1 where VARIABLE='cases_total';" > county-state-tests-data.csv


#county-country validation
sqlite3 temp.1.db "select TYPE, VARIABLE, TIME, sum(cast(VALUE as real)) as VALUE_SUM from tbl1 where not(COUNTY_FIPS='NA') and not(STATE_FIPS='NA') group by TYPE, VARIABLE, TIME;" > temp.2.csv
sqlite3 temp.1.db "select TYPE, VARIABLE, TIME, VALUE from tbl1 where COUNTY_FIPS='NA' and STATE_FIPS='NA';" > temp.3.csv
joiner 'TYPE,VARIABLE,TIME' temp.2.csv temp.3.csv > temp.4.csv
rm -f temp.5.db
sqlite3 temp.5.db ".import $sIODir/temp.4.csv tbl1"
sqlite3 temp.5.db "select TYPE, VARIABLE, sum(abs(cast(VALUE as real)-cast(VALUE_SUM as real))) as SUM_DEVIATIONS_COUNTY_COUNTRY from tbl1 group by TYPE, VARIABLE;"

#state-country validation
sqlite3 temp.1.db "select TYPE, VARIABLE, TIME, sum(cast(VALUE as real)) as VALUE_SUM from tbl1 where COUNTY_FIPS='NA' and not(STATE_FIPS='NA') group by TYPE, VARIABLE, TIME;" > temp.2.csv
sqlite3 temp.1.db "select TYPE, VARIABLE, TIME, VALUE from tbl1 where COUNTY_FIPS='NA' and STATE_FIPS='NA';" > temp.3.csv
joiner 'TYPE,VARIABLE,TIME' temp.2.csv temp.3.csv > temp.4.csv
rm -f temp.5.db
sqlite3 temp.5.db ".import $sIODir/temp.4.csv tbl1"
sqlite3 temp.5.db "select TYPE, VARIABLE, sum(abs(cast(VALUE as real)-cast(VALUE_SUM as real))) as SUM_DEVIATIONS_STATE_COUNTRY from tbl1 group by TYPE, VARIABLE;"

#cleaning up
rm temp.*.*

