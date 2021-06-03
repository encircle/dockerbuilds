#!/bin/sh

# required variables
[ -z $1 ] && echo 'no file provided' && echo 0 && exit 1
[ -z ${AV_HOST} ] && echo 'no AV host provided' && exit 1
[ -z ${AV_PORT} ] && echo 'no AV port provided' && exit 1
[ -z ${AV_APIKEY} ] && echo 'no AV API key provided' && exit 1

file=$1

# send file for scanning
response=$(echo $(curl \
              -H "X-API-Key: ${AV_APIKEY}" \
	      --silent \
              --write-out %{http_code} \
              --insecure \
              --form "data=@$file" \
              "https://${AV_HOST}:${AV_PORT}/scan"
	  ))

# AV server is down
[ "$response" -eq 000 ] && echo 0 && exit

# get response JSON and code
return_json=$( echo $response | awk '{print $1}')
return_code=$( echo $response | awk '{print $2}')

# antivirus is unavailable, exit bad status
[ $return_code != 200 ] && echo 0 && exit

# get task id from response
task_id=$(echo $return_json | jq -r '.task_id')

# loop until task is finished
attempts=0
while true; do
    [ $attempts -eq 11 ] && result='NOTOK' && break
    response=$(echo $(curl \
                  -H "X-API-Key: ${AV_APIKEY}" \
                  --silent \
                  --write-out %{http_code} \
                  --insecure \
                  "https://${AV_HOST}:${AV_PORT}/task?id=${task_id}"
             ))
    return_json=$( echo $response | awk '{print $1}')
    status=$(echo $return_json | jq -r '.task_status')
    [ "$status" = 'PENDING' ] && continue
    result=$(echo $return_json | jq -r '.task_result')
    [ $status = 'SUCCESS' ] && break
    attempts=$((attempts+1))
    sleep 5
done

###
# Modsec codes
# 1 -> success
# 0 -> failure
###

# virus detected, exit bad status
[ "$result" = 'NOTOK' ] && echo 0 && exit

# File is clear
[ "$result" = 'OK' ] && echo 1 && exit
