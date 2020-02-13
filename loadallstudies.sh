#!/bin/bash

studyids=("ccaf")

for studyid in ${studyids[@]}; do

	rm -rf completed/*

	aws s3 cp s3://stage-$studyid-etl/completed/ completed/ --recursive

	bash LoadTables.sh -u stage-dev-db.c275fkjalvvb.us-east-1.rds.amazonaws.com:1521/orcl -o root -p $1 -s oracle/ctl/TRUNCATE/ -c completed/

	aws s3 cp . s3://stage-general-etl/logs/loading/$studyid/ --recursive --exclude "*" --include "*.bad"

	aws s3 cp . s3://stage-general-etl/logs/loading/$studyid/ --recursive --exclude "*" --include "*.log" 

	rm -rf *.bad

	rm -rf *.log

done
