FROM python:3.7.7-alpine3.12

# Clamd setup #
RUN apk add clamav clamav-libunrar
RUN mkdir /run/clamav
RUN chown clamav:clamav /run/clamav
RUN chmod 750 /run/clamav
COPY conf/restingclam/clamd.conf /etc/clamav/clamd.conf
COPY conf/restingclam/freshclam.conf /etc/clamav/freshclam.conf
RUN freshclam
# Clamd Setup

# ClamAV Rest setup #
COPY conf/restingclam/requirements.txt /requirements.txt

RUN apk add gcc \
 && pip install -r /requirements.txt \
 && apk del gcc

COPY scripts/restingclam/rest.py /rest.py
# ClamAV Rest Setup #

RUN mkdir /var/run/gunicorn

COPY entry/restingclam/entrypoint.sh /entrypoint.sh

WORKDIR '/'
ENTRYPOINT [ "sh", "entrypoint.sh" ]
