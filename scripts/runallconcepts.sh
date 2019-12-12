#!/bin/bash

# 1 = root bucket for project

IFS=$'\r\n' GLOBIGNORE='*' command eval  'studyids=($(cat ../studyids.txt))'

cp ../jars/GenerateAllConcepts.jar ../../

aws s3 cp s3://$1/general/studyids.txt.csv ./ --quiet

for studyid in ${studyids[@]}; do

   echo "running ${studyid}"
   
   if [ -d "../../data/${studyid}/" ]; then

     find ../../data/${studyid}/ -type f -exec rm -rf {} \;

   fi
   
   aws s3 cp s3://$1/$studyid/mappings/mapping.csv ../../mappings/${studyid}/mapping.csv --quiet
   aws s3 cp s3://$1/$studyid/data/ ../../data/${studyid}/ --recursive --quiet
   aws s3 cp s3://$1/$studyid/resources/job.config ../../resources/${studyid}/job.config --quiet

   sed "s/pathseparator.*//g" ../../resources/${studyid}/job.config > ../../resources/${studyid}/job2.config
   mv ../../resources/${studyid}/job2.config ../../resources/${studyid}/job.config

   sed "s/datadir.*//g" ../../resources/${studyid}/job.config > ../../resources/${studyid}/job2.config
   mv ../../resources/${studyid}/job2.config ../../resources/${studyid}/job.config

   if grep -q pathseparator "../../resources/${studyid}/job.config"; then
      sed "s/pathseparator.*/pathseparator=\\\\\\\\/g" ../../resources/${studyid}/job.config > ../../resources/${studyid}/job2.config
      mv ../../resources/${studyid}/job2.config ../../resources/${studyid}/job.config

      sed "s/filename.*/filename=data\/${studyid}\//g" ../../resources/${studyid}/job.config > ../../resources/${studyid}/job2.config
      mv ../../resources/${studyid}/job2.config ../../resources/${studyid}/job.config

      sed "s/mappingfile.*/mappingfile=mappings\/${studyid}\/mapping.csv\//g" ../../resources/${studyid}/job.config > ../../resources/${studyid}/job2.config
      mv ../../resources/${studyid}/job2.config ../../resources/${studyid}/job.config

      sed "s/patientmappingfile.*/patientmappingfile=mappings\/${studyid}\/mapping.csv.patient\//g" ../../resources/${studyid}/job.config > ../../resources/${studyid}/job2.config
      mv ../../resources/${studyid}/job2.config ../../resources/${studyid}/job.config

   else
      echo "pathseparator=\\\\" >> ../../resources/${studyid}/job.config
      echo "datadir=data/${studyid}/" >> ../../resources/${studyid}/job.config
      sed "s/filename.*/filename=data\/${studyid}\//g" ../../resources/${studyid}/job.config > ../../resources/${studyid}/job2.config
      mv ../../resources/${studyid}/job2.config ../../resources/${studyid}/job.config

      sed "s/mappingfile.*/mappingfile=mappings\/${studyid}\/mapping.csv\//g" ../../resources/${studyid}/job.config > ../../resources/${studyid}/job2.config
      mv ../../resources/${studyid}/job2.config ../../resources/${studyid}/job.config

      sed "s/patientmappingfile.*/patientmappingfile=mappings\/${studyid}\/mapping.csv.patient\//g" ../../resources/${studyid}/job.config > ../../resources/${studyid}/job2.config
      mv ../../resources/${studyid}/job2.config ../../resources/${studyid}/job.config
   fi

   nohup java -jar ../../GenerateAllConcepts.jar -propertiesfile ../../resources/${studyid}/job.config -Xmx5g > ../../resources/${studyid}/etl.log 2>&1 &

   #aws s3 cp completed/${studyid}_allConcepts.csv s3://stage-$studyid-etl/completed/${studyid}_allConcepts.csv

   while [ $(ps aux | grep GenerateAllConcepts.jar | wc -l) -gt 16 ]; do

      sleep 1
   done
   echo "finished ${studyid}"
done

rm -rf ../../completed/ConsentGroupVariable.csv

cp ../jars/DbgapGlobalVarGenerator.jar ../../
cp ../jars/HarmonizedConsentsGenerator.jar ../../
cp ../jars/DbGapDataMerge.jar ../../

for studyid in ${studyids[@]}; do
   find data/ -type f -exec rm -rf {} \;
   find data/ -type d -exec rm -rf {}/* \;

   #aws s3 cp s3://stage-${studyid}-etl/completed/PatientMapping.csv completed/PatientMapping.csv

   #aws s3 cp s3://stage-${studyid}-etl/resources/job.config resources/job.config

   aws s3 cp s3://$1/${studyid}/rawData/data/ data/${studyid,,}/ --recursive --exclude "*" --include "*multi*" --include "*Multi*" --include "*MULTI*"

   java -jar ../../DbgapGlobalVarGenerator.jar -propertiesfile resources/${studyid,,}/job.config
   
done
   
java -jar ../../HarmonizedConsentsGenerator.jar -propertiesfile resources/${studyid,,}/job.config

aws s3 cp ../../completed/ConsentGroupVariable.csv s3://$1/consents/data/ConsentGroupVariable.csv

aws s3 cp ../../mappings/consentmapping.csv s3://$1/consents/mappings/consentmapping.csv

nohup java -jar ../../DbGapDataMerge.jar -propertiesfile resources/job.config -Xmx50g &



