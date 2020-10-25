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
   aws s3 cp s3://avillach-73-bdcatalyst-etl/${studyid,,}/completed/${studyid^^}_allConcepts.csv data/
done

aws s3 cp s3://avillach-73-bdcatalyst-etl/hrmn/completed/HRMN_allConcepts.csv data/

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/completed/GLOBAL_allConcepts.csv data/

java -jar DbGapDataMerge.jar

aws s3 cp completed/allConcepts.csv s3://avillach-73-bdcatalyst-etl/general/completed/

mv completed/allConcepts.csv pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/

sed -i 's/µ/\\/g' pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/allConcepts.csv

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/resources/docker-compose-csv-loader.yml pic-sure-hpds/docker/pic-sure-hpds-etl/

cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 > pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/encryption_key

docker-compose -f pic-sure-hpds/docker/pic-sure-hpds-etl/docker-compose-csv-loader.yml up -d

d=$(date +"%m-%d-%y") 

tar zcf biodatacatalyst_javabins_${d}.tar.gz pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/allObservationsStore.javabin pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/columnMeta.javabin pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/encryption_key

aws s3 cp biodatacatalyst_javabins_${d}.tar.gz s3://avillach-73-bdcatalyst-etl/general/hpds/javabin/
