#!/bin/bash

#read -p "请输入域名: " -a DOMAINS

API_TOKEN="Jt9jGe3dyoDLqjU1kTS0iUFowow_m-rQI9JUE758"
for DOMAIN in "$@"
do

#獲取ZONEID LIST
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
       -H "Authorization: Bearer ${API_TOKEN}" \
       -H "Content-Type: application/json")
#獲取輸入的DOMAIN的ZONEID
ZONE_ID=$(echo $RESPONSE | jq -r --arg DOMAIN "$DOMAIN" '.result[] | select(.name==$DOMAIN) | .id')
#舊版獲取RULEID


curl -s --request POST \
  --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache \
  --header 'Content-Type: application/json' \
  --header 'X-Auth-Key: 25f5607b58eeab07ef8c21869ad11e4e8c4e4' \
  --header 'X-Auth-Email: shawn.fu@rayprosoft.com' \
  -d '{"purge_everything":true}'
done
