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


aws s3 cp s3://avillach-73-bdcatalyst-etl/general/data/ data/ --recursive

cp ETL-MissionControl-dbgap-submodule/jars/* .

echo ""
echo "#### Fix Patient Mappings for each study ####"
echo ""

for studyid in ${studyids[@]}; do

   find data/ -name "phs*" -exec rm -rf {} \;

   find completed/ -type f -exec rm -rf {} \;

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/current.config resources/job.config --quiet

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/data/ data/ --recursive --exclude "*" --include "phs*" --include "*PatientMapping.csv" --quiet

   java -jar AppendSampleID.jar -propertiesfile resources/job.config

   aws s3 cp completed/ s3://avillach-73-bdcatalyst-etl/${studyid}/data/ --recursive

done

find data/ -type f -exec rm -rf {} \;

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/data/ data/ --recursive

echo ""
echo "#### Building allConcepts.csv for each study ####"
echo ""

for studyid in ${studyids[@]}; do

   echo ""
   echo "#### Building " ${studyid} " allConcepts.csv ####"
   echo ""

   find data/ -name "phs*" -exec rm -rf {} \;

   find processing/ -type f -exec rm -rf {} \;

   find completed/ -type f -exec rm -rf {} \;

   find mappings/ -name "mapping.part*" -exec rm -rf {} \;

   find resources/ -name "config.part*" -exec rm -rf {} \;

   mkdir data
   mkdir completed
   mkdir processing

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/currentmapping.csv mappings/mapping.csv --quiet

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/current.config resources/job.config --quiet

   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid}/data/ data/ --recursive --exclude "*" --include "phs*" --include "*PatientMapping.v2.csv" --quiet

   sed -i "s/patientmappingfile=.*/patientmappingfile=data\/${studyid^^}\_PatientMapping.v2.csv/g" resources/job.config

   java -jar Partitioner.jar -propertiesfile resources/job.config --quiet

   echo ""
   echo "#### Building partitioned files ####"
   echo ""
   bash runpartition.sh -j $NPROC -m 3g -c 'config.part*.config' -r resources/

   echo ""
   echo "#### Merging partitioned files ####"
   echo ""
   java -jar MergePartitions.jar -propertiesfile resources/job.config

   aws s3 cp completed/ s3://avillach-73-bdcatalyst-etl/${studyid}/completed/ --recursive --quiet

   echo ""
   echo "#### Finished Building " ${studyid} " allConcepts.csv ####"
   echo ""
   echo ""
   echo ""
done

echo ""
echo "#### Finished Building allConcepts.csv for each study ####"
echo ""