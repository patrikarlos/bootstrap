#!/bin/bash



tmpfile=$(mktemp)
tmpdir=$(mktemp -d )
openstack image list --long | grep -e 'bare' | awk -F "|" '{ if ( $6 > 0 ) {print $2," | ",$6," | ",$4,"|",$3,"|";} }' > $tmpfile

cat $tmpfile | while read LINE
do
#    echo "got $LINE"
    IFS="|" read UUID SIZE fstype1 Name <<<$(echo "$LINE")
    new1Name=$(echo $Name | tr -s ' ' | tr ' ' '_' | sed 'y/ÅÄÖåäö/AAOaao/' | tr '/' '-' )
    newName=$(echo $new1Name"."$fstype)
    fstype=$(echo "$fstype1" | tr -d " ")
    
#    echo "The UUID=$UUID, size = $SIZE and Name $Name . -> $newName "

    echo "Saving $Name to $tmpdir/$newName, its $SIZE bytes "
    openstack image save --file $tmpdir/$newName $UUID
    echo "Saved..." 
    
    
done


echo "Images stored to $tmpdir"

    


