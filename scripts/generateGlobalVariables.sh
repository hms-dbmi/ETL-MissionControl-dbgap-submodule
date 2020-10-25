#!/bin/bash

#####
#
# This script generates global variables.
# 
#####

#####
#
# This script presumes you have a good data set for each desired study that needs to have global variables generated.
#
#####

# Clean up dirs before running
find data/ -exec rm -rf {} \;

#### Jar files #####
cp ETL-MissionControl-dbgap-submodule/jars/* .


# Managed Inputs
aws s3 cp s3://avillach-73-bdcatalyst-etl/general/resources/Managed_Inputs.csv data/

IFS=$'\r\n' GLOBIGNORE='*' command eval  'studyids=($(cut -d , -f 1 data/Managed_Inputs.csv | uniq))'


#### get all subject multi files and patient mapping file from each study
for studyid in ${studyids[@]}; do
   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid,,}/rawData/data/ data/ --recursive --exclude "*" --include "*subject.multi*" --include "*Subject.Multi*" --include "*Subject.MULTI*"

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid,,}/data/${studyid^^}_PatientMapping.v2.csv data/
done

#### get Harmonized all concepts to harmonize
aws s3 cp s3://avillach-73-bdcatalyst-etl/hrmn/completed/HRMN_allConcepts.csv data/

java -jar ConsentGroupGenerator.jar 

java -jar PHSIdGenerator.jar 

