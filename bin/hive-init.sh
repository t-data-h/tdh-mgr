#!/bin/bash
#
#  Init script for Hive
#
#  Timothy C. Arland <tcarland@gmail.com>
#
ACTION="$1"
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HADOOP_ENV="hadoop-env-user.sh"

# source the hadoop-env-user script
if [ -z "$HADOOP_ENV_USER" ]; then
    if [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then
        . $HOME/hadoop/etc/$HADOOP_ENV
    elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
        . /etc/hadoop/$HADOOP_ENV
    elif [ -r "./etc/$HADOOP_ENV" ]; then
        . ./etc/$HADOOP_ENV
    fi
fi

HIVEMETASTORE="MetaStore"
HIVESERVER2="HiveServer2"
HIVE_LOGDIR="/var/log/hadoop/hive"
METASTORE_LOG="$HIVE_LOGDIR/hive-metastore.log"
HIVESERVER2_LOG="$HIVE_LOGDIR/hiveserver2.log"
METADB="mysqld"
PID=0


if [ -n "$HADOOP_LOGDIR" ]; then
    HIVE_LOGDIR="$HADOOP_LOGDIR/hive"
fi


usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $HADOOP_ENV_USER_VERSION"
}


get_process_pid()
{
    local key="$1"
    local pids=

    PID=0
    pids=$(ps awwwx | grep "$key" | grep -v "grep" | awk '{ print $1 }')

    for p in $pids; do
        PID=$p
        break
    done

    return 0
}


show_status()
{
    get_process_pid $HIVEMETASTORE
    if [ $PID -ne 0 ]; then
        echo " Hive Metastore        [$PID]"
    else
        echo " Hive Metastore is not running"
    fi

    get_process_pid $HIVESERVER2
    if [ $PID -ne 0 ]; then
        echo " HiveServer2           [$PID]"
    else
        echo " HiveServer2 is not running"
    fi

    return $PID
}


# =================
#  MAIN
# =================


rt=0

echo " ------ Hive ---------"

case "$ACTION" in

    'start')
        get_process_pid $HIVEMETASTORE
        if [ $PID -ne 0 ]; then
            echo " MetaStore is already running  [$PID]"
            exit $PID
        fi

        get_process_pid $HIVESERVER2
        if [ $PID -ne 0 ]; then
            echo " HiveServer2 is already running [$PID]"
            exit $PID
        fi

        get_process_pid $METADB
        if [ $PID -eq 0 ]; then
            echo "Mysqld is not running! aborting..."
            exit 1
        fi

        echo "Starting MetaStore..."
        ( sudo -u $HADOOP_USER nohup $HIVE_HOME/bin/hive --service metastore > $METASTORE_LOG & )

        echo "Starting HiveServer2..."
        ( sudo -u $HADOOP_USER nohup $HIVE_HOME/bin/hive --service hiveserver2 > $HIVESERVER2_LOG & )
        ;;

    'stop')
        get_process_pid $HIVEMETASTORE
        if [ $PID -ne 0 ]; then
            echo "Stopping Hive MetaStore [$PID]..."
            ( sudo -u $HADOOP_USER kill $PID )
        else
            echo "Hive Metastore process not found..."
        fi

        get_process_pid $HIVESERVER2
        if [ $PID -ne 0 ]; then
            echo "Stopping HiveServer2 [$PID]..."
            ( sudo -u $HADOOP_USER kill $PID )
        else
            echo "HiveServer2 process not found..."
        fi
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
