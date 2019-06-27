#!/bin/bash

# VARIABLES

sProgramName=`basename $0 .shl`

# FUNCTION

report() {

echo executing ${sProgramName} for ${sSID}

export ORAENV_ASK=NO
export ORACLE_SID=${sSID}
export PATH=$PATH:/usr/local/bin
. oraenv
export ORAENV_ASK=YES

# BEGIN codeblock
# END   codeblock

}

# CONST

sSMON=ora_smon_

# SYNTAX

if [ -z $1 ]
then
	echo usage\: ${sProgramName}.shl \[ ORACLE_SID \| ALL \]
	exit -1
else
	vSID=$1
fi

# MAIN

if [ $vSID = "ALL" ]
then
	for sProcess in $( ps -ef | grep ${sSMON} | grep -v "grep ${sSMON}" )
	do
		if [ $(( $( echo ${sProcess} | grep ${sSMON} | wc -l ) )) -gt 0 ]
		then
			sSID=${sProcess#${sSMON}}
			report	
		fi
	done
else
	if [ $(( $( ps -ef | grep ${sSMON}${vSID} | grep -v "grep ${sSMON}${vSID}" | wc -l ) )) -gt 0 ]
	then
		sSID=${vSID}
		report
	else
		echo instance\:${vSID} not valid.
		exit -1
	fi	
fi
