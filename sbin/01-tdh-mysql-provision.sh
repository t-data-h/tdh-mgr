#!/bin/bash
#
#  Initiate hive mysql schema. This assumes the MySQL itself and the
#  secret file '~/.my.cnf' is configured to avoid password prompts.
# 
#  $ cat ~/.my.cnf
#   [mysql]
#   user=root
#   host=myhostname
#   password=mypw
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

hivedb="metastore"
hive_dir="${HIVE_HOME}"
hive_ver=
hive_schema_ver=
hive_schema_path="scripts/metastore/upgrade/mysql"
hive_schema=
mysql=$(which mysql 2>/dev/null)
rt=

usage="
Initiates the Hive Metastore database within MySQL.
The script assumes the secret is configured via '~/.my.cnf'

Synopsis:
$PNAME <dbname>

<dbname> defaults to '$hivedb'
"

if [ -n "$1" ]; then
    case "$1" in 
        'help'|-h|--help)
            echo "$usage"
            exit 0
            ;;
        'version'|-V|--version)
            tdh_version
            exit 0
            ;;
        *)
            hivedb="$1"
            ;;
    esac
fi

if [ -z "$mysql" ]; then
    echo "$PNAME Error, 'mysql' client not found in PATH"
    exit 2
fi

# -------------------------------------
# Set Hive real path locations

if [ -z "$hive_dir" ]; then
    hive_dir="$HADOOP_ROOT"
    if [ -n "$hive_dir" ]; then
        hive_dir="$hive_dir/hive"
    else
        hive_dir="/opt/TDH/hive"
    fi
fi

hive_dir=$( readlink -f $hive_dir )

if [ ! -d $hive_dir ]; then
    echo "$PNAME Error locating HIVE_HOME"
    exit 1
fi

# -------------------------------------
# Set hive schema version
if [[ $hive_dir =~ ^.*-[0-9]+ ]]; then
    hive_ver=${hive_dir##*-}
fi

rever='([0-9]\.[0-9])\.[0-9]'

if [[ $hive_ver =~ $rever ]]; then
    hive_schema_ver="${BASH_REMATCH[1]}.0"
fi

if [ -z "$hive_schema_ver" ]; then
    echo "$PNAME Error determining HIVE schema version"
    exit 1
fi

hive_schema_path="${hive_dir}/${hive_schema_path}"
hive_schema="hive-schema-${hive_schema_ver}.mysql.sql"

if [ ! -f ${hive_schema_path}/${hive_schema} ]; then
    echo "$PNAME Error locating hive schema file '$hive_schema_path/$hive_schema'"
    exit 1
fi

# -------------------------------------
echo "
$PNAME initializing Hive Db: '$hivedb'
  Schema File: '$hive_schema'
"

# create db
( mysql -e "CREATE DATABASE IF NOT EXISTS $hivedb" )
rt=$?

if [ $rt -ne 0 ]; then
    echo "$PNAME Error in MySQL 'CREATE DATABASE'"
    exit $rt
fi

# Import the hive mysql schema
# Note that the schema relies on relative path to import/include
# the hive-txn schema file thus change directory is needed or the
# relative path would need changing to absolute path.
( cd $hive_schema_path; mysql $hivedb < $hive_schema )
rt=$?

if [ $rt -ne 0 ]; then
    echo "Error in import of hive metastore schema"
fi

echo "$PNAME finished."
exit $rt
