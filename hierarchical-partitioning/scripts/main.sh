#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

#running partitioning
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=hierarchical_partitioning \
	--sOutputPath=$sIODir/temp.2.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=$iOrderingsHierarchical \
	--iNullIterations=$iNullIterationsHierarchical \
	--sBIOMPath=$sBIOMPath \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
	--sResponseDataPath=$sPairedDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sTaxonGroupsAllTaxaPath \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'
		
#calculating significance and standardized effect sizes
java -cp $sJavaDir/Utilities.jar edu.ucsf.StandardizedEffectSizes.StandardizedEffectSizesLauncher \
	--sDataPath=$sIODir/temp.2.csv \
	--rgsCategoryHeaders=TAXON \
	--sValueHeader=MARGINAL_PERFORMANCE_INCREASE \
	--sRandomizationHeader=INITIAL_RANDOMIZATION \
	--iNullIterations=$iNullIterationsHierarchical \
	--sOutputPath=$sIODir/standardized-effect-sizes.csv

#finding inferences
sed "1 s|TAXON|TAXON_ID_SHORT|g" standardized-effect-sizes.csv | grep -v "all_taxa" > temp.6.csv
rm -f temp.4.db
sqlite3 temp.4.db ".import $sIODir/temp.6.csv tbl1"
sqlite3 temp.4.db "select TAXON_ID_SHORT, (case when cast(PR_GTE as real)<=0.05 and not(PR_GTE='na') then 'associated' else 'not_associated' end) as INFERENCE_TAXON, '0' as DATA_SET_ID from tbl1 where not(TAXON_ID_SHORT='all_taxa');" > temp.39.csv
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
joiner 'TAXON_ID_SHORT' temp.5.csv temp.6.csv > temp.55.csv
mv temp.5.csv temp.5-0.csv
rm -f temp.56.db
sqlite3 temp.56.db ".import $sIODir/temp.55.csv tbl1"
sqlite3 temp.56.db "select DATA_SET_ID, TAXON_ID_SHORT, (case when INFERENCE_CLUSTER='associated' and cast(OBSERVED as real)>0.01 then 'associated' else 'not_associated' end) as INFERENCE_CLUSTER, INFERENCE_TAXON from tbl1;" | sed "s|\r||g" > temp.5.csv

#filtering based on prevalence
joiner 'TAXON_ID_SHORT' temp.5.csv $sAbundancePrevalencePath > temp.31.csv
rm -f temp.32.db
sqlite3 temp.32.db ".import $sIODir/temp.31.csv tbl1"
sqlite3 temp.32.db "select TAXON_ID_SHORT, INFERENCE_CLUSTER, INFERENCE_TAXON, PREVALENCE from tbl1 where cast(PREVALENCE as real)>=$iPrevalenceThreshold and not(INFERENCE_CLUSTER='not_associated' and INFERENCE_TAXON='not_associated') order by INFERENCE_TAXON;" > temp.33.csv

#creating list of selected taxa
joiner 'TAXON_ID_SHORT' temp.33.csv $sTaxonAbbreviationsPath | sponge temp.33.csv
joiner 'TAXON_ID_SHORT' temp.33.csv temp.6.csv > temp.34.csv
rm -f temp.35.db
sqlite3 temp.35.db ".import $sIODir/temp.34.csv tbl1"
sqlite3 temp.35.db "select TAXON_ID_SHORT, TAXON_ID, INFERENCE_CLUSTER, INFERENCE_TAXON, PREVALENCE, OBSERVED, (case when not(cast(SES as real)=9999) then SES else 'na' end) as SES, (case when not(cast(PR_GTE as real)=9999) then PR_GTE else 'na' end) as PR_GTE from tbl1 where not(SES='9999') order by cast(SES as real) desc;" > selected-taxa.csv
sqlite3 temp.35.db "select TAXON_ID_SHORT, TAXON_ID, INFERENCE_CLUSTER, INFERENCE_TAXON, PREVALENCE, OBSERVED, (case when not(cast(SES as real)=9999) then SES else 'na' end) as SES, (case when not(cast(PR_GTE as real)=9999) then PR_GTE else 'na' end) as PR_GTE from tbl1 where SES='9999' order by TAXON_ID_SHORT;" | tail -n+2 >> selected-taxa.csv

#finding taxon pairs/clusters
cut -d\, -f1,2 selected-taxa.csv | sed "s|TAXON_ID_SHORT|TAXON_ID_SHORT_1|g" > temp.58.csv
joiner 'TAXON_ID_SHORT_1' $sCorrelatedTaxonPairsPath temp.58.csv > temp.60.csv
sed -i "1 s|TAXON_ID_SHORT_1|TAXON_ID_SHORT_2|g" temp.58.csv
joiner 'TAXON_ID_SHORT_2' temp.60.csv temp.58.csv | grep -v "\,NA" | cut -d\, -f1,2 > temp.61.csv

#updating names of clusters
sed -e "1 s|$|\,VALUE|g" -e "2,$ s|$|\,1|g" temp.61.csv > temp.3.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.SingleLinkageClustering.SingleLinkageClusteringLauncher \
	--sDataPath=$sIODir/temp.3.csv \
	--sObjectHeader1=TAXON_ID_SHORT_1 \
	--sObjectHeader2=TAXON_ID_SHORT_2 \
	--sValueHeader=VALUE \
	--dThreshold='0.5' \
	--sOutputPath=$sIODir/temp.4.csv
sed -i "1 s|OBJECT|TAXON_ID_SHORT|g" temp.4.csv
cut -d\, -f1 selected-taxa.csv > temp.5.csv
joiner 'TAXON_ID_SHORT' temp.5.csv temp.4.csv > temp.6.csv
grep -v '\,NA' temp.6.csv > temp.7.csv
echo 'TAXON_ID_SHORT' > temp.8.csv
grep '\,NA' temp.6.csv >> temp.8.csv
rownumbers temp.8.csv | sed "2,$ s|^|d|g" | sponge temp.8.csv
paste -d\, <(cut -d\, -f2 temp.8.csv | tail -n+2) <(cut -d\, -f1 temp.8.csv | tail -n+2) >> temp.7.csv

java -cp $sJavaDir/Utilities.jar edu.ucsf.FlatFileToLists.FlatFileToListsLauncher \
	--sDataPath=$sIODir/temp.7.csv \
	--sKeyField=CLUSTER \
	--sValueField=TAXON_ID_SHORT \
	--sOutputPath=$sIODir/temp.9.csv
sed -i "1 s|TAXON_ID_SHORT|CLUSTER_NEW|g" temp.9.csv
joiner 'CLUSTER' temp.7.csv temp.9.csv > temp.10.csv
cut -d\, -f1,3 temp.10.csv | sed "s|CLUSTER_NEW|CLUSTER|g" > selected-taxa-clusters.csv

rm temp.*.*
