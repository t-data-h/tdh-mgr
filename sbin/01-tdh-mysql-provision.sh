#!/bin/bash
#
#  Initiate mysql schema(s)
#   assumes the secret file '~/.my.cnf' is configured.
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

hivedb="metastore"
hive_schema_path="/opt/TDH/hive/scripts/metastore/upgrade/mysql"
hive_schema="${hive_schema_path}/hive-schema-1.2.0.mysql.sql"
rt=


if [ -n "$1" ]; then
    hivedb="$1"
fi
echo "$PNAME initializing Hive Db: '$hivedb'"

# create db
( mysql -e "CREATE DATABASE IF NOT EXISTS $hivedb" )
rt=$?

if [ $rt -ne 0 ]; then
    echo "Error in MySQL 'CREATE DATABASE'"
    exit $rt
fi

# import the hive mysql schema
# Note that this may require an update to the hive-txn schema path, but
# change directory should work as the schema uses relative path
( cd $hive_schema_path; mysql metastore < $hive_schema )
rt=$?

if [ $rt -ne 0 ]; then
    echo "Error in import of hive metastore schema"
fi

exit $rt
