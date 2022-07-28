#! /bin/bash -e

# see https://docs.github.com/en/enterprise-server@3.1/rest/enterprise-admin/repo-pre-receive-hooks

# can uncomment the below for local testing
#TOKEN=""
#OWNER="Solutions-Center"
#REPO=""
#HOOKNAME="OWASP SEDATED"

HOSTNAME="https://github.boozallencsn.com"

json=$(curl -H "Accept: application/vnd.github+json" -H "Authorization: token $TOKEN" $HOSTNAME/api/v3/repos/$OWNER/$REPO/pre-receive-hooks)

while read -r i ; do
    hookid=$(echo $json | jq -r --arg NAME "$i" '.[] | select(.name == $NAME) | .id')
    #echo "name:$i id:$hookid"
    if [ "$HOOKNAME" == "$i" ]
    then
      #echo "name:$i id:$hookid"
      curl -X PATCH -H "Accept: application/vnd.github+json" -H "Authorization: token $TOKEN" $HOSTNAME/api/v3/repos/$OWNER/$REPO/pre-receive-hooks/$hookid -d '{"enforcement":"enabled"}'
    fi
done < <(echo $json | jq -r '.[].name')
