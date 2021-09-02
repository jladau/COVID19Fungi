#!/bin/bash
source $1

s0=`dirname $0`
sIODir=`dirname $s0`

iIteration=$2
	
cd $sIODir

#printing merged data
java -cp $sJavaDir/Autocorrelation.jar edu.ucsf.BetaDiversityAssociation.BetaDiversityAssociationLauncher \
	--sRegressionType=windowed_quantile \
	--bRemoveUnclassified=true \
	--sMode=print_data_merged \
	--sOutputPath=$sIODir/temp.2.csv \
	--iWindowSize=20 \
	--sMetric=bray_curtis \
	--sTaxonRank=$sTaxonRank \
	--iPartitioningOrders=25 \
	--iNullIterations=1000 \
	--sBIOMPath=$sBIOMPath \
	--sResponseDataPath=$sPairedDataPath \
	--sSample1Header=SAMPLE_INDOOR \
	--sSample2Header=SAMPLE_OUTDOOR \
	--sResponse=IFR_COUNTY \
	--sMergeHeader=COUNTY_FIPS \
	--sTaxonGroupsMapPath=$sIODir/correlated-taxa.csv \
	--rgdThresholds=75 \
	--dObservedValueThreshold='0.01'

#simulating correlated data
java -cp $sJavaDir/Covid.jar gov.lbnl.SimulateData.SimulateDataLauncher \
	--sDataPath=$sIODir/temp.2.csv \
	--sOutputPath=$sIODir/temp.3.csv \
	--sMode=unconditional \
	--dIntercept=0 \
	--dSlope='0.027'
rm -f temp.5.db
sqlite3 temp.5.db ".import $sIODir/temp.3.csv tbl1"
sqlite3 temp.5.db "select SAMPLE_ID as COUNTY_FIPS, RESPONSE_SIMULATED as IFR_COUNTY_SIMULATED from tbl1;" > temp.6.csv
joiner 'COUNTY_FIPS' $sPairedDataPath temp.6.csv | grep -v '\,NA' > temp.7.csv
rm -f temp.8.db
sqlite3 temp.8.db ".import $sIODir/temp.7.csv tbl1"
sqlite3 temp.8.db "select SAMPLE, SAMPLE_INDOOR, SAMPLE_OUTDOOR, STATE_FIPS, COUNTY_FIPS, IFR_COUNTY_SIMULATED as IFR_COUNTY, IFR_STATE, R0 from tbl1;" > simulated-correlated-response-data-$iIteration.csv

#simulating uncorrelated data
#java -cp $sJavaDir/Covid.jar gov.lbnl.SimulateData.SimulateDataLauncher \
#	--sDataPath=$sIODir/temp.2.csv \
#	--sOutputPath=$sIODir/temp.3.csv \
#	--sMode=conditional \
#	--dIntercept='0.027' \
#	--dSlope=0
#rm -f temp.5.db
#sqlite3 temp.5.db ".import $sIODir/temp.3.csv tbl1"
#sqlite3 temp.5.db "select SAMPLE_ID as COUNTY_FIPS, RESPONSE_SIMULATED as IFR_COUNTY_SIMULATED from tbl1;" > temp.6.csv
#joiner 'COUNTY_FIPS' $sPairedDataPath temp.6.csv | grep -v '\,NA' > temp.7.csv
#rm -f temp.8.db
#sqlite3 temp.8.db ".import $sIODir/temp.7.csv tbl1"
#sqlite3 temp.8.db "select SAMPLE, SAMPLE_INDOOR, SAMPLE_OUTDOOR, STATE_FIPS, COUNTY_FIPS, IFR_COUNTY_SIMULATED as IFR_COUNTY, IFR_STATE, R0 from tbl1;" > simulated-uncorrelated-response-#data-$iIteration.csv

rm -f temp.*.*
