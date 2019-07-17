#!/bin/bash
#
#  Init script for Hive
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HIVEMETASTORE="MetaStore"
HIVESERVER2="HiveServer2"
METADB="mysqld"

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "/opt/TDH/etc/$HADOOP_ENV" ]; then
    . /opt/TDH/etc/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi

# -----------

HIVE_VER=$(readlink $HIVE_HOME)
HIVE_LOGDIR="${HADOOP_LOGDIR}/hive"
METASTORE_LOG="${HIVE_LOGDIR}/hive-metastore.log"
HIVESERVER2_LOG="${HIVE_LOGDIR}/hiveserver2.log"

HOST=$(hostname -s)
HIVE_SERVER=$( grep -A1 'hive.metastore.uris' ${HIVE_HOME}/conf/hive-site.xml | grep value | \
  sed  -E 's/.*<value>thrift:\/\/(.*)<\/value>/\1/' | awk -F':' '{ print $1 }' )

# -----------

usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    ( echo $HIVE_SERVER | grep $HOST > /dev/null )
    if [ $? -eq 0 ]; then
        check_process $HIVEMETASTORE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " Hive Metastore        [$PID]"
        else
            echo " Hive Metastore is not running"
        fi

        check_process $HIVESERVER2
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " Hive Server           [$PID]"
        else
            echo " Hive Server is not running"
        fi
    else
            echo " Hive Server           [$HIVESERVER]"
    fi

    return $rt
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

echo " ------- $HIVE_VER ---------- "

case "$ACTION" in

    'start')
        check_process $METADB
        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Mysqld is not running! aborting..."
            exit $rt
        fi

        check_process $HIVEMETASTORE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " MetaStore is already running  [$PID]"
            exit $rt
        fi

        check_process $HIVESERVER2
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " HiveServer2 is already running [$PID]"
            exit $rt
        fi

        ( mkdir -p $HIVE_LOGDIR )

        echo "Starting Hive MetaStore..."
        ( sudo -u $HADOOP_USER nohup $HIVE_HOME/bin/hive --service metastore 2>&1 > $METASTORE_LOG & )

        echo "Starting HiveServer2..."
        ( sudo -u $HADOOP_USER nohup $HIVE_HOME/bin/hive --service hiveserver2 2>&1 > $HIVESERVER2_LOG & )
        ;;

    'stop')
        check_process $HIVEMETASTORE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Stopping Hive MetaStore [$PID]..."
            ( sudo -u $HADOOP_USER kill $PID )
        else
            echo "Hive Metastore process not found..."
        fi

        check_process $HIVESERVER2
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Stopping HiveServer2 [$PID]..."
            ( sudo -u $HADOOP_USER kill $PID )
        else
            echo "HiveServer2 process not found..."
        fi
        rt=0
        ;;

    'status'|'info')
        show_status
        rt=$?
        ;;
    *)
        usage
        ;;
esac

exit $rt
