#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

sqlite3 $sInteractionsDBPath "select FACTOR_1, FACTOR_2, FACTOR_1_SIZE, FACTOR_2_SIZE, OBSERVED as OBSERVED_INTERACTION, PR_GTE, 
(case when FACTOR_1 like '%Eur511;Wal1582;Asp109%' then 'EAW' else '' end) as EAW_1,
(case when FACTOR_2 like '%Eur511;Wal1582;Asp109%' then 'EAW' else '' end) as EAW_2,
(case when FACTOR_1 like '%Tox1500%' then 'T' else '' end) as T_1,
(case when FACTOR_2 like '%Tox1500%' then 'T' else '' end) as T_2,
(case when FACTOR_1 like '%Epi494%' then 'E' else '' end) as E_1,
(case when FACTOR_2 like '%Epi494%' then 'E' else '' end) as E_2,
(case when FACTOR_1 like '%uni1835;Alt29%' then 'AM' else '' end) as AM_1,
(case when FACTOR_2 like '%uni1835;Alt29%' then 'AM' else '' end) as AM_2
from tbl1;" > temp.2.csv

rm -f temp.7.db
sqlite3 temp.7.db ".import $sIODir/temp.2.csv tbl1"
sqlite3 temp.7.db "select FACTOR_1 as FACTOR_1_SHORT, FACTOR_2 as FACTOR_2_SHORT, (EAW_1 || '+' || T_1 || '+' || E_1 || '+' || AM_1) as FACTOR_1, (EAW_2 || '+' || T_2 || '+' || E_2 || '+' || AM_2) as FACTOR_2, (EAW_1 || EAW_2 || '+' || T_1 || T_2 || '+' || E_1 || E_2 || '+' || AM_1 || AM_2) as FACTOR_MERGED, FACTOR_1_SIZE, FACTOR_2_SIZE, OBSERVED_INTERACTION from tbl1;" | sed "s|\+\+|\+|g" | sed "s|\,+|,|g" | sed "s|+\,|,|g" | sed "s|^\+||g" > temp.4.csv

rm -f temp.5.db
sqlite3 temp.5.db ".import $sIODir/temp.4.csv tbl1"
sqlite3 temp.5.db "select FACTOR_1_SHORT, FACTOR_1, FACTOR_MERGED, FACTOR_1_SIZE, OBSERVED_INTERACTION from tbl1;" > temp.6.csv
sqlite3 temp.5.db "select FACTOR_2_SHORT as FACTOR_1_SHORT, FACTOR_2 as FACTOR_1, FACTOR_MERGED, FACTOR_2_SIZE as FACTOR_1_SIZE, OBSERVED_INTERACTION from tbl1;" | tail -n+2 >> temp.6.csv
sqlite3 temp.5.db "select 'Eur511;Wal1582;Asp109 + Tox1500 + uni1835;Alt29 + Epi494' as FACTOR_1_SHORT, 'EAW+T+E+AM' as FACTOR_1, 'EAW+T+E+AM' as FACTOR_MERGED, '4' as FACTOR_1_SIZE, '1' as OBSERVED_INTERACTION;" | tail -n+2 >> temp.6.csv

sqlite3 $sEffectsDBPath "select TAXA as FACTOR_1_SHORT, OBSERVED as OBSERVED_EFFECT_FACTOR_1 from tbl1;" > temp.4.csv
joiner 'FACTOR_1_SHORT' temp.6.csv temp.4.csv > temp.5.csv

mv temp.5.csv cytoscape-data.csv

rm temp.*.*

