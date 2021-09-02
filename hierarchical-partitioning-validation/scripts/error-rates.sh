#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1
sAnalysisType=$2

cd $sIODir

if [[ "$sAnalysisType" == 'cluster' ]]
then
	#finding rates: clusters
	sqlite3 temp.10.db "select TAXON_ID_SHORT, PREVALENCE, INFERENCE_CLUSTER as INFERENCE, ACTUAL_ASSOCIATION_CLUSTER as ACTUAL_ASSOCIATION, (case when ACTUAL_ASSOCIATION_CLUSTER='associated' and INFERENCE_CLUSTER='associated' then 'true_positive' when ACTUAL_ASSOCIATION_CLUSTER='associated' and INFERENCE_CLUSTER='not_associated' then 'false_negative' when ACTUAL_ASSOCIATION_CLUSTER='not_associated' and INFERENCE_CLUSTER='not_associated' then 'true_negative' else 'false_positive' end) as RESULT from tbl1;" > temp.17.csv

else

	#finding rates: no clusters
	sqlite3 temp.10.db "select TAXON_ID_SHORT, PREVALENCE, INFERENCE_TAXON as INFERENCE, ACTUAL_ASSOCIATION_TAXON as ACTUAL_ASSOCIATION, (case when ACTUAL_ASSOCIATION_TAXON='associated' and INFERENCE_TAXON='associated' then 'true_positive' when ACTUAL_ASSOCIATION_TAXON='associated' and INFERENCE_TAXON='not_associated' then 'false_negative' when ACTUAL_ASSOCIATION_TAXON='not_associated' and INFERENCE_TAXON='not_associated' then 'true_negative' else 'false_positive' end) as RESULT from tbl1;" > temp.17.csv
fi

rm -f temp.18.db
sqlite3 temp.18.db ".import $sIODir/temp.17.csv tbl1"
sqlite3 temp.18.db "select TAXON_ID_SHORT, PREVALENCE, count(*) as NEGATIVE_COUNT from tbl1 where ACTUAL_ASSOCIATION='not_associated' group by TAXON_ID_SHORT;" > temp.19.csv
sqlite3 temp.18.db "select TAXON_ID_SHORT, PREVALENCE, count(*) as FALSE_POSITIVE_COUNT from tbl1 where RESULT='false_positive' group by TAXON_ID_SHORT;" > temp.20.csv
sqlite3 temp.18.db "select TAXON_ID_SHORT, PREVALENCE, count(*) as POSITIVE_COUNT from tbl1 where ACTUAL_ASSOCIATION='associated' group by TAXON_ID_SHORT;" > temp.21.csv
sqlite3 temp.18.db "select TAXON_ID_SHORT, PREVALENCE, count(*) as TRUE_POSITIVE_COUNT from tbl1 where RESULT='true_positive' group by TAXON_ID_SHORT;" > temp.22.csv
joiner 'TAXON_ID_SHORT,PREVALENCE' temp.19.csv temp.20.csv | sed "s|\,NA|\,0|g" > temp.23.csv
joiner 'TAXON_ID_SHORT,PREVALENCE' temp.21.csv temp.22.csv | sed "s|\,NA|\,0|g" > temp.24.csv
rm -f temp.25.db
sqlite3 temp.25.db ".import $sIODir/temp.23.csv tbl1"
sqlite3 temp.25.db "select TAXON_ID_SHORT, cast(FALSE_POSITIVE_COUNT as real)/cast(NEGATIVE_COUNT as real) as FALSE_POSITIVE_RATE_${sAnalysisType^^} from tbl1 order by cast(PREVALENCE as integer);" | sed "s|\r||g" > temp.42.csv
rm -f temp.26.db
sqlite3 temp.26.db ".import $sIODir/temp.24.csv tbl1"
sqlite3 temp.26.db "select TAXON_ID_SHORT, cast(TRUE_POSITIVE_COUNT as real)/cast(POSITIVE_COUNT as real) as TRUE_POSITIVE_RATE_${sAnalysisType^^} from tbl1 order by cast(PREVALENCE as integer);" | sed "s|\r||g" > temp.43.csv

sqlite3 temp.18.db "select distinct TAXON_ID_SHORT, PREVALENCE from tbl1;" > temp.41.csv
joiner 'TAXON_ID_SHORT' temp.41.csv temp.42.csv > temp.44-$sAnalysisType.csv
joiner 'TAXON_ID_SHORT' temp.44-$sAnalysisType.csv temp.43.csv | sed "s|\,NA|,na|g" | sponge temp.44-$sAnalysisType.csv
