#!/bin/bash
#
#  Do a full Hive Metastore dump including the schema
PNAME=${0##*\/}

dbhost="$1"
dbport="${2:-3306}"
dbname="${3:-metastore}"
dbuser="${4:-hive}"

mydump=$(which mysqldump 2>/dev/null)

usage="
Usage: $PNAME  [dbhost] <dbport> <dbname> <dbuser>
  <dbport> will default to 3306, 
  <dbname> defaults to 'metastore'
  <dbuser> defaults to 'hive'
"

if [ -z "$dbhost" ]; then
    echo "$usage"
    exit 1
fi

if [ -z "$mydump" ]; then
    echo "$PNAME Error, binary for 'mysqldump' was not found in the PATH"
    exit 2
fi

# full backup
( mysqldump -u $dbuser -p -h $dbhost -P $dbport \
  --opt $dbname > $dbname-$dbhost-backup.sql )

# schema backup
( mysqldump -u $dbuser -p -h $dbhost -P $dbport \
  --skip-add-drop-table \
  --no-data $dbname > hive-$dbhost-schema-2.3.6.mysql.sql )

echo "$PNAME Finished."

exit $?
