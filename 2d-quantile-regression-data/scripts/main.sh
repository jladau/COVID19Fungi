#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

cd $sIODir

#loading list of taxa to include
rm -f temp.2.db
sqlite3 temp.2.db ".import $sSelectedTaxaPath tbl1"
sqlite3 temp.2.db "select TAXON_ID from tbl1;" > temp.3.csv
echo 'k__Fungi;p__Ascomycota;c__Dothideomycetes;o__Capnodiales;f__Incertae sedis;g__Toxicocladosporium' >> temp.3.csv

#loading flat file of relative abundances
java -cp $sJavaDir/Utilities.jar edu.ucsf.BIOM.ToFlatFile.ToFlatFileLauncher \
	--sBIOMPath=$sBIOMPath \
	--sSamplesToKeepPath=$sSamplesWithCompleteDataPath \
	--sTaxonRank=$sTaxonRank \
	--sOutputPath=$sIODir/temp.1.csv \
	--bOutputZeros=true \
	--sObservationsToKeepPath=$sIODir/temp.3.csv

#joining short names
sed -i -e "1 s|OBSERVATION|TAXON_ID|g" -e "1 s|VALUE|READ_COUNT|g" -e "1 s|SAMPLE|SAMPLE_ID|g" temp.1.csv
joiner 'TAXON_ID' temp.1.csv $sTaxonAbbreviationsPath > temp.4.csv

#finding diversity measures and summed relative abundances
rm -f temp.5.db
sqlite3 temp.5.db ".import $sIODir/temp.4.csv tbl1"
sqlite3 temp.5.db "select SAMPLE_ID, sum(cast(READ_COUNT as real)) as READS_TOTAL_7 from tbl1 group by SAMPLE_ID;" > temp.6.csv
sqlite3 temp.5.db "select SAMPLE_ID, sum(cast(READ_COUNT as real)) as READS_TOTAL_6 from tbl1 where not(TAXON_ID_SHORT='Tox1500') group by SAMPLE_ID;" > temp.7.csv
joiner 'SAMPLE_ID' temp.4.csv temp.6.csv > temp.8.csv
joiner 'SAMPLE_ID' temp.8.csv temp.7.csv | sponge temp.8.csv
rm -f temp.9.db
sqlite3 temp.9.db ".import $sIODir/temp.8.csv tbl1"
sqlite3 temp.9.db "select SAMPLE_ID, 'shannon_diversity_7' as TAXON_ID_SHORT, -sum(P_I*log(P_I)) as VALUE from (select SAMPLE_ID, TAXON_ID_SHORT, cast(READ_COUNT as real)/cast(READS_TOTAL_7 as real) as P_I from tbl1) where P_I>0 group by SAMPLE_ID;" > temp.10.csv
sqlite3 temp.9.db "select SAMPLE_ID, 'shannon_diversity_6' as TAXON_ID_SHORT, -sum(P_I*log(P_I)) as VALUE from (select SAMPLE_ID, TAXON_ID_SHORT, cast(READ_COUNT as real)/cast(READS_TOTAL_6 as real) as P_I from tbl1 where not(TAXON_ID_SHORT='Tox1500') and P_I>0) group by SAMPLE_ID;" | tail -n+2 >> temp.10.csv
sqlite3 temp.9.db "select SAMPLE_ID, 'richness_7' as TAXON_ID_SHORT, count(TAXON_ID_SHORT) as VALUE from tbl1 where not(cast(READ_COUNT as real)=0) group by SAMPLE_ID;" | tail -n+2 >> temp.10.csv
sqlite3 temp.9.db "select SAMPLE_ID, 'richness_6' as TAXON_ID_SHORT, count(TAXON_ID_SHORT) as VALUE from tbl1 where not(cast(READ_COUNT as real)=0) and not(TAXON_ID_SHORT='Tox1500') group by SAMPLE_ID;" | tail -n+2 >> temp.10.csv
sqlite3 temp.9.db "select distinct SAMPLE_ID, 'reads_total_7' as TAXON_ID_SHORT, log10((cast(READS_TOTAL_7 as real)+1)/10001) as VALUE from tbl1;" | tail -n+2 >> temp.10.csv
sqlite3 temp.9.db "select distinct SAMPLE_ID, 'reads_total_6' as TAXON_ID_SHORT, log10((cast(READS_TOTAL_6 as real)+1)/10001) as VALUE from tbl1;" | tail -n+2 >> temp.10.csv
sqlite3 temp.9.db "select distinct SAMPLE_ID, TAXON_ID_SHORT, log10((cast(READ_COUNT as real)+1)/10001) as VALUE from tbl1;" | tail -n+2 >> temp.10.csv

#finding indoor and outdoor values
rm -f temp.11.db
sqlite3 temp.11.db ".import $sPairedDataPath tbl1"
sqlite3 temp.11.db "select SAMPLE_INDOOR as SAMPLE_ID, 'indoor' as LOCATION, COUNTY_FIPS from tbl1;" > temp.12.csv
sqlite3 temp.11.db "select SAMPLE_OUTDOOR as SAMPLE_ID, 'outdoor' as LOCATION, COUNTY_FIPS from tbl1;" | tail -n+2 >> temp.12.csv
joiner 'SAMPLE_ID' temp.10.csv temp.12.csv | grep -v '\,NA' > temp.13.csv

#finding county averages
rm -f temp.14.db
sqlite3 temp.14.db ".import $sIODir/temp.13.csv tbl1"
sqlite3 temp.14.db "select COUNTY_FIPS, LOCATION, TAXON_ID_SHORT, avg(cast(VALUE as real)) as VALUE from tbl1 group by COUNTY_FIPS, LOCATION, TAXON_ID_SHORT;" > temp.15.csv
java -cp $sJavaDir/Utilities.jar edu.ucsf.FlatFileToPivotTable.FlatFileToPivotTableLauncher \
	--sDataPath=$sIODir/temp.15.csv \
	--sValueHeader=VALUE \
	--rgsExpandHeaders='TAXON_ID_SHORT,LOCATION' \
	--sOutputPath=$sIODir/temp.16.csv
sed -e "1 s|TAXON_ID_SHORT\=||g" -e "1 s|\;LOCATION\=|_|g" temp.16.csv | grep -v '\,null' > temp.17.csv

#joining ifr data
sqlite3 temp.11.db "select COUNTY_FIPS, IFR_COUNTY from tbl1;" > temp.18.csv
joiner 'COUNTY_FIPS' temp.17.csv temp.18.csv > 2d-quantile-regression-data.csv

#cleaning up
rm temp.*.*

