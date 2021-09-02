#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

#TODO just consider samples for which we have paired data in biom file

java -cp $sJavaDir/Utilities.jar edu.ucsf.BIOM.PrintIDs.PrintIDsLauncher \
	--sDataPath=$sBIOMPath \
	--sOutputPath=$sIODir/temp.1.csv \
	--sAxis=sample \
	--sTaxonRank=$sTaxonRank \
	--bRemoveUnclassified=true

sed -i -e "1 s|$|\,DATA_AVAILABLE|g" -e "2,$ s|$|\,true|g" temp.1.csv
sed -i "1 s|SAMPLE|SAMPLE_INDOOR|g" temp.1.csv
joiner 'SAMPLE_INDOOR' $sPairedDataPath temp.1.csv > temp.2.csv
sed -i "1 s|SAMPLE_INDOOR|SAMPLE_OUTDOOR|g" temp.1.csv
joiner 'SAMPLE_OUTDOOR' temp.2.csv temp.1.csv | sponge temp.2.csv
cut -d\, -f1-3,9-10 temp.2.csv | grep -v '\,NA' > temp.3.csv

echo "SAMPLE_ID" > samples-with-complete-data.csv
cut -d\, -f2 temp.3.csv | tail -n+2 >> samples-with-complete-data.csv
cut -d\, -f3 temp.3.csv | tail -n+2 >> samples-with-complete-data.csv

#cleaning up
rm -f temp.*.*
