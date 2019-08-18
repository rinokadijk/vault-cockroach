#!/usr/bin/env sh

set -e

while [ ! -s /cockroach/cockroach-data/ca.crt ]
do
    echo Wating for CA.crt to be present...
    sleep 2
done

/cockroach/cockroach.sh start --join=roach1,roach2 --certs-dir=/cockroach/cockroach-data --advertise-addr=roach3 --log-dir=/cockroach/cockroach-data/logs

