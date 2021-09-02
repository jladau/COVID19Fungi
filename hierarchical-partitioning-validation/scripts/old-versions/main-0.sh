#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

sResponseDataPath=/home/jladau/Desktop/covid-19-microbiome/final-version/in-progress/validation-data/simulated-correlated-response-data-$iValidationDataSetID.csv
sCorrelatedTaxaPath=/home/jladau/Desktop/covid-19-microbiome/final-version/in-progress/validation-data/correlated-taxa.csv
sClustersPath=/home/jladau/Desktop/covid-19-microbiome/final-version/in-progress/taxon-correlation-clusters/taxon-correlation-clusters-r0.5.csv
iNullIterations=100
#iValidationDataSetID=`basename $sResponseDataPath | cut -d\- -f5 | cut -d\. -f1`

cd $sIODir

<<COMMENT1

#making taxon groups file
paste -d\, <(cat $sTaxonAbbreviationsPath) <(cut -d\, -f2 $sTaxonAbbreviationsPath | sed "1 s|TAXON_ID_SHORT|GROUP|g") > temp.1.csv
joiner 'TAXON_ID_SHORT,TAXON_ID' temp.1.csv $sAbundancePrevalencePath | sed "1 s|GROUP|GROUPX|g" > temp.2.csv
rm -f temp.3.db
sqlite3 temp.3.db ".import $sIODir/temp.2.csv tbl1"
sqlite3 temp.3.db "select TAXON_ID, TAXON_ID_SHORT, GROUPX, 'true' as INCLUDE from tbl1 order by TAXON_ID_SHORT limit 600;" | sed "1 s|GROUPX|GROUP|g" | sed "s|\r||g" > temp.4.csv
sqlite3 temp.3.db "select TAXON_ID, TAXON_ID_SHORT, GROUPX from tbl1;" | sed "1 s|GROUPX|GROUP|g" | sed "s|\r||g" > temp.5.csv
joiner 'TAXON_ID,TAXON_ID_SHORT,GROUP' temp.5.csv temp.4.csv | sed "s|\,NA|\,false|g" > temp.6.csv
mv temp.6.csv taxon-groups.csv

<<COMMENT0
#running tests
for i in {1..100}
do
	bash scripts/iterator.sh $1 $i
done
COMMENT0

#merging results
head --lines=1 standardized-effect-sizes-1.csv | sed "s|^|DATA_SET_ID,|g" > standardized-effect-sizes.csv
for i in {1..100}
do
	tail -n+2 standardized-effect-sizes-$i.csv | sed "s|^|$i,|g" >> standardized-effect-sizes.csv
done

COMMENT1

#finding inference
rm -f temp.4.db
sqlite3 temp.4.db ".import $sIODir/standardized-effect-sizes.csv tbl1"
sqlite3 temp.4.db "select TAXON as TAXON_ID_SHORT, (case when not(PR_GTE='na') and cast(PR_GTE as real)<=0.05 then 'associated' else 'not_associated' end) as INFERENCE from tbl1 where not(TAXON='all_taxa');" > temp.5.csv 

exit

#finding actual state
#TODO some taxa here to do not have prevalences/abundances
#TODO single-linkage clustering appears to be working. Need to tune R^2 cutoff: tradeoff between too few clusters and type I and type II errors.
joiner 'TAXON_ID_SHORT' temp.5.csv $sAbundancePrevalencePath > temp.6.csv
joiner 'TAXON_ID_SHORT,TAXON_ID' temp.6.csv $sCorrelatedTaxaPath > temp.7.csv
sed -i "1 s|GROUP|GROUPX|g" temp.7.csv
rm -f temp.8.db
sqlite3 temp.8.db ".import $sIODir/temp.7.csv tbl1"
sqlite3 temp.8.db "select TAXON_ID_SHORT, PREVALENCE, INFERENCE, (case when GROUPX='NA' then 'not_associated' else 'associated' end) as POPULATION_TAXON from tbl1;" > temp.9.csv

#finding associated clusters
joiner 'TAXON_ID' $sClustersPath $sTaxonAbbreviationsPath > temp.12.csv
joiner 'TAXON_ID_SHORT' temp.9.csv temp.12.csv > temp.13.csv
rm -f temp.14.db
sqlite3 temp.14.db ".import $sIODir/temp.13.csv tbl1"
sqlite3 temp.14.db "select CLUSTER, (case when sum((case when POPULATION_TAXON='associated' then 1 else 0 end))=0 then 'not_associated' else 'associated' end) as POPULATION_CLUSTER from tbl1 group by CLUSTER;" > temp.15.csv
joiner 'CLUSTER' temp.13.csv temp.15.csv > temp.16.csv
rm -f temp.10.db
sqlite3 temp.10.db ".import temp.16.csv tbl1"

#sqlite3 temp.10.db "select TAXON_ID_SHORT, PREVALENCE, INFERENCE, POPULATION_CLUSTER as POPULATION, (case when POPULATION_CLUSTER='associated' and INFERENCE='associated' then 'true_positive' when POPULATION_CLUSTER='associated' and INFERENCE='not_associated' then 'false_negative' when POPULATION_CLUSTER='not_associated' and INFERENCE='not_associated' then 'true_negative' else 'false_positive' end) as RESULT from tbl1;" > temp.17.csv

sqlite3 temp.10.db "select TAXON_ID_SHORT, PREVALENCE, INFERENCE, POPULATION_TAXON as POPULATION, (case when POPULATION_TAXON='associated' and INFERENCE='associated' then 'true_positive' when POPULATION_TAXON='associated' and INFERENCE='not_associated' then 'false_negative' when POPULATION_TAXON='not_associated' and INFERENCE='not_associated' then 'true_negative' else 'false_positive' end) as RESULT from tbl1;" > temp.17.csv

rm -f temp.18.db
sqlite3 temp.18.db ".import $sIODir/temp.17.csv tbl1"
sqlite3 temp.18.db "select TAXON_ID_SHORT, PREVALENCE, count(*) as NEGATIVE_COUNT from tbl1 where POPULATION='not_associated' group by TAXON_ID_SHORT;" > temp.19.csv
sqlite3 temp.18.db "select TAXON_ID_SHORT, PREVALENCE, count(*) as FALSE_POSITIVE_COUNT from tbl1 where RESULT='false_positive' group by TAXON_ID_SHORT;" > temp.20.csv
sqlite3 temp.18.db "select TAXON_ID_SHORT, PREVALENCE, count(*) as POSITIVE_COUNT from tbl1 where POPULATION='associated' group by TAXON_ID_SHORT;" > temp.21.csv
sqlite3 temp.18.db "select TAXON_ID_SHORT, PREVALENCE, count(*) as TRUE_POSITIVE_COUNT from tbl1 where RESULT='true_positive' group by TAXON_ID_SHORT;" > temp.22.csv
joiner 'TAXON_ID_SHORT,PREVALENCE' temp.19.csv temp.20.csv | sed "s|\,NA|\,0|g" > temp.23.csv
joiner 'TAXON_ID_SHORT,PREVALENCE' temp.21.csv temp.22.csv | sed "s|\,NA|\,0|g" > temp.24.csv
rm -f temp.25.db
sqlite3 temp.25.db ".import $sIODir/temp.23.csv tbl1"
sqlite3 temp.25.db "select TAXON_ID_SHORT, PREVALENCE, cast(FALSE_POSITIVE_COUNT as real)/cast(NEGATIVE_COUNT as real) as FALSE_POSITIVE_RATE from tbl1 order by cast(PREVALENCE as integer);" | sed "s|\r||g" > false-positive-rates.csv
rm -f temp.26.db
sqlite3 temp.26.db ".import $sIODir/temp.24.csv tbl1"
sqlite3 temp.26.db "select TAXON_ID_SHORT, PREVALENCE, cast(TRUE_POSITIVE_COUNT as real)/cast(POSITIVE_COUNT as real) as TRUE_POSITIVE_RATE from tbl1 order by cast(PREVALENCE as integer);" | sed "s|\r||g" > true-positive-rates.csv

paste -d\, false-positive-rates.csv true-positive-rates.csv > error-rates.csv

#rm temp.*.*
