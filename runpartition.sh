#!/bin/bash

while getopts m:j:c:r: option
do
case "${option}"
in
        m) memory=${OPTARG};;
        j) maxjobs=${OPTARG};;
        c) configfile=${OPTARG};;
        r) resdir=${OPTARG};;
esac
done

echo ${memory}
echo $maxjobs
echo $configfile
echo $resdir

rm -f -r etl_logs
mkdir etl_logs

for filename in ${resdir}${configfile}; do
    echo $filename started
    nohup java -jar jars/GenerateAllConcepts.jar -propertiesfile $filename -Xmx${memory} >> etl_logs/${configfile}.log &

    while [ $(ps aux | grep GenerateAllConcepts.jar | wc -l) -gt ${maxjobs} ]; do
        sleep .2
    done
done

while [ $(ps aux | grep GenerateAllConcepts.jar | wc -l) -gt 1 ]; do

   sleep .2

done
echo all GenerateAllConcepts threads completed