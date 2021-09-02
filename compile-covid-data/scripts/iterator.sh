#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1
sDates=$2

cd $sIODir


sOutputPathPaired='compiled-covid-data-'$sDates'-paired.csv'
sOutputPathUnpaired='compiled-covid-data-'$sDates'-unpaired.csv'

#joining r0 data
sIFRDataPath=$sIFREstimatesDir/ifr-estimates-$sDates.csv
joiner 'COUNTY_FIPS' $sIFRDataPath $sR0EstimatesPath | cut -d\, -f1-6 | tail -n+2 | sed "1 s|^|SAMPLE,STATE_FIPS,COUNTY_FIPS,IFR_COUNTY,IFR_STATE,R0\n|g" | grep -v "\,NA" > temp.8.csv

#formatting paired data
sed "1 s|SAMPLE\,|SAMPLE.LOCATION,|1" temp.8.csv > temp.1.csv
paste -d\, <(cut -d\. -f1 temp.1.csv) <(cut -d\. -f2 temp.1.csv | cut -d\, -f1) <(cat temp.1.csv) | sed "1 s|SAMPLE\.LOCATION|SAMPLE_LOCATION|g" > temp.2.csv
rm -f temp.3.db
sqlite3 temp.3.db ".import $sIODir/temp.2.csv tbl1"
sqlite3 temp.3.db "select distinct SAMPLE, STATE_FIPS, COUNTY_FIPS, IFR_COUNTY, IFR_STATE, R0 from tbl1;" > temp.4.csv
sqlite3 temp.3.db "select SAMPLE, SAMPLE_LOCATION as SAMPLE_INDOOR from tbl1 where LOCATION='I';" > temp.5.csv
sqlite3 temp.3.db "select SAMPLE, SAMPLE_LOCATION as SAMPLE_OUTDOOR from tbl1 where LOCATION='O';" > temp.6.csv
joiner 'SAMPLE' temp.4.csv temp.5.csv > temp.7.csv
joiner 'SAMPLE' temp.7.csv temp.6.csv | grep -v "\,NA" | sponge temp.7.csv
csvtool namedcol SAMPLE,SAMPLE_INDOOR,SAMPLE_OUTDOOR,STATE_FIPS,COUNTY_FIPS,IFR_COUNTY,IFR_STATE,R0 temp.7.csv > $sOutputPathPaired
mv temp.8.csv $sOutputPathUnpaired

rm temp.*.*
