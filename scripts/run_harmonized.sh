#!/bin/bash

#####
#
# This script generates global variables.
#
#####

#### Config files #####

IFS=$'\r\n' GLOBIGNORE='*' command eval  'studyids=($(cat ./studyids.txt))'


#### Global variables

find data/ -type f -exec rm -rf {} \;

find completed/ -type f -exec rm -rf {} \;

find processing/ -type f -exec rm -rf {} \;

find resources/ -type f -exec rm -rf {} \;

find mappings/ -type f -exec rm -rf {} \;

cp ETL-MissionControl-dbgap-submodule/jars/* .

mkdir data
mkdir completed
mkdir hierarchies
mkdir processing

echo '### Building DCC Harmonized data set'

aws s3 cp s3://avillach-73-bdcatalyst-etl/hrmn/data/ data/ --recursive

aws s3 cp s3://avillach-73-bdcatalyst-etl/hrmn/resources/job.config resources/

aws s3 cp s3://avillach-73-bdcatalyst-etl/hrmn/mappings/mapping.csv mappings/

java -jar Partitioner.jar -propertiesfile resources/job.config --quiet

echo ""
echo "#### Building Harmonized files ####"
echo ""

java -jar GenerateAllConcepts.jar -propertiesfile resources/job.config

aws s3 cp completed/ s3://avillach-73-bdcatalyst-etl/hrmn/completed/ --recursive --quiet

aws s3 cp completed/HRMN_PatientMapping.csv s3://avillach-73-bdcatalyst-etl/hrmn/data/

echo ""
echo "#### Finished Building hrmn allConcepts.csv ####"
echo ""
echo ""
echo ""

echo ""
echo "#### Sync Harmonized patient nums ####"
echo ""

find data/ -type f -exec rm -rf {} \;

find completed/ -type f -exec rm -rf {} \;

aws s3 cp s3://avillach-73-bdcatalyst-etl/hrmn/data/ data/ --recursive

aws s3 cp s3://avillach-73-bdcatalyst-etl/hrmn/completed/HRMN_allConcepts.csv data/

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/consents/HarmonizedPatientsWithConsentInfo.csv data/

for studyid in ${studyids[@]}; do
   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/data/${studyid^^}_PatientMapping.csv data/
done

aws s3 cp s3://avillach-73-bdcatalyst-etl/hrmn/data/HRMN_PatientMapping.csv data/

java -jar HarmonizedSyncPatients.jar -propertiesfile resources/job.config
