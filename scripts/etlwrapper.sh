#!/bin/bash

#####
# 
# This script is inteneded to automate the
# phenotype data load for bdcatalyst project.
# 
#####

#### Config files #####
#
# studyids.txt - contains short study name for each project that 
#                needs to be processed. 
# 
# studyid_with_accessions.csv - file contains studys with there 
#                associated topmed and parent accession.  Studies 
#                may only have a topmed accession.
# 
# 
####

IFS=$'\r\n' GLOBIGNORE='*' command eval  'studyids=($(cat ./studyids.txt))'

## checkout repos



## make dir 
echo "#### Making directory structure ####"
mkdir data
mkdir completed
mkdir hierarchies
mkdir processing
echo "########"
## build or update mapping file

echo "#### Making mappings and update job config for current run ####"
aws s3 cp s3://avillach-73-bdcatalyst-etl/general/data/ data/ --recursive

for studyid in ${studyids[@]}; do

   find data/ -name "phs*" -exec rm -rf {} \;

   rm -rf data/*
   
   mkdir data

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/resources/ resources/ --recursive --include "mapping.csv" --include "job.config"

   sed -i "s/skipdataheader=Y/skipdataheader=N/g" resources/job.config

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/rawData/data/ data/ --recursive

   java -jar DbgapDecodeFiles.jar

   java -jar DbgapTreeBuilder2.jar -dataseperator '\t'
   
   aws s3 cp mappings/mapping.csv s3://avillach-73-bdcatalyst-etl/${studyid}/currentmapping.csv

   aws s3 cp resources/job.config s3://avillach-73-bdcatalyst-etl/${studyid}/current.config

done

echo "#### Finished building mappings and job.config for current run ####"



