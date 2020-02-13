#!/usr/local/bin

# Clean up project before processing
rm -rf mappings/mapping.csv
rm -rf mappings/mapping.csv.patient
rm -rf completed/*
rm -rf data/*
rm -rf dict/*
rm -rf processing/*

NPROC=$(nproc --all)

echo 'Running cleanse for ' $1

echo 'Total Num of processors: ' $NPROC
echo ''
echo '------------------------'
echo 'Building config files.'
cp template/job.config resources/job.config
# update job config trial id
sed "s/trialid.*/trialid=${1^^}/" resources/job.config > processing/new.config
sed "s/rootnode=.*/rootnode=/" processing/new.config > processing/new2.config
sed "s/dataquotedstring=.*/dataquotedstring=ç/" processing/new2.config > processing/new3.config

cp processing/new3.config resources/job.config

# update json config
cp template/runpartition.json runpartition.json
sed "s/s3:\/\/<bucket_name>/s3:\/\/stage-$1-etl/" runpartition.json > processing/new.json
sed "s/\"maxjobs\": 3/\"maxjobs\": $NPROC/" processing/new.json > processing/new2.json
cp processing/new2.json runpartition.json

echo ''
echo '------------------------'
echo 'Pulling data for ' $1
# Pull data and dictionaries
aws s3 cp s3://stage-$1-etl/rawData/data/ data/ --recursive
aws s3 cp s3://stage-$1-etl/rawData/dict/ dict/ --recursive

echo ''
echo '------------------------'
echo "Building Hierarchy"
# Build Hierarchies
if [ "${2^^}" != "Y" ];
   then
      java -jar DbgapTreeBuilder.jar -propertiesfile resources/job.config
   else
      java -jar DbgapTreeBuilder.jar -propertiesfile resources/job.config -encodedlabel $2
fi

sed "s/dataquotedstring=.*/dataquotedstring=\"/" resources/job.config > resources/job2.config
sed "s/datadelimiter=.*/datadelimiter=,/" resources/job2.config > resources/job3.config

mv resources/job3.config resources/job.config
rm resources/job2.config

echo ''
echo '------------------------'
echo 'Syncing data back to cloud'
# sync built structure ready for data load
rm -rf data/*

mv completed/* data/

aws s3 cp data/ s3://stage-$1-etl/data/ --recursive
aws s3 cp resources/job.config s3://stage-$1-etl/resources/job.config

echo ''
echo '------------------------'
echo 'Running data analyzer'
java -jar DataAnalyzer.jar -propertiesfile resources/job.config -Xmx20g

echo ''
echo '------------------------'
echo 'Syncing new mapping and config files back to the cloud'
aws s3 cp mappings/mapping.csv s3://stage-$1-etl/mappings/mapping.csv
aws s3 cp mappings/bad_mappings.csv s3://stage-$1-etl/mappings/bad_mappings.csv
aws s3 cp mappings/mapping.csv.patient s3://stage-$1-etl/mappings/mapping.csv.patient

# Sync config files
aws s3 cp resources/job.config s3://stage-$1-etl/resources/job.config
aws s3 cp runpartition.json s3://stage-$1-etl/runpartition.json

echo ''
echo '------------------------'
echo 'Running data evaluation'
# Run Data Evaluation

java -jar DataEvaluation.jar -propertiesfile resources/job.config -Xmx20g

echo ''
echo '------------------------'
echo 'Syncing data evaluation to stage-general-etl'
aws s3 cp resources/dataevaluation.txt s3://stage-general-etl/data_evaluations/$1_dataevaluation.txt

echo ''
echo '------------------------'
echo 'Job Finished'
echo '------------------------'
echo ''
# Clean up dirs
#rm -rf mappings/mapping.csv
#rm -rf mappings/mapping.csv.patient
#rm -rf completed/*
#rm -rf data/*
#rm -rf dict/*
#rm -rf processing/*