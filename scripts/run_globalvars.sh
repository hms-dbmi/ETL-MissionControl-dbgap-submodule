#!/bin/bash

#####
#
# This script generates global variables.
#
#####

#### Config files #####

IFS=$'\r\n' GLOBIGNORE='*' command eval  'studyids=($(cat ./studyids.txt))'


#### Global variables

echo "#### pull all the subject multi files for each study ####" 

find data/ -name "phs*" -exec rm -rf {} \;

find completed/ -type f -exec rm -rf {} \;

mkdir data
mkdir completed
mkdir hierarchies
mkdir processing

for studyid in ${studyids[@]}; do

   rm -rf resources/job.config

   find data/ -name "phs*" -exec rm -rf {} \;

   rm -rf data/${studyid^^}_PatientMapping.csv

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/rawData/data/ data/ --recursive --exclude "*" --include "*subject.multi*" --include "*Subject.Multi*" --include "*Subject.MULTI*"

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/resources/job.config resources/job.config

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/data/${studyid^^}_PatientMapping.csv data/

   java -jar ConsentGroupGenerator.jar -propertiesfile resources/job.config

   java -jar PHSIdGenerator.jar -propertiesfile resources/job.config

done

