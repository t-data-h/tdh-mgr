#!/bin/bash
#

HOST="$1"

if [ -z $HOST ]; then
    echo "Need a hostname for grant privileges."
    echo "$0 <hostname>"
    exit 1
fi


# hive
mysql -u root -p -e 'CREATE DATABASE IF NOT EXISTS metastore'
mysql -u root -p -e "GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'localhost' IDENTIFIED BY 'chhive'"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'${HOST}' IDENTIFIED BY 'chhive'"

# import schema (note that this may require an update to hive-txn schema path
mysql -u hive -p metastore < /opt/hadoop/hive/scripts/metastore/upgrade/mysql/hive-schema-1.2.0.mysql.sql

# hue
mysql -u root -p -e 'CREATE DATABASE IF NOT EXISTS hue'
mysql -u root -p -e "GRANT ALL PRIVILEGES ON hue.* TO 'hue'@'localhost' IDENTIFIED BY 'chhue'"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON hue.* TO 'hue'@'${HOST}' IDENTIFIED BY 'chhue'"


