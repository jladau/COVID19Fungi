#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

sClassificationsPath=$sIODir/raw-data/variable-classifications.csv
sResultsPath=$sIODir/raw-data/Convolved_Regression_All_Taxa.csv

cd $sIODir


#formatting elijah's r^2 results
tail -n+2 $sResultsPath | sed "1 s|^|VARIABLE,R2\n|g" > temp.1.csv
rm -f temp.2.db
sqlite3 temp.2.db ".import $sIODir/temp.1.csv tbl1"
sqlite3 temp.2.db "select VARIABLE, R2 as R2_SHUFFLED from tbl1 where VARIABLE like '%_shuffled';" | sed "s|_shuffled||g" > temp.3.csv
sqlite3 temp.2.db "select VARIABLE, R2 as R2 from tbl1 where not(VARIABLE like '%_shuffled');" > temp.4.csv
joiner 'VARIABLE' temp.3.csv temp.4.csv > temp.5.csv
joiner 'VARIABLE' temp.5.csv $sClassificationsPath > temp.6.csv

#correcting periods in names
rm -f temp.17.db
sqlite3 temp.17.db ".import $sIODir/temp.6.csv tbl1"
sqlite3 temp.17.db "select replace(VARIABLE,'.','-') as VARIABLE, R2, R2_SHUFFLED from tbl1 where CLASSIFICATION='NA' and cast(R2 as real)>cast(R2_SHUFFLED as real);" > temp.18.csv
sqlite3 temp.17.db "select VARIABLE, R2, R2_SHUFFLED from tbl1 where not(CLASSIFICATION='NA') and cast(R2 as real)>cast(R2_SHUFFLED as real);" > temp.18.csv
joiner 'VARIABLE' temp.18.csv $sClassificationsPath > temp.19.csv


java -cp $sJavaDir/Utilities.jar edu.ucsf.AppendIntegerIDs.AppendIntegerIDsLauncher \
	--sDataPath=$sIODir/temp.19.csv \
	--sField=CLASSIFICATION \
	--sOutputPath=$sIODir/temp.7.csv
	
#appending coordinates for raw data
echo 'CLASSIFICATION,X' > temp.20.csv
echo 'microbe,0.669' >> temp.20.csv
echo 'housing,0.801' >> temp.20.csv
echo 'demographic,0.934' >> temp.20.csv
echo 'covid-policy,1.068' >> temp.20.csv
echo 'climate-except-soil-ph,1.201' >> temp.20.csv
echo 'soil-ph,1.334' >> temp.20.csv

joiner 'CLASSIFICATION' temp.19.csv temp.20.csv > temp.21.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.IdenticalObservationNoise.IdenticalObservationNoiseLauncher \
	--sDataPath=$sIODir/temp.21.csv \
	--sCategoryHeader=CLASSIFICATION \
	--sValueHeader=X \
	--dOffset=0.05 \
	--sOutputPath=$sIODir/temp.22.csv
paste -d\, temp.22.csv <(cut -d\, -f5 temp.21.csv) > temp.23.csv
sed -i "1 s|X$|COLOR|g" temp.23.csv

rm -f temp.8.db
sqlite3 temp.8.db ".import $sIODir/temp.7.csv tbl1"
sqlite3 temp.8.db "select CLASSIFICATION, avg(cast(R2 as real)) as R2_MEAN, stdev(cast(R2 as real))/sqrt(count(R2)) as R2_STERR, median(cast(R2 as real)) as R2_MEDIAN, avg(cast(R2_SHUFFLED as real)) as R2_SHUFFLED_MEAN, stdev(cast(R2_SHUFFLED as real))/sqrt(count(R2)) as R2_SHUFFLED_STERR from tbl1 group by CLASSIFICATION order by R2_MEAN desc;" > temp.9.csv

java -cp $sJavaDir/Utilities.jar edu.ucsf.TransposeTable.TransposeTableLauncher \
	--sTablePath=$sIODir/temp.9.csv \
	--sOutputPath=$sIODir/temp.10.csv

#formatting beta-diversity prediction r^2 results
sed "s|\t|,|g" raw-data/RelativeImportance_soilpH.txt | sed -e "s|Covid\ Policy\ Features|covid-policy|g" -e "s|Housing\ Features|housing|g" -e "s|Demographic\ Features|demographic|g" -e "s|Climate\ Except\ Soil\ pH\ Features|climate-except-soil-ph|g" -e "s|Soil pH Features|soil-ph|g" -e "s|Feature\ Group|CLASSIFICATION|g" -e "s|Relative\ Importance|RELATIVE_IMPORTANCE|g" > temp.11.csv

joiner 'CLASSIFICATION' temp.11.csv temp.9.csv | sed "s|\,NA|,0|g" > temp.14.csv 
rm -f temp.15.db
sqlite3 temp.15.db ".import $sIODir/temp.14.csv tbl1"
sqlite3 temp.15.db "select CLASSIFICATION, RELATIVE_IMPORTANCE from tbl1 order by cast(R2_MEAN as real) desc;" > temp.16.csv

java -cp $sJavaDir/Utilities.jar edu.ucsf.TransposeTable.TransposeTableLauncher \
	--sTablePath=$sIODir/temp.16.csv \
	--sOutputPath=$sIODir/temp.12.csv

paste -d\, temp.23.csv temp.10.csv > temp.24.csv
paste -d\, temp.24.csv temp.12.csv > temp.13.csv

bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/template-ifr-prediction.xml temp.13.csv ifr-prediction.xml
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/template-beta-diversity-prediction.xml temp.13.csv beta-diversity-prediction.xml




rm temp.*.*

