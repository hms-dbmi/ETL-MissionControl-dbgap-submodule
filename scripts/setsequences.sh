#!/bin/bash

# Managed Inputs
aws s3 cp s3://avillach-73-bdcatalyst-etl/general/resources/Managed_Inputs.csv data/

IFS=$'\r\n' GLOBIGNORE='*' command eval  'studyids=($(cut -d , -f 1 data/Managed_Inputs.csv | grep -v Study\ Abbr | uniq))'


#### get all subject multi files, job.config and patient mapping file from each study 
for studyid in ${studyids[@]}; do

	aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid,,}/data/${studyid^^}_PatientMapping.v2.csv data/

	aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid,,}/resources/job.config resources/${studyid^^}_job.config

	aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid,,}/rawData/ data/ --recursive --exclude "*" --include "*subject.multi*" --include "*Subject.Multi*" --include "*Subject.MULTI*"

done