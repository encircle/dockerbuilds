#!/bin/sh
if [ ! -d /etc/opendkim/keys ]; then
    sleep 9999999999999999999
elif [ -z "$(find /etc/opendkim/keys -type f ! -name .)" ]; then
    sleep 9999999999999999999
else
    /usr/sbin/opendkim -D -f -x /etc/opendkim/opendkim.conf
fi
