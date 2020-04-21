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

cp ETL-MissionControl-dbgap-submodule/jars/* .

mkdir data
mkdir completed
mkdir hierarchies
mkdir processing

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/data/ data/ --recursive

echo "#### Building Consent groups ####" 

for studyid in ${studyids[@]}; do

   rm -rf resources/job.config

   find data/ -name "phs*" -exec rm -rf {} \;

   rm -rf data/${studyid^^}_PatientMapping.csv

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/rawData/data/ data/ --recursive --exclude "*" --include "*subject.multi*" --include "*Subject.Multi*" --include "*Subject.MULTI*"

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/resources/job.config resources/job.config

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/data/${studyid^^}_PatientMapping.csv data/

   java -jar ConsentGroupGenerator.jar -propertiesfile resources/job.config

done

aws s3 cp completed/ConsentGroupVariable.csv s3://avillach-73-bdcatalyst-etl/general/data/

echo "#### Finished Building Consent global vars ####" 

echo "#### Building phs subject ids ####" 

for studyid in ${studyids[@]}; do

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/rawData/data/ data/ --recursive --exclude "*" --include "*subject.multi*" --include "*Subject.Multi*" --include "*Subject.MULTI*"

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/data/${studyid^^}_PatientMapping.csv data/

done

java -jar PHSIdGenerator.jar -propertiesfile resources/job.config

aws s3 cp completed/AccessionIds.csv s3://avillach-73-bdcatalyst-etl/general/data/

echo "#### Finished Building phs subject ids ####" 

echo "#### Building Global Allconcepts ####" 

find data/ -type f -exec rm -rf {} \;

find completed/ -type f -exec rm -rf {} \;

find resources/ -type f -exec rm -rf {} \;

find mappings/ -type f -exec rm -rf {} \;

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/data/ data/ --recursive

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/resources/job.config resources/

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/mappings/mapping.csv mappings/ 

java -jar GenerateAllConcepts.jar -propertiesfile resources/job.config

aws s3 cp completed/ s3://avillach-73-bdcatalyst-etl/general/completed/ --recursive


