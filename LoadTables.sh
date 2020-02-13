#!/bin/bash

while getopts u:s:o:p:c: option
do
case "${option}"
in
        u) url=${OPTARG};;
        s) scripts=${OPTARG};;
        o) user=${OPTARG};;
        p) password=${OPTARG};;
        c) completedir=${OPTARG};;
esac
done

for filename in ${scripts}*.ctl; do
	datafile=${completedir}/$(basename "${filename}" .ctl).csv
	sqlldr ${user}/${password}@${url} control=$filename data=${datafile} ROWS=1000 BINDSIZE=999999999 ERRORS=99999 &
	if [ $(ps aux | grep sqlldr | wc -l) -gt 0 ]
           then
                sleep 5
        fi
done

