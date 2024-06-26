#!/bin/bash

API_TOKEN="Jt9jGe3dyoDLqjU1kTS0iUFowow_m-rQI9JUE758"
for DOMAIN in "$@"
do
  # 获取 ZONE ID LIST
  echo "Processing domain: $DOMAIN"
  RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Content-Type: application/json")
  
  # 获取输入的 DOMAIN 的 ZONE ID
  ZONE_ID=$(echo $RESPONSE | jq -r --arg DOMAIN "$DOMAIN" '.result[] | select(.name==$DOMAIN) | .id')
  
  # 获取自定义 WAF 的 RULESET ID
  RULESETID=$(curl -s --request GET \
    --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets \
    --header "Authorization: Bearer ${API_TOKEN}" \
    --header 'Content-Type: application/json' | jq -r '.result[] | select(.source == "firewall_custom") | .id')
  
  # 获取规则列表
  CTMRULELIST=$(curl -s --request GET \
    --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/$RULESETID \
    -H "Authorization: Bearer ${API_TOKEN}" \
    --header 'Content-Type: application/json')
  # 查找描述为 "Block Taiwan" 或 "Block-Taiwan" 的规则并修改表达式
  NEW_EXPRESSION='(ip.geoip.country in {\"TW\"} and not ip.src in {125.227.69.109 125.227.69.112 18.162.210.214})'
  RULES_FOUND=false
  
  RULES=$(echo $CTMRULELIST | jq -r '.result.rules[] | @base64')
  for RULE in $RULES; do
    RULE_ID=$(echo $RULE | base64 --decode | jq -r '.id')
    RULE_DESC=$(echo $RULE | base64 --decode | jq -r '.description')
    
    if [[ "$RULE_DESC" =~ .*Block.*Taiwan ]]; then
      RULES_FOUND=true
      echo "找到规则: $RULE_DESC，修改中..."
      curl -s --request PATCH \
        --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/$RULESETID/rules/$RULE_ID \
        --header "Authorization: Bearer ${API_TOKEN}" \
        --header 'Content-Type: application/json' \
        --data '{
        "action": "block",
        "description": "'"${RULE_DESC}"'",
        "enabled": true,
        "expression": "'"${NEW_EXPRESSION}"'"
      }' | jq '{success: .success, errors: .errors, messages: .messages}'
    fi
  done
  
  if [ "$RULES_FOUND" = false ]; then
    echo "未找到相关规则，创建新规则中..."
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
          "expression": "'"${NEW_EXPRESSION}"'"
        } 
      ]
    }' | jq '{success: .success, errors: .errors, messages: .messages}'
  fi

done
