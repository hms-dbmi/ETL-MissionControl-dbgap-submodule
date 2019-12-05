#!/bin/bash


## args
# 1 = root bucket for project

IFS=$'\r\n' GLOBIGNORE='*' command eval  'studyids=($(cat ../studyids.txt))'


#studyids=("fhs" "mesa" "mghaf" "partners" "safs" "sage" "sarcoidosis" "sas" "thrv" "vafar" "vuaf" "wghs" "whi" "hvh" "jhs" "mayovte" "aric" "bags" "ccaf" "cfs" "chs" "copdgene" "cra" "dhs" "eocopd" "galaii" "genestar" "genoa" "gensalt" "goldn" "hchs" "hrmn" "hvh" "hypergen" "jhs")
#studyids=("fhs" "mesa" "mghaf" "partners" "safs" "sage" "sarcoidosis" "sas" "thrv" "vafar" "vuaf" "wghs" "whi" "hvh" "jhs" "mayovte")
#studyids=("aric" "bags" "ccaf" "cfs" "chs" "copdgene" "cra" "dhs" "eocopd" "galaii" "genestar" "genoa" "gensalt" "goldn" "hchs" "hrmn" "hvh" "hypergen" "jhs"


pat_strt_seq=1
cncpt_strt_seq=1
for studyid in ${studyids[@]}; do
	echo ${map[${studyid}]}
	echo $studyid 'new concept seq:' $cncpt_strt_seq
	echo $studyid 'new patient seq:' $pat_strt_seq
	#pull runpartition.json and job.config
	#aws s3 cp s3://stage-$studyid-etl/runpartition.json .
	aws s3 cp s3://$1/$studyid/resources/job.config ../../resources/job.config

	# change job config starting sequences
	sed "s/conceptcdstartseq=.*/conceptcdstartseq=${cncpt_strt_seq}/" ../../resources/job.config > ../../temp.config
	sed "s/patientnumstartseq=.*/patientnumstartseq=${pat_strt_seq}/" ../../temp.config > ../../resources/job.config

	aws s3 cp ../../resources/job.config s3://$1/$studyid/resources/job.config

	aws s3 cp s3://$1/general/data_evaluations/${studyid}_dataevaluation.txt ../../resources/dataevaluation.txt

	cnext_increment=$(cat resources/dataevaluation.txt | grep 'Total expected concepts:' | sed 's/Total expected concepts: //')
	pnext_increment=$(cat resources/dataevaluation.txt | grep 'Total expected patients:' | sed 's/Total expected patients: //')

	cncpt_strt_seq=$(($cncpt_strt_seq + $cnext_increment + 10000))
	pat_strt_seq=$(($pat_strt_seq + $pnext_increment + 1000))

done
