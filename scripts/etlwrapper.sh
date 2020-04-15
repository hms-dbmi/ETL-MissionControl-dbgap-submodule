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


aws s3 cp s3://avillach-73-bdcatalyst-etl/general/data/ data/ --recursive

cp ETL-MissionControl-dbgap-submodule/jars/* .

if [ $1 = "true"]; then
   echo ""
   echo "#### Making mappings and update job config for current run ####"
   echo ""
   for studyid in ${studyids[@]}; do

      find data/ -name "phs*" -exec rm -rf {} \;

      rm -rf completed/*
      mkdir data

      aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/mappings/ mappings/ --recursive --include "mapping.csv" --quiet

      aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/resources/ resources/ --recursive --include "job.config" --quiet

      sed -i "s/skipdataheader=Y/skipdataheader=N/g" resources/job.config

      sed -i "s/patientmappingfile=.*/patientmappingfile=data\/${studyid^^}\_PatientMapping.csv/g" resources/job.config

      echo 'usepatientmapping=Y' >> resources/job.config

      aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/rawData/data/ data/ --recursive --quiet

      java -jar DbgapDecodeFiles.jar

      aws s3 cp completed/ s3://avillach-73-bdcatalyst-etl/${studyid}/data/ --recursive --quiet

      java -jar DbgapTreeBuilder2.jar -dataseperator '\t'

      find data/ -name "phs*" -exec rm -rf {} \;

      mv completed/* data/

      java -jar DbGapPMGenerator.jar -propertiesfile resources/job.config

      aws s3 cp data/${studyid^^}_PatientMapping.csv s3://avillach-73-bdcatalyst-etl/${studyid}/data/

      aws s3 cp mappings/mapping.csv s3://avillach-73-bdcatalyst-etl/${studyid}/currentmapping.csv --quiet

      aws s3 cp resources/job.config s3://avillach-73-bdcatalyst-etl/${studyid}/current.config --quiet
      
   done

   echo ""
   echo "#### Finished building mappings and job.config for current run ####"
   echo ""
fi

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

   rm -rf mappings/mapping.part*

   rm -rf resources/config.part*

   mkdir data
   mkdir completed
   mkdir processing

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/currentmapping.csv mappings/mapping.csv --quiet

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/current.config resources/job.config --quiet

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/data/ data/ --recursive --quiet
   
   java -jar Partitioner.jar -propertiesfile resources/job.config --quiet
   
   echo ""
   echo "#### Building partitioned files ####"
   echo ""
   bash runpartition.sh -j 4 -m 3g -c 'config.part*.config' -r resources/

   echo ""
   echo "#### Merging partitioned files ####"
   echo ""
   java -jar MergePartitions.jar -propertiesfile resources/job.config

   aws s3 cp completed/ s3://avillach-73-bdcatalyst-etl/${studyid}/completed/ --recursive --quiet
   #aws s3 cp completed/ s3://avillach-73-bdcatalyst-etl/${studyid}/completed/ --recursive

   echo ""
   echo "#### Finished Building " ${studyid} " allConcepts.csv ####"
   echo ""
   echo ""
   echo ""
done

echo ""
echo "#### Finished Building allConcepts.csv for each study ####"
echo ""
