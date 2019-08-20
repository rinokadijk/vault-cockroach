#!/usr/bin/env sh

set -e

while [ ! -s /cockroach/cockroach-data/ca.crt ]
do
    echo Wating for CA.crt to be present...
    sleep 5
done

while /cockroach/cockroach.sh node status; ret=$?; [ $ret -ne 0 ];do
    echo Waiting ${COCKROACH_HOST} to be up...
    sleep 5
done

exec /cockroach/cockroach.sh sql --execute="CREATE USER IF NOT EXISTS jpointsman WITH PASSWORD 'Q7gc8rEdS';
CREATE DATABASE IF NOT EXISTS jpointsmandb;
GRANT ALL ON DATABASE jpointsmandb TO jpointsman;"

