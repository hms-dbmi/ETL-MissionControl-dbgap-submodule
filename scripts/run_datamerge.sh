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

for studyid in ${studyids[@]}; do
   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/completed/${studyid^^}_allConcepts.csv data/
done

aws s3 cp s3://avillach-73-bdcatalyst-etl/hrmn/completed/HRMN_allConcepts.csv data/

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/completed/GLOBAL_allConcepts.csv data/

java -jar DbGapDataMerge.jar


