#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

for i in {0..15}
do

	sStartDate=${rgsStartDates[i]}
	sEndDate=${rgsEndDates[i]}
	iStartTime=`sqlite3 temp.0.db "select cast(julianday('$sStartDate') as integer);" | tail -n+2 | sed "s|\r||g"`
	iEndTime=`sqlite3 temp.0.db "select cast(julianday('$sEndDate') as integer);" | tail -n+2 | sed "s|\r||g"`
	sOutputSuffix=$sStartDate'_'$sEndDate
	
	java -cp $sJavaDir/Covid.jar gov.lbnl.Estimator.EstimatorLauncher \
		--sDataPath=$sIODir/output.csv \
		--iRandomSeed=1234 \
		--iStartTime=$iStartTime \
		--iEndTime=$iEndTime \
		--iWindowSize='-1' \
		--sMode=infection_fatality_rate \
		--sOutputPath=$sIODir/infection-fatality-rate.csv

	#infection fatality rate maps
	rm -f temp.2.db
	sqlite3 temp.2.db ".import $sIODir/infection-fatality-rate.csv tbl1"
	sqlite3 temp.2.db "select COUNTY_FIPS, STATE_FIPS, 1000*cast(VALUE as real) as COUNTY_RATE from tbl1 where not(COUNTY_FIPS='NA');" > temp.3.csv
	sqlite3 temp.2.db "select STATE_FIPS, 1000*cast(VALUE as real) as STATE_RATE from tbl1 where COUNTY_FIPS='NA' and not(STATE_FIPS='NA');" > temp.4.csv
	joiner 'STATE_FIPS' temp.3.csv temp.4.csv > infection-fatality-rate-map-$sOutputSuffix.csv
	echo '"String","String","Real","Real"' > infection-fatality-rate-map-$sOutputSuffix.csvt

	#joining to sample file
	joiner 'COUNTY_FIPS,STATE_FIPS' sample-fips-map/sample-fips-map.csv infection-fatality-rate-map-$sOutputSuffix.csv | sed -e "1 s|COUNTY_RATE|IFR_COUNTY|g" -e "1 s|STATE_RATE|IFR_STATE|g" > ifr-estimates-$sOutputSuffix.csv
done

#cleaning up
rm -f temp.*.*
rm -f infection-fatality-rate.csv
rm -f output.csv
