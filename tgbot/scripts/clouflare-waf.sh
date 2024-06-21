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
RULES=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/firewall/rules" \
       -H "Authorization: Bearer ${API_TOKEN}" \
       -H "Content-Type: application/json")
#獲取RULEID(自訂WAF的ID)
RULESETID=$(curl -s --request GET \
  --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets \
  --header "Authorization: Bearer ${API_TOKEN}" \
  --header 'Content-Type: application/json'| jq -r '.result[] | select(.source == "firewall_custom") | .id')
CTMRULELIST=$(curl -s --request GET \
  --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/$RULESETID \
  -H "Authorization: Bearer ${API_TOKEN}" \
  --header 'Content-Type: application/json')
# 查找描述为"Block Taiwan"的规则并修改表达式
# 查找描述为"Block Taiwan"的规则并修改表达式
NEW_EXPRESSION='(ip.geoip.country in {"TW"} and not ip.src in {125.227.69.109, 125.227.69.112})'
RULE_ID=$(echo $CTMRULELIST | jq -r '.result.rules[] | select(.description=="Block Taiwan") | .id')
RULE_ID1=$(echo $CTMRULELIST | jq -r '.result.rules[] | select(.description=="Block-Taiwan") | .id')
RULE_NAME=$(echo $CTMRULELIST | jq -r '.result.rules[].description')
echo changing


if [ "$RULE_NAME" == "Block Taiwan" ];then
  echo "我在執行BlockTaiwan"
  curl -s --request PATCH \
  --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/$RULESETID/rules/$RULE_ID \
  --header "Authorization: Bearer ${API_TOKEN}" \
  --header 'Content-Type: application/json' \
  --data '{
  "action": "block",
  "description": "Block Taiwan",
  "enabled": true,
  "expression": "(ip.geoip.country in {\"TW\"} and not ip.src in {125.227.69.109 125.227.69.112 18.162.210.214})"
  }'| jq '{success: .success, errors: .errors, messages: .messages}'
elif [ "$RULE_NAME" == "Block-Taiwan" ];then
  echo "我在執行B-T"
  curl -s --request PATCH \
  --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/$RULESETID/rules/$RULE_ID1 \
  --header "Authorization: Bearer ${API_TOKEN}" \
  --header 'Content-Type: application/json' \
  --data '{
  "action": "block",
  "description": "Block-Taiwan",
  "enabled": true,
  "expression": "(ip.geoip.country in {\"TW\"} and not ip.src in {125.227.69.109 125.227.69.112 18.162.210.214})"
  }'| jq '{success: .success, errors: .errors, messages: .messages}'
elif [ -z "$RULE_NAME" ];then
  echo "原本沒有規則,創建中"
  curl -s --request POST \
  --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets \
  --header "Authorization: Bearer ${API_TOKEN}" \
  --header 'Content-Type: application/json' \
  --data '{
  "description": "",
  "name": "default",
  "kind": "zone",
  "phase": "http_request_firewall_custom",
  "rules": [
  {
      "action": "block",
      "description": "Block Taiwan",
      "enabled": true,
      "expression": "(ip.geoip.country in {\"TW\"} and not ip.src in {125.227.69.109 125.227.69.112 18.162.210.214})"
   } 
  ]
}'| jq '{success: .success, errors: .errors, messages: .messages}'
#  curl --request POST \
#  --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/$RULESETID/rules \
#  --header "Authorization: Bearer ${API_TOKEN}" \
#  --header 'Content-Type: application/json' \
#  --data '{
#  "action": "block",
#  "action_parameters": {
#    "response": {
#      "content": "{\n  \"success\": false,\n  \"error\": \"you have been blocked\"\n}",
#      "content_type": "application/json",
#      "status_code": 400
#    },
#  "description": "Block Taiwan",
#  "enabled": true,
#  "expression": "(ip.geoip.country in {\"TW\"} and not ip.src in {125.227.69.109 125.227.69.112 18.162.210.214})"
#  }'
else
  echo error!!!!
fi
done
