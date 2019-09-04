#!/bin/bash
#
#  Initiate mysql schema(s)
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"
rt=

# hive
mysql -e 'CREATE DATABASE IF NOT EXISTS metastore'

rt=$?

if [ $rt -ne 0 ]; then
    echo "Error in CREATE DATABASE"
    exit $rt
fi

# import schema (note that this may require an update to hive-txn schema path
mysql metastore < /opt/TDH/hive/scripts/metastore/upgrade/mysql/hive-schema-1.2.0.mysql.sql

rt=$?
if [ $rt -ne 0 ]; then
    echo "Error in import of metastore schema"
    exit $rt
fi

exit $rt
