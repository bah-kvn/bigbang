#! /bin/bash -e

#can uncomment the below for local testing
#TOKEN=""
#OWNER="Solutions-Center"
#REPO=""

json=$(curl -H "Accept: application/vnd.github+json" -H "Authorization: token $TOKEN" https://github.boozallencsn.com/api/v3/repos/$OWNER/$REPO/labels)

while read -r i ; do
    name=$(echo $i | sed 's/ /%20/g')
    #echo "deleting label $name"
    curl -X DELETE  -H "Accept: application/vnd.github+json"  -H "Authorization: token $TOKEN" https://github.boozallencsn.com/api/v3/repos/$OWNER/$REPO/labels/$name
    sleep 1
done < <(echo $json | jq -r '.[].name')
