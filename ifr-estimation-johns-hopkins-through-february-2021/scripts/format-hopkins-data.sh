#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

echo 'Initializing output...'
echo 'date,county,state,fips,cases,deaths' > temp.1.csv

#----------------------------------------------------
#FINDING NUMBERS OF DEATHS

sDataPath=$sCountyMortalityPath

echo 'Reformatting dates...'
#old versions of raw data file
#s1=`cut -d\, -f13- $sDataPath | head --lines=1`
#echo $s1 | sed -e "s|\,|\n|g" -e "s|\/|\-|g" > temp.5.csv
#paste -d\- <(cut -d\; -f1 temp.4.csv) <(cut -d\; -f2 temp.4.csv | sed "s|^|0|g" | grep -o '..$') <(cut -d\; -f2 temp.4.csv | sed "s|^|0|g" | grep -o '..$') > temp.5.csv
#new version of raw data file
s1=`cut -d\, -f13- $sDataPath | head --lines=1`
echo $s1 | sed -e "s|\,|\n|g" -e "s|\/|\-|g" > temp.5.csv

paste -d\- <(cut -d\- -f3 temp.5.csv | sed "s|^|20|g") <(cut -d\- -f1 temp.5.csv | sed "s|^|0|g" | grep -o '..$') <(cut -d\- -f2 temp.5.csv | sed "s|^|0|g" | grep -o '..$') > temp.11.csv
mv temp.11.csv temp.5.csv

s3=`tr '\n' '\,' < temp.5.csv | sed "s|\,$||g"`
s2=`cut -d\, -f1-12 $sDataPath| head --lines=1`','$s3
echo $s2 > temp.6.csv
tail -n+2 $sDataPath >> temp.6.csv

echo 'Reformatting fips codes...'
cut -d\, -f5 temp.6.csv | tail -n+2 | sed "s|^|00000|g" | grep -o '.....$' | sed "1,1 s|^|fips\n|g" > temp.7.csv
paste -d\, <(cut -d\, -f1-4 temp.6.csv) <(cat temp.7.csv) <(cut -d\, -f6- temp.6.csv) > temp.8.csv

echo 'Flattening data file...'
cut -d\, -f5-7,13- temp.8.csv > temp.2.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.PivotTableToFlatFile.PivotTableToFlatFileLauncher \
	--sDataPath=$sIODir/temp.2.csv \
	--lstColumnsToFlatten="$s3" \
	--sOutputPath=$sIODir/temp.3.csv

echo 'Rearranging columns...'
rm -f temp.9.db
sqlite3.2 temp.9.db ".import $sIODir/temp.3.csv tbl1"
sqlite3.2 temp.9.db "select FLAT_VAR_KEY as date, Admin2 as county, Province_State as state, fips, FLAT_VAR_VALUE as deaths from tbl1;" | sed -e "s|\,\,|\,na\,|g" -e "s|\"\"|na|g" -e "s|\"||g" > temp.10.csv
#----------------------------------------------------

#----------------------------------------------------
#FINDING NUMBERS OF CASES

sDataPath=$sCountyCasesPath

echo 'Reformatting dates...'
#new version of raw data file
s1=`cut -d\, -f12- $sDataPath | head --lines=1`
echo $s1 | sed -e "s|\,|\n|g" -e "s|\/|\-|g" > temp.5.csv
paste -d\- <(cut -d\- -f3 temp.5.csv | sed "s|^|20|g") <(cut -d\- -f1 temp.5.csv | sed "s|^|0|g" | grep -o '..$') <(cut -d\- -f2 temp.5.csv | sed "s|^|0|g" | grep -o '..$') > temp.11.csv
mv temp.11.csv temp.5.csv

s3=`tr '\n' '\,' < temp.5.csv | sed "s|\,$||g"`
s2=`cut -d\, -f1-11 $sDataPath | head --lines=1`','$s3
echo $s2 > temp.6.csv
tail -n+2 $sDataPath >> temp.6.csv

echo 'Reformatting fips codes...'
cut -d\, -f5 temp.6.csv | tail -n+2 | sed "s|^|00000|g" | grep -o '.....$' | sed "1,1 s|^|fips\n|g" > temp.7.csv
paste -d\, <(cut -d\, -f1-4 temp.6.csv) <(cat temp.7.csv) <(cut -d\, -f6- temp.6.csv) > temp.8.csv

echo 'Flattening data file...'
cut -d\, -f5-7,12- temp.8.csv > temp.2.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.PivotTableToFlatFile.PivotTableToFlatFileLauncher \
	--sDataPath=$sIODir/temp.2.csv \
	--lstColumnsToFlatten="$s3" \
	--sOutputPath=$sIODir/temp.3.csv

echo 'Rearranging columns...'
rm -f temp.9.db
sqlite3.2 temp.9.db ".import $sIODir/temp.3.csv tbl1"
sqlite3.2 temp.9.db "select FLAT_VAR_KEY as date, Admin2 as county, Province_State as state, fips, FLAT_VAR_VALUE as cases from tbl1;" | sed -e "s|\,\,|\,na\,|g" -e "s|\"\"|na|g" -e "s|\"||g" > temp.11.csv

#----------------------------------------------------

joiner 'date,county,state,fips' temp.11.csv temp.10.csv > temp.12.csv

echo 'Cleaning up...'
rm -f formatted-covid-data.db
sqlite3 formatted-covid-data.db ".import $sIODir/temp.12.csv tbl1"
rm temp.*.*
