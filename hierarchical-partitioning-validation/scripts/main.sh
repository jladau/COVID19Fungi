#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

<<COMMENT1

<<COMMENT0
#running tests
for i in {1..100}
do
	bash $sIODir/scripts/iterator.sh $1 $i
done
COMMENT0

#merging results
head --lines=1 standardized-effect-sizes-1.csv | sed "s|^|DATA_SET_ID,|g" > standardized-effect-sizes.csv
for i in {1..100}
do
	tail -n+2 standardized-effect-sizes-$i.csv | sed "s|^|$i,|g" >> standardized-effect-sizes.csv
done
sed -i "1 s|TAXON\,|TAXON_ID_SHORT,|g" standardized-effect-sizes.csv

COMMENT1

#finding inferences
rm -f temp.4.db
sqlite3 temp.4.db ".import $sIODir/standardized-effect-sizes.csv tbl1"
sqlite3 temp.4.db "select TAXON_ID_SHORT, (case when cast(PR_GTE as real)<=0.05 and not(PR_GTE='na') then 'associated' else 'not_associated' end) as INFERENCE_TAXON, DATA_SET_ID from tbl1 where not(TAXON_ID_SHORT='all_taxa');" > temp.39.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.PercolateValuesThroughGraph.PercolateValuesThroughGraphLauncher \
	--sValuesPath=$sIODir/temp.39.csv \
	--sGraphPath=$sCorrelatedTaxonPairsPath \
	--sCategoryHeader=DATA_SET_ID \
	--sValueHeader=INFERENCE_TAXON \
	--sVertexHeader=TAXON_ID_SHORT \
	--sValueToPercolate=associated \
	--sOutputPath=$sIODir/temp.51.csv
sed -i "1 s|INFERENCE_TAXON|INFERENCE_CLUSTER|g" temp.51.csv
joiner 'DATA_SET_ID,TAXON_ID_SHORT' temp.51.csv temp.39.csv | sponge temp.39.csv

rm -f temp.30.db
sqlite3 temp.30.db ".import $sIODir/temp.39.csv tbl1"
sqlite3 temp.30.db "select DATA_SET_ID, TAXON_ID_SHORT, INFERENCE_CLUSTER, INFERENCE_TAXON from tbl1;" > temp.5.csv

#adding observed correlation criterion to inference
joiner 'TAXON_ID_SHORT,DATA_SET_ID' temp.5.csv standardized-effect-sizes.csv > temp.55.csv
mv temp.5.csv temp.5-0.csv
rm -f temp.56.db
sqlite3 temp.56.db ".import $sIODir/temp.55.csv tbl1"
sqlite3 temp.56.db "select DATA_SET_ID, TAXON_ID_SHORT, (case when INFERENCE_CLUSTER='associated' and cast(OBSERVED as real)>0.01 then 'associated' else 'not_associated' end) as INFERENCE_CLUSTER, INFERENCE_TAXON from tbl1;" | sed "s|\r||g" > temp.5.csv

#finding actual states
sed -e "1 s|$|,ACTUAL_ASSOCIATION|g" -e "2,$ s|$|,associated|g"  $sValidationCorrelatedTaxaPath > temp.31.csv
rm -f temp.35.db
sqlite3 temp.35.db ".import $sIODir/temp.31.csv tbl1"
sqlite3 temp.35.db "select '0' as DATA_SET_ID, TAXON_ID_SHORT, ACTUAL_ASSOCIATION as ACTUAL_ASSOCIATION_TAXON from tbl1;" > temp.36.csv
joiner 'TAXON_ID_SHORT' $sTaxonAbbreviationsPath temp.36.csv | sed "s|\,NA\,NA|,0,not_associated|g" > temp.37.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.PercolateValuesThroughGraph.PercolateValuesThroughGraphLauncher \
	--sValuesPath=$sIODir/temp.37.csv \
	--sGraphPath=$sCorrelatedTaxonPairsPath \
	--sCategoryHeader=DATA_SET_ID \
	--sValueHeader=ACTUAL_ASSOCIATION_TAXON \
	--sVertexHeader=TAXON_ID_SHORT \
	--sValueToPercolate=associated \
	--sOutputPath=$sIODir/temp.38.csv
sed -i "1 s|ACTUAL_ASSOCIATION_TAXON|ACTUAL_ASSOCIATION_CLUSTER|g" temp.38.csv 
joiner 'TAXON_ID_SHORT,DATA_SET_ID' temp.37.csv temp.38.csv > temp.51.csv
joiner 'TAXON_ID_SHORT,TAXON_ID' temp.51.csv $sAbundancePrevalencePath > temp.54.csv
rm -f temp.52.db
sqlite3 temp.52.db ".import $sIODir/temp.54.csv tbl1"
sqlite3 temp.52.db "select TAXON_ID_SHORT, PREVALENCE, ACTUAL_ASSOCIATION_TAXON, ACTUAL_ASSOCIATION_CLUSTER from tbl1;" | sed "s|\r||g" > temp.53.csv

#joining inference and actual states
joiner 'TAXON_ID_SHORT' temp.5.csv temp.53.csv > temp.40.csv
rm -f associations.db
sqlite3 associations.db ".import $sIODir/temp.40.csv tbl1"

#finding false discovery rates
sqlite3 associations.db "select DATA_SET_ID, count(*) as S_CLUSTER from tbl1 where ACTUAL_ASSOCIATION_CLUSTER='associated' and INFERENCE_CLUSTER='associated' and cast(PREVALENCE as integer)>$iPrevalenceThreshold group by DATA_SET_ID;" | sed "s|\r||g" > temp.41.csv
sqlite3 associations.db "select DATA_SET_ID, count(*) as V_CLUSTER from tbl1 where ACTUAL_ASSOCIATION_CLUSTER='not_associated' and INFERENCE_CLUSTER='associated' and cast(PREVALENCE as integer)>$iPrevalenceThreshold group by DATA_SET_ID;" | sed "s|\r||g" > temp.42.csv
sqlite3 associations.db "select distinct DATA_SET_ID from tbl1;" > temp.43.csv
joiner 'DATA_SET_ID' temp.43.csv temp.41.csv > temp.44.csv
joiner 'DATA_SET_ID' temp.44.csv temp.42.csv | sponge temp.44.csv

sqlite3 associations.db "select DATA_SET_ID, count(*) as S_TAXON from tbl1 where ACTUAL_ASSOCIATION_TAXON='associated' and INFERENCE_TAXON='associated' and cast(PREVALENCE as integer)>$iPrevalenceThreshold group by DATA_SET_ID;" | sed "s|\r||g" > temp.41.csv
sqlite3 associations.db "select DATA_SET_ID, count(*) as V_TAXON from tbl1 where ACTUAL_ASSOCIATION_TAXON='not_associated' and INFERENCE_TAXON='associated' and cast(PREVALENCE as integer)>$iPrevalenceThreshold group by DATA_SET_ID;" | sed "s|\r||g" > temp.42.csv

joiner 'DATA_SET_ID' temp.44.csv temp.41.csv | sponge temp.44.csv
joiner 'DATA_SET_ID' temp.44.csv temp.42.csv | sponge temp.44.csv
sed -i "s|\,NA|\,0|g" temp.44.csv

rm -f temp.46.db
sqlite3 temp.46.db ".import $sIODir/temp.44.csv tbl1"
sqlite3 temp.46.db "select avg(FDR_TAXON) as FDR_TAXON, avg(FDR_CLUSTER) as FDR_CLUSTER from (select *, cast(V_TAXON as real)/(cast(V_TAXON as real)+cast(S_TAXON as real)) as FDR_TAXON, cast(V_CLUSTER as real)/(cast(V_CLUSTER as real)+cast(S_CLUSTER as real)) as FDR_CLUSTER from tbl1);" > error-rates-fdr.csv

#finding false positive and true positive rates
bash $sIODir/scripts/error-rates.sh $1 'taxa'
bash $sIODir/scripts/error-rates.sh $1 'cluster'

#joining results and exiting
joiner 'TAXON_ID_SHORT,PREVALENCE' temp.44-taxa.csv temp.44-cluster.csv > error-rates.csv
rm temp.*.*
