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

aws s3 cp s3://avillach-73-bdcatalyst-etl/hrmn/mappings/mapping.csv resources/

java -jar Partitioner.jar -propertiesfile resources/job.config --quiet

echo ""
echo "#### Building partitioned files ####"
echo ""
bash runpartition.sh -j $NPROC -m 3g -c 'config.part*.config' -r resources/

echo ""
echo "#### Merging partitioned files ####"
echo ""
java -jar MergePartitions.jar -propertiesfile resources/job.config

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

java -jar HarmonizedSyncPatients.jar -propertiesfile resources/job.config
