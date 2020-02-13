#!/usr/bin/env bash
echo""
echo "############## Starting ##############"
echo ""

dir=$PWD

path=$1
krt_file=$2
key=$3

key_path=$path/$key
krt_path=$path/$krt_file
echo "Path is $path"
echo $key_path

vdb-config --import $key_path

working_dir=`ls -d /root/ncbi/*`

echo""
echo "############## End config ##############"
echo ""

echo "working directory is $working_dir"

echo "Downloading files from $krt_path"
echo ""
echo "############ Fetching data ################"
echo ""
sh -c "prefetch $krt_path"

echo ""
echo "############### decrytpging data ##############"
echo ""
cd $working_dir
vdb-decrypt .

echo "Done !!!"

mkdir $path/source_files
mv $working_dir/files/*.* $path/source_files/

mkdir $path/data
mkdir $path/dict

mv $path/source_files/*.xml $path/dict/
mv $path/source_files/*.gz $path/data/

cd $path/data
gunzip *.gz

rm $path/source_files -r
rm $working_dir -r
