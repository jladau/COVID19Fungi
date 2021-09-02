#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1
	
cd $sIODir

#loading taxon names
java -cp $sJavaDir/Utilities.jar edu.ucsf.BIOM.PrintIDs.PrintIDsLauncher \
	--sDataPath=$sBIOMPath \
	--sOutputPath=$sIODir/temp.1.csv \
	--sAxis=observation \
	--sTaxonRank=$sTaxonRank \
	--bRemoveUnclassified=true
	
#finding abbreviations
cut -d\; -f6 temp.1.csv | sed "s|g__||g" | cut -c-3 > temp.2.csv
paste -d\, temp.1.csv temp.2.csv > temp.5.csv
rm -f temp.6.db
sqlite3 temp.6.db ".import $sIODir/temp.5.csv tbl1"
sqlite3 temp.6.db "select * from tbl1 order by OBS asc" | sed "s|\r||g" > temp.7.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.RowNumbers.RowNumbersLauncher \
	--sDataPath=$sIODir/temp.7.csv \
	--sOutputPath=$sIODir/temp.8.csv
paste -d\, <(cat temp.7.csv) <(cut -d\, -f1 temp.8.csv) > temp.9.csv
sed "s|\,||2g" temp.9.csv | tail -n+2 | sed "1 s|^|TAXON_ID\,TAXON_ID_SHORT\n|g" > taxon-abbreviations.csv

#cleaning up
rm temp.*.*
