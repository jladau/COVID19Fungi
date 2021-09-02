#!/bin/bash

s0=`dirname $0`
sIODir=`dirname $s0`

source $1

for i in {0..15}
do
	sStartDate=${rgsStartDates[i]}
	sEndDate=${rgsEndDates[i]}
	sDates=$sStartDate'_'$sEndDate
	
	echo $sDates
	
	bash $sIODir/scripts/iterator.sh $1 $sDates
done
