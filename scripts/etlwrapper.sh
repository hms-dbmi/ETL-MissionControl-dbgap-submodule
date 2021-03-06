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

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/ studyids.txt

IFS=$'\r\n' GLOBIGNORE='*' command eval  'studyids=($(cat ./studyids.txt))'

## checkout repos

NPROC=$(nproc)

## make dir
echo "#### Making directory structure ####"

find data/  -exec rm -rf {} \;

mkdir data
mkdir completed
mkdir hierarchies
mkdir processing
echo "########"
## build or update mapping file

echo ""
echo "#### General Setup ####"
echo ""

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/data/ data/ --recursive

cp ETL-MissionControl-dbgap-submodule/jars/* .


echo ""
echo "#### Build initial mappings and update job config for current etl run ####"
echo ""

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/data/ data/ --recursive

cp ETL-MissionControl-dbgap-submodule/jars/* .


for studyid in ${studyids[@]}; do

   find data/ -name "phs*" -exec rm -rf {} \;

   rm -rf completed/*
   mkdir data

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/mappings/ mappings/ --recursive --include "mapping.csv"

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/resources/ resources/ --recursive --include "job.config"

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/rawData/dict/ s3://avillach-73-bdcatalyst-etl/${studyid}/rawData/data/ --recursive

   sed -i "s/skipdataheader=Y/skipdataheader=N/g" resources/job.config

   sed -i "s/patientmappingfile=.*/patientmappingfile=data\/${studyid^^}\_PatientMapping.csv/g" resources/job.config

   echo 'usepatientmapping=Y' >> resources/job.config

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/rawData/data/ data/ --recursive

   java -jar DbgapDecodeFiles.jar

   java -jar DbgapTreeBuilder2.jar -dataseperator '\t'

   find data/ -name "phs*" -exec rm -rf {} \;

   mv completed/* data/

   java -jar DbGapPMGenerator.jar -propertiesfile resources/job.config

   mv completed/* data/

   aws s3 cp data/ s3://avillach-73-bdcatalyst-etl/${studyid}/data/ --exclude "*" --include "phs*" --include "*PatientMapping.csv" --recursive

   aws s3 cp mappings/mapping.csv s3://avillach-73-bdcatalyst-etl/${studyid}/currentmapping.csv

   aws s3 cp resources/job.config s3://avillach-73-bdcatalyst-etl/${studyid}/current.config
   
done

echo ""
echo "#### Finished building mappings and job.config for current run ####"
echo ""


echo ""
echo "#### Building allConcepts.csv for each study ####"
echo "" 

for studyid in ${studyids[@]}; do

   echo ""
   echo "#### Building " ${studyid} " allConcepts.csv ####"
   echo ""

   find data/ -name "phs*" -exec rm -rf {} \;
   
   find processing/ -type f -exec rm -rf {} \;

   rm -rf completed/*

   find mappings/ -name "mapping.part*" -exec rm -rf {} \;

   find resources/ -name "config.part*" -exec rm -rf {} \;

   mkdir data
   mkdir completed
   mkdir processing

   aws s3 cp s3://avillach-73-bdcatalyst-etl/copdgene/currentmapping.csv mappings/mapping.csv

   aws s3 cp s3://avillach-73-bdcatalyst-etl/copdgene/current.config resources/job.config

   aws s3 cp s3://avillach-73-bdcatalyst-etl/copdgene/data/ data/ --recursive --exclude "*" --include "phs*" --include "*PatientMapping.csv"
   
   java -jar Partitioner.jar -propertiesfile resources/job.config 

   echo ""
   echo "#### Building partitioned files ####"
   echo ""
   bash runpartition.sh -j $NPROC -m 3g -c 'config.part*.config' -r resources/

   echo ""
   echo "#### Merging partitioned files ####"
   echo ""
   java -jar MergePartitions.jar -propertiesfile resources/job.config

   aws s3 cp completed/ s3://avillach-73-bdcatalyst-etl/copdgene/completed/ --recursive --quiet

   echo ""
   echo "#### Finished Building " ${studyid} " allConcepts.csv ####"
   echo ""
   echo ""
   echo ""
done

echo ""
echo "#### Finished Building allConcepts.csv for each study ####"
echo ""
