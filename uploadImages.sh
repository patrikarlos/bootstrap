#!/bin/bash

sourcedir=$1


for file in $sourcedir/*
do
    echo "Will work on $file"
    filename=$(basename "$file")
    fname="${filename%.*}"
    ext="${filename##*.}"
    
    
    echo -e "\t Uploading: openstack image create --public --container-format=bare --file=$file --disk-format=$ext $fname"
    openstack image create --public --container-format=bare --file=$file --disk-format=$ext $fname 
    
  
    
done
