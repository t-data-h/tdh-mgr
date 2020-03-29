#!/bin/bash
#
#  Do a full Hive Metastore dump including the schema

dbhost="$1"
dbport="${2:-3306}"
dbname="${3:-metastore}"
dbuser="${4:-hive}"

if [ -z "$dbhost" ]; then
    echo "Usage: $0  [dbhost] <dbport> <dbname> [dbuser]"
    echo "  port will default to 3306, dbname to 'metastore'"
    echo "  and dbuser to 'hive'"
    exit 1
fi

# full backup
( mysqldump -u $dbuser -p -h $dbhost -P $dbport \
  --opt $dbname > $dbname-$dbhost-backup.sql )

# schema backup
( mysqldump -u $dbuser -p -h $dbhost -P $dbport \
  --skip-add-drop-table \
  --no-data $dbname > hive-$dbhost-schema-2.3.6.mysql.sql )

echo "Finished."

exit $?
