#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

paste -d\, <(cat $sTaxonAbbreviationsPath) <(cut -d\, -f2 $sTaxonAbbreviationsPath | sed "1 s|TAXON_ID_SHORT|GROUP|g") > temp.1.csv
sed "s|\r||g" $sTaxaPassingPrevalencePath | sed -e "1 s|$|,INCLUDE|g" -e "2,$ s|$|\,true|g" > temp.2.csv
joiner 'TAXON_ID' temp.1.csv temp.2.csv | sed "s|\,NA|,false|g" > taxon-groups-all-taxa.csv

rm temp.*.*
