#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

rgsA=('uni1835;Alt29' 'uni1835;Alt29' 'Eur511;Wal1582;Asp109' 'Eur511;Wal1582;Asp109 + uni1835;Alt29')
rgsB=('Eur511;Wal1582;Asp109' 'Tox1500' 'uni1835;Alt29 + Epi494' 'Tox1500 + Epi494')
rgsAB=('Eur511;Wal1582;Asp109 + uni1835;Alt29' 'Tox1500 + uni1835;Alt29' 'Eur511;Wal1582;Asp109 + uni1835;Alt29 + Epi494' 'Eur511;Wal1582;Asp109 + Tox1500 + uni1835;Alt29 + Epi494')
rgsAAlias=('AM' 'AM' 'EAW' 'EAW+AM')
rgsBAlias=('EAW' 'T' 'E+AM' 'T+E')

for i in {0..3}
do	
	sA=${rgsA[i]}
	sB=${rgsB[i]}
	sAB=${rgsAB[i]}
	sAAlias=${rgsAAlias[i]}
	sBAlias=${rgsBAlias[i]}
	sABAlias=$sAAlias'x'$sBAlias
	
	sqlite3 $sEffectsDBPath "select (case when TAXA='$sA' then '1' when TAXA='$sAB' then '2' end) as X, TAXA, NUMBER_INDIVIDUAL_TAXA, OBSERVED, NULL_MEAN, cast(NULL_MEAN as real)-cast(NULL_STDEV as real) as NULL_LB, cast(NULL_MEAN as real)+cast(NULL_STDEV as real) as NULL_UB from tbl1 where TAXA='$sA' or TAXA='$sAB' order by cast(X as integer);" > temp.15.csv
	echo '' >> temp.15.csv
	sqlite3 $sEffectsDBPath "select (case when TAXA='none' then '1' when TAXA='$sB' then '2' end) as X, TAXA, NUMBER_INDIVIDUAL_TAXA, OBSERVED, NULL_MEAN, cast(NULL_MEAN as real)-cast(NULL_STDEV as real) as NULL_LB, cast(NULL_MEAN as real)+cast(NULL_STDEV as real) as NULL_UB from tbl1 where TAXA='none' or TAXA='$sB' order by cast(X as integer);" | tail -n+2 >> temp.15.csv
	
	sed -e "s|XXXX|$sAAlias|g" -e "s|YYYY|$sBAlias|g" graph-templates/interaction-plots-template.xml > temp.16.xml
	bash $sScriptsDir/UpdateGnumericGraph.sh temp.16.xml temp.15.csv interactions-$sABAlias.xml
done

rm temp.*.*

