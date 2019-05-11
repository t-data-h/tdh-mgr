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
HIVE_LOGDIR="${HADOOP_LOGDIR}/hive"
METASTORE_LOG="${HIVE_LOGDIR}/hive-metastore.log"
HIVESERVER2_LOG="${HIVE_LOGDIR}/hiveserver2.log"
METADB="mysqld"

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "/opt/TDH/etc/$HADOOP_ENV" ]; then        # /opt/TDH   is default
    . /opt/TDH/etc/$HADOOP_ENV
elif [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then    # $HOME is last
    . $HOME/hadoop/etc/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
# -----------



usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $TDH_VERSION"
}


show_status()
{
    #get_process_pid $HIVEMETASTORE
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
        echo " HiveServer2           [$PID]"
    else
        echo " HiveServer2 is not running"
    fi

    return $rt
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

echo " ------ Hive ---------"

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
