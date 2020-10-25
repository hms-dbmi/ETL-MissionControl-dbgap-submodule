#!/bin/bash

##
# 1 = root bucket for project
#

IFS=$'\r\n' GLOBIGNORE='*' command eval  'studyids=($(cat ../studyids.txt))'

#studyids=("ccaf")

rm -rf ../../completed/ConsentGroupVariable.csv

cp ../jars/DbgapGlobalVarGenerator.jar ../../
cp ../jars/HarmonizedConsentsGenerator.jar ../../

for studyid in ${studyids[@]}; do
   find data/ -type f -exec rm -rf {} \;
   find data/ -type d -exec rm -rf {}/* \;

   #aws s3 cp s3://stage-${studyid}-etl/completed/PatientMapping.csv completed/PatientMapping.csv

   #aws s3 cp s3://stage-${studyid}-etl/resources/job.config resources/job.config

   aws s3 cp s3://$1/${studyid}/rawData/data/ data/ --recursive --exclude "*" --include "*multi*" --include "*Multi*" --include "*MULTI*"

   java -jar DbgapGlobalVarGenerator.jar -propertiesfile resources/${studyid,,}/job.config
   
done
   
java -jar ../../HarmonizedConsentsGenerator.jar -propertiesfile resources/${studyid,,}/job.config

aws s3 cp ../../completed/ConsentGroupVariable.csv s3://$1/data/ConsentGroupVariable.csv
aws s3 cp ../../mappings/consentmapping.csv s3://$1/mappings/consentmapping.csv