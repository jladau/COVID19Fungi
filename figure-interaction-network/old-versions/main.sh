#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

sInteractionsPath=/home/jladau/Desktop/covid-19-microbiome/final-version/effects-and-interactions/interactions.csv
sEffectsPath=/home/jladau/Desktop/covid-19-microbiome/final-version/effects-and-interactions/effects.csv

cd $sIODir

rm -f temp.1.db
sqlite3 temp.1.db ".import $sInteractionsPath tbl1"
sqlite3 temp.1.db "select FACTOR_1, FACTOR_2, FACTOR_1_SIZE, OBSERVED as OBSERVED_INTERACTION, PR_GTE from tbl1;" > temp.2.csv
sqlite3 temp.1.db "select FACTOR_2 as FACTOR_1, FACTOR_1 as FACTOR_2, FACTOR_2_SIZE as FACTOR_1_SIZE, OBSERVED as OBSERVED_INTERACTION, PR_GTE from tbl1;" | tail -n+2 >> temp.2.csv

rm -f temp.3.db
sqlite3 temp.3.db ".import $sEffectsPath tbl1"
sqlite3 temp.3.db "select TAXA as FACTOR_1, OBSERVED as OBSERVED_EFFECT_FACTOR_1 from tbl1;" > temp.4.csv
joiner 'FACTOR_1' temp.2.csv temp.4.csv > temp.5.csv

sed -i "s|Eur511\;Wal1582\;Asp109|EAW|g" temp.5.csv
sed -i "s|uni1835\;Alt29|AM|g" temp.5.csv
sed -i "s|Epi494|E|g" temp.5.csv
sed -i "s|Tox1500|T|g" temp.5.csv

mv temp.5.csv cytoscape-data.csv

rm temp.*.*

