#!/bin/bash
source $1

s0=`dirname $0`
sIODir=`dirname $s0`

cd $sIODir

#outputting data: merged, selected taxa, no tox1500
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_data_merged \
	--sOutputPath=$sIODir/beta-diversity-data-merged-selected-taxa-no-tox1500.csv \
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
	--sTaxonGroupsMapPath=$sTaxonGroupsSelectedTaxaPathNoTox1500 \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'
	
	
#outputting data: unmerged, selected taxa, no tox1500
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_data_unmerged \
	--sOutputPath=$sIODir/beta-diversity-data-unmerged-selected-taxa-no-tox1500.csv \
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
	--sTaxonGroupsMapPath=$sTaxonGroupsSelectedTaxaPathNoTox1500 \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'

#outputting data: merged, selected taxa
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_data_merged \
	--sOutputPath=$sIODir/beta-diversity-data-merged-selected-taxa.csv \
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
	--sTaxonGroupsMapPath=$sTaxonGroupsSelectedTaxaPath \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'
	
	
#outputting data: unmerged, selected taxa
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_data_unmerged \
	--sOutputPath=$sIODir/beta-diversity-data-unmerged-selected-taxa.csv \
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
	--sTaxonGroupsMapPath=$sTaxonGroupsSelectedTaxaPath \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'

#outputting data: merged, all taxa
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_data_merged \
	--sOutputPath=$sIODir/beta-diversity-data-merged-all-taxa.csv \
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
	
#outputting data: unmerged, all taxa
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_data_unmerged \
	--sOutputPath=$sIODir/beta-diversity-data-unmerged-all-taxa.csv \
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
