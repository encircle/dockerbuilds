#!/bin/sh

clamrest_host=$AV_HOST
clamrest_port=$AV_PORT
file=$1

result=$(curl -s -F "data=@$file" "http://$clamrest_host:$clamrest_port/scan")

if [[ $result == '"OK"' ]]; then
  echo 1
elif [[ $result == '"NOTOK"' ]]; then
  echo 0
fi
