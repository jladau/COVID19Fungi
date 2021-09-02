#!/bin/bash
source $1

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

#loading taxa to consider: making taxon groups file
paste -d\, <(cat $sTaxonAbbreviationsPath) <(cut -d\, -f2 $sTaxonAbbreviationsPath | sed "1 s|TAXON_ID_SHORT|GROUPX|g") > temp.1.csv
joiner 'TAXON_ID,TAXON_ID_SHORT' $sAbundancePrevalencePath temp.1.csv  > temp.9.csv
rm -f temp.10.db
sqlite3 temp.10.db ".import $sIODir/temp.9.csv tbl1"

#50/50 split between associated and unassociated taxa
iRows=`wc -l temp.9.csv | cut -d' ' -f1`
iRows=$((iRows-1))
sqlite3 temp.10.db "select TAXON_ID, TAXON_ID_SHORT, GROUPX from tbl1 order by random() limit $iRows/2;" | sed "1 s|GROUPX|GROUP|g" > correlated-taxa.csv


#looping through data sets
for i in {1..100}
do
	bash $sIODir/scripts/iterator.sh $1 $i
done

