#!/bin/bash

set -xe

HUB_AUTHORIZATION_HEADER="Authorization: Basic $(echo -n ${HUB_ADMIN_LOGIN}:${HUB_ADMIN_PASSWORD} | base64)"
REST_API_URL="${HUB_BASE_URL}:8080/hub/api/rest"
TOKEN_FILE="/home/storage/hub.token"

hub_post() {
  curl -s -X "POST" -H "$HUB_AUTHORIZATION_HEADER" -H "Content-Type: application/json;charset=UTF-8" "${REST_API_URL}$1" -d "$2"
}


setup_hub_access() {
  hub_post "/services" "{\
    \"name\": \"datalore\", \
    \"homeUrl\": \"${DATALORE_BASE_URL}\", \
    \"id\": \"datalore\", \
    \"secret\": \"${HUB_DATALORE_SERVICE_SECRET}\", \
    \"iconUrl\": \"data:image/png;base64,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\", \
    \"baseUrls\": [\"${DATALORE_BASE_URL}\"], \
    \"redirectUris\": [\"/api/hub/openid/login\"], \
    \"trusted\": true \
  }"

  HUB_PERM_TOKEN=$(hub_post "/users/me/permanenttokens?fields=token" "{\
      \"scope\": [\
        {\
          \"id\":\"0-0-0-0-0\",\
          \"key\":\"0-0-0-0-0\",\
          \"label\":\"Hub\",\
          \"data\": {\
            \"id\":\"0-0-0-0-0\",\
            \"name\":\"Hub\",\
            \"applicationName\":\"Hub\"\
          }\
        },\
        {\
          \"id\":\"datalore\",\
          \"key\":\"datalore\",\
          \"label\":\"datalore\",\
          \"data\":{\
            \"id\":\"datalore\",\
            \"name\":\"datalore\"\
          }\
        }\
      ],\
      \"name\":\"datalore_token\"\
    }" | jq --raw-output '.token')
}

timeout 60 bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' http://hub:8080/hub/api/rest/users/guest )" != "200" ]]; do sleep 5; done' || false

if [ -s ${TOKEN_FILE} ]; then
  HUB_PERM_TOKEN=$(cat ${TOKEN_FILE})
else
  setup_hub_access
  echo -n ${HUB_PERM_TOKEN} > ${TOKEN_FILE}
fi

export HUB_PERM_TOKEN

cd /opt/bazel && ./entrypoint.sh
