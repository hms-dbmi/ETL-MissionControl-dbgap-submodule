#!/bin/bash

#####
#
# This script generates global variables.
#
#####

#### Config files #####

IFS=$'\r\n' GLOBIGNORE='*' command eval  'studyids=($(cat ./studyids.txt))'


#### Global variables

cp ETL-MissionControl-dbgap-submodule/jars/* .

mkdir data
mkdir completed
mkdir hierarchies
mkdir processing

mv batch1/*allConcepts.csv data/
mv batch2/*allConcepts.csv data/
mv batch3/*allConcepts.csv data/
mv batch4/*allConcepts.csv data/

aws s3 cp s3://avillach-73-bdcatalyst-etl/hrmn/completed/HRMN_allConcepts.csv data/

aws s3 cp s3://avillach-73-bdcatalyst-etl/general/completed/GLOBAL_allConcepts.csv data/

java -jar DbGapDataMerge.jar

aws s3 cp completed/allConcepts.csv s3://avillach-73-bdcatalyst-etl/general/completed/

mv completed/allConcepts.csv pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/

sed -i 's/µ/\\/g' pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/allConcepts.csv

docker-compose -f pic-sure-hpds/docker/pic-sure-hpds-etl/docker-compose-csv-loader.yml up -d

d=$(date +"%m-%d-%y") 

tar zcf biodatacatalyst_javabins_${d}.tar.gz pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/allObservationsStore.javabin pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/columnMeta.javabin pic-sure-hpds/docker/pic-sure-hpds-etl/hpds/encryption_key

aws s3 cp biodatacatalyst_javabins_${d}.tar.gz s3://avillach-73-bdcatalyst-etl/general/hpds/javabin/
