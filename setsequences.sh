#!/bin/bash

#NPROC=$(nproc --all)
NPROC=$(sysctl -n hw.physicalcpu)

studyids=("fhs" "mesa" "mghaf" "partners" "safs" "sage" "sarcoidosis" "sas" "thrv" "vafar" "vuaf" "wghs" "whi" "hvh" "jhs" "mayovte" "aric" "bags" "ccaf" "cfs" "chs" "copdgene" "cra" "dhs" "eocopd" "galaii" "genestar" "genoa" "gensalt" "goldn" "hchs" "hrmn" "hvh" "hypergen" "jhs")
#studyids=("fhs" "mesa" "mghaf" "partners" "safs" "sage" "sarcoidosis" "sas" "thrv" "vafar" "vuaf" "wghs" "whi" "hvh" "jhs" "mayovte")
#studyids=("aric" "bags" "ccaf" "cfs" "chs" "copdgene" "cra" "dhs" "eocopd" "galaii" "genestar" "genoa" "gensalt" "goldn" "hchs" "hrmn" "hvh" "hypergen" "jhs"  
declare -A pmap
pmap[sarcoidosis]=1

declare -A cmap
cmap[sarcoidosis]=1

pat_strt_seq=1
cncpt_strt_seq=1
for studyid in ${studyids[@]}; do
	echo ${map[${studyid}]}
	echo $studyid 'new concept seq:' $cncpt_strt_seq
	echo $studyid 'new patient seq:' $pat_strt_seq
	#pull runpartition.json and job.config
	#aws s3 cp s3://stage-$studyid-etl/runpartition.json .
	aws s3 cp s3://stage-$studyid-etl/resources/job.config ./resources/job.config

	# change job config starting sequences
	sed "s/conceptcdstartseq=.*/conceptcdstartseq=${cncpt_strt_seq}/" resources/job.config > temp.config
	sed "s/patientnumstartseq=.*/patientnumstartseq=${pat_strt_seq}/" temp.config > resources/job.config
	
	aws s3 cp resources/job.config s3://stage-$studyid-etl/resources/job.config
	
	aws s3 cp s3://stage-general-etl/data_evaluations/${studyid}_dataevaluation.txt ./resources/dataevaluation.txt

	cnext_increment=$(cat resources/dataevaluation.txt | grep 'Total expected concepts:' | sed 's/Total expected concepts: //')
	pnext_increment=$(cat resources/dataevaluation.txt | grep 'Total expected patients:' | sed 's/Total expected patients: //')

	cncpt_strt_seq=$(($cncpt_strt_seq + $cnext_increment + 10000))
	pat_strt_seq=$(($pat_strt_seq + $pnext_increment + 1000))
	
done