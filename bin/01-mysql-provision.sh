#!/bin/bash
#

HOST=$(hostname -f)
rt=

# hive
mysql -e 'CREATE DATABASE IF NOT EXISTS metastore'

rt=$?

if [ $rt -ne 0 ]; then
    echo "Error in CREATE DATABASE"
    exit $rt
fi

mysql -e "GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'localhost' IDENTIFIED BY 'TDH@hive11b'"
mysql -e "GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'${HOST}' IDENTIFIED BY 'TDH@hive11b'"

# import schema (note that this may require an update to hive-txn schema path
mysql metastore < /opt/TDH/hive/scripts/metastore/upgrade/mysql/hive-schema-1.2.0.mysql.sql

rt=$?
if [ $rt -ne 0 ]; then
    echo "Error in import of metastore schema"
    exit $rt
fi

# hue
mysql -e 'CREATE DATABASE IF NOT EXISTS hue'
mysql -e "GRANT ALL PRIVILEGES ON hue.* TO 'hue'@'localhost' IDENTIFIED BY 'TDH@huexp11b'"
mysql -e "GRANT ALL PRIVILEGES ON hue.* TO 'hue'@'${HOST}' IDENTIFIED BY 'TDH@huexp11b'"

rt=$?

exit $rt


