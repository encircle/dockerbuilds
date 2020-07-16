#!/bin/sh

exec 1> /tmp/antivirus.log 2>&1
set -x

[[ -z $1 ]] && echo 0 && exit

file=$1

response=$(echo $(curl --cert /etc/nginx/certs/client.crt \
	      --silent \
     	      --key /etc/nginx/certs/client.key \
              --write-out %{http_code} \
              --insecure \
              --form "data=@$file" \
              "https://$AV_HOST:$AV_PORT/scan"
	  ))

# AV server is down
[[ "$response" == '000' ]] && echo 0 && exit

return_text=$( echo $response | awk '{print $1}')
return_code=$( echo $response | awk '{print $2}')

###
# Modsec codes
# 1 -> success
# 0 -> failure
###

# AV server is unavailable or virus detected
[[ $return_code != 200 ]] || [[ $return_text == '"NOTOK"' ]] && echo 0 && exit

# File is clear
[[ $return_text == '"OK"' ]] && echo 1 && exit
