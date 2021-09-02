#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

sqlite3 $sIFREstimatesPath "select distinct fips as REGION_ID from tbl1;" > output.csv
echo '"String","Real","Real"' > output.csvt
#for i in {0..5}
#for i in {0..4}
for i in {0..0}
do

	sDateStart=${rgsR0StartDates[i]}
	sDateEnd=${rgsR0EndDates[i]}
	sSuffix=`echo $sDateStart | sed "s|\-||g"`'_'`echo $sDateEnd | sed "s|\-||g"`

	sqlite3 $sIFREstimatesPath "select REGION_ID, row_number() over (partition by REGION_ID order by TIME) - 1 as SERIAL_INTERVAL, CASES from (select julianday(date)-0.5 as TIME, fips as REGION_ID, cast(cases as real) as CASES from tbl1 where TIME % 5 = 0 and not(REGION_ID like '00%') and cast(CASES as real)>0 and TIME>=julianday('$sDateStart') and TIME<=julianday('$sDateEnd')) order by REGION_ID, TIME;" > temp.2.csv

	rm -f temp.5.db
	sqlite3 temp.5.db ".import $sIODir/temp.2.csv tbl1"
	sqlite3 temp.5.db "select REGION_ID, CASES as CASES_0 from tbl1 where cast(SERIAL_INTERVAL as real)=0;" > temp.6.csv
	joiner 'REGION_ID' temp.2.csv temp.6.csv > temp.7.csv
	rm -f temp.8.db
	sqlite3 temp.8.db ".import $sIODir/temp.7.csv tbl1"
	sqlite3 temp.8.db "select REGION_ID, SERIAL_INTERVAL, cast(SERIAL_INTERVAL as real)*cast(SERIAL_INTERVAL as real) as SERIAL_INTERVAL2, log(cast(CASES as real)/cast(CASES_0 as real)) as CASES_NORMALIZED_LOG from tbl1 where not(SERIAL_INTERVAL=0);" > temp.9.csv

	java -cp $sJavaDir/Utilities.jar edu.ucsf.LinearModelsWithinCategories.LinearModelsWithinCategoriesLauncher \
		--sDataPath=$sIODir/temp.9.csv \
		--sCategory=REGION_ID \
		--sResponse=CASES_NORMALIZED_LOG \
		--setPredictors='SERIAL_INTERVAL,SERIAL_INTERVAL2' \
		--bNoIntercept=true \
		--sOutputPath=$sIODir/temp.3.csv
		
	rm -f temp.4.db
	sqlite3 temp.4.db ".import $sIODir/temp.3.csv tbl1"
	sqlite3 temp.4.db "select CATEGORY as REGION_ID, exp(cast(VALUE as real)) as R0_ESTIMATE_$sSuffix from tbl1 where COEFFICIENT='SERIAL_INTERVAL';" > temp.10.csv
	#joiner 'REGION_ID' output.csv temp.10.csv | sed "s|\,NA|\,0|g" | sponge output.csv
	joiner 'REGION_ID' output.csv temp.10.csv | sponge output.csv
	sqlite3 temp.4.db "select CATEGORY as REGION_ID, exp(-1*cast(VALUE as real))-1 as D_ESTIMATE_$sSuffix from tbl1 where COEFFICIENT='SERIAL_INTERVAL2';" > temp.10.csv
	joiner 'REGION_ID' output.csv temp.10.csv | sponge output.csv
done

sed -i "1 s|REGION_ID|COUNTY_FIPS|g" output.csv
mv output.csv r0-estimates.csv
mv output.csvt r0-estimates.csvt

rm temp.*.*
