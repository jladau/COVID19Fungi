#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1
	
cd $sIODir

#finding abundance and prevalence
java -cp $sJavaDir/Utilities.jar edu.ucsf.BIOM.PrevalenceRelativeAbundance.PrevalenceRelativeAbundanceLauncher \
	--bNormalize=false \
	--bRemoveUnclassified=true \
	--sDataPath=$sBIOMPath \
	--sTaxonRank=$sTaxonRank \
	--sOutputPath=$sIODir/temp.1.csv \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath
sed -i "1 s|^TAXON|TAXON_ID|g" temp.1.csv
joiner 'TAXON_ID' temp.1.csv $sTaxonAbbreviationsPath > temp.2.csv
rm -f temp.3.db
sqlite3 temp.3.db ".import $sIODir/temp.2.csv tbl1"
sqlite3 temp.3.db "select TAXON_ID, TAXON_ID_SHORT, PREVALENCE, RELATIVE_ABUNDANCE_MEAN, RELATIVE_ABUNDANCE_MAXIMUM from tbl1 order by cast(PREVALENCE as real) desc;" > taxon-abundance-prevalence.csv
sqlite3 temp.3.db "select TAXON_ID from tbl1 where cast(PREVALENCE as real)>=$iPrevalenceThresholdInitial;" > taxa-passing-prevalence-threshold.csv

#cleaning up
rm -f temp.*.*
