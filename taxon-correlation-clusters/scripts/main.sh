#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

#finding correlations
java -cp $sJavaDir/Utilities.jar edu.ucsf.BIOM.PairwiseTaxonCorrelations.PairwiseTaxonCorrelationsLauncher \
	--sBIOMPath=$sBIOMPath \
	--sTaxonRank=$sTaxonRank \
	--bRemoveUnclassified=true \
	--sOutputPath=$sIODir/temp.1.csv \
	--sObservationsToKeepPath=$sTaxaPassingPrevalencePath \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath
mv temp.1.csv pairwise-correlations.csv

#finding correlation pairs
rm -f temp.48.db
sqlite3 temp.48.db ".import $sIODir/pairwise-correlations.csv tbl1"
sqlite3 temp.48.db "select TAXON_1 as TAXON_ID_1, TAXON_2 as TAXON_ID_2 from tbl1 where cast(SPEARMAN as real)>0.5;" > temp.49.csv
sed -e "1 s|TAXON_ID\,|TAXON_ID_1,|g" -e "1 s|TAXON_ID_SHORT|TAXON_ID_SHORT_1|g" $sTaxonAbbreviationsPath > temp.57.csv
joiner 'TAXON_ID_1' temp.49.csv temp.57.csv | sponge temp.49.csv
sed -e "1 s|TAXON_ID\,|TAXON_ID_2,|g" -e "1 s|TAXON_ID_SHORT|TAXON_ID_SHORT_2|g" $sTaxonAbbreviationsPath > temp.57.csv
joiner 'TAXON_ID_2' temp.49.csv temp.57.csv | sponge temp.49.csv
cut -d\, -f3-4 temp.49.csv | sponge temp.49.csv
mv temp.49.csv correlated-taxon-pairs.csv

rm temp.*.*
