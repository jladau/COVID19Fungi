#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

rm -f temp.1.db
sqlite3 temp.1.db ".import $sSelectedTaxaPath tbl1"
sqlite3 temp.1.db "select TAXON_ID, TAXON_ID_SHORT, TAXON_ID_SHORT as GROUPX, 'true' as INCLUDE from tbl1;" | sed "1 s|GROUPX|GROUP|g" | sed "s|\r||g" > taxon-groups-selected-taxa.csv
sqlite3 temp.1.db "select TAXON_ID, TAXON_ID_SHORT, TAXON_ID_SHORT as GROUPX, 'true' as INCLUDE from tbl1 where not(TAXON_ID_SHORT='Tox1500');" | sed "1 s|GROUPX|GROUP|g" | sed "s|\r||g" > taxon-groups-selected-taxa-no-tox1500.csv

rm temp.*.*
