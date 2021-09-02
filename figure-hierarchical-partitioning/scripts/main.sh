#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

sed "1 s|TAXON|TAXON_ID_SHORT|g" $sHierarchicalPartitioningSESPath > temp.2.csv
joiner 'TAXON_ID_SHORT' temp.2.csv $sAbundancePrevalencePath | grep -v "\,NA" > temp.1.csv
rm -f temp.3.db
sqlite3 temp.3.db ".import $sIODir/temp.1.csv tbl1"
sqlite3 temp.3.db "select TAXON_ID_SHORT, TAXON_ID, PREVALENCE, OBSERVED, SES, PR_GTE, (case when (cast(PR_GTE as real)<=0.05 and not(PR_GTE='na') and cast(PREVALENCE as real)>=$iPrevalenceThreshold) then OBSERVED else 'na' end) as OBSERVED_SIGNIFICANT from tbl1 order by cast(OBSERVED as real) desc;" | sed "s|\r||g" > temp.4.csv
bash $sScriptsDir/UpdateGnumericGraph.sh graph-templates/figure-hierarchical-partitioning-template.xml temp.4.csv figure-hierarchical-partitioning.xml
rm temp.*.*

