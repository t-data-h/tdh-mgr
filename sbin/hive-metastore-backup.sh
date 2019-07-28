#!/bin/bash
#
#  Do a full Hive Metastore dump including the schema


dbhost="$1"
dbport="$2"
dbname="$3"

if [ -z "$dbhost" ]; then
    echo "Usage: $0  [dbhost] <dbport> <dbname>"
    echo "  port will default to 3306 and dbname to 'metastore'"
    exit 1
fi

if [ -z "$dbport" ]; then
    dbport="3306"
fi
if [ -z "$dbname" ]; then 
    dbname="metastore"
fi

( mysqldump -u hive -p -h $dbhost -P $dbport --opt $dbname > $dbname-$dbhost-backup.sql )

( mysqldump -u hive -p -h $dbhost -P $dbport --skip-add-drop-table --no-data $dbname > hive-$dbhost-schema-1.2.1.mysql.sql )

exit $?
