#!/usr/bin/env sh

set -e

while [ ! -s /cockroach/cockroach-data/ca.crt ]
do
    echo Wating for CA.crt to be present...
    sleep 5
done

while /cockroach/cockroach.sh node status --host=roach1 --certs-dir=/cockroach/cockroach-data; ret=$? ; [ $ret -ne 0 ];do
    echo Waiting for http://roach1:8080/ to be up...
    sleep 5
done

/cockroach/cockroach.sh sql --host=roach1 --certs-dir=/cockroach/cockroach-data --execute="CREATE USER IF NOT EXISTS jpointsman WITH PASSWORD 'Q7gc8rEdS';"

