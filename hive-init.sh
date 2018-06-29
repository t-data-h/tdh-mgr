#!/bin/bash
#
#  Init script for Hive
#
#  Timothy C. Arland <tcarland@gmail.com>
#
ACTION="$1"
PNAME=${0##*\/}
VERSION="0.511"
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"


HADOOP_ENV="hadoop-env-user.sh"

# source the hadoop-env-user script
if [ -z "$HADOOP_ENV_USER" ]; then
    if [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then
        HADOOP_ENV="$HOME/hadoop/etc/$HADOOP_ENV"
    elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
        HADOOP_ENV="/etc/hadoop/$HADOOP_ENV"
    elif [ -r "./$HADOOP_ENV" ]; then
        HADOOP_ENV="./$HADOOP_ENV"
    fi
    source $HADOOP_ENV
fi


HIVEMETASTORE="MetaStore"
HIVESERVER2="HiveServer2"
HIVE_LOGDIR="/var/log/hadoop/hive"
METASTORE_LOG="$HIVE_LOGDIR/hive-metastore.log"
HIVESERVER2_LOG="$HIVE_LOGDIR/hiveserver2.log"
METADB="mysqld"
HPID=0


if [ -z "$HADOOP_USER" ]; then
    HADOOP_USER="$USER"
fi

if [ -n "$HADOOP_LOGDIR" ]; then
    HIVE_LOGDIR="$HADOOP_LOGDIR/hive"
fi


usage() 
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $VERSION"
}


get_process_pid()
{
    local key="$1"
    local pids=

    HPID=0
    pids=$(ps awwwx | grep "$key" | grep -v "grep" | awk '{ print $1 }')

    for p in $pids; do
        HPID=$p
        break
    done

    return 0
}


show_status()
{
    get_process_pid $HIVEMETASTORE
    if [ $HPID -ne 0 ]; then
        echo " Hive Metastore        [$HPID]"
    else
        echo " Hive Metastore is not running"
    fi

    get_process_pid $HIVESERVER2
    if [ $HPID -ne 0 ]; then
        echo " HiveServer2           [$HPID]"
    else
        echo " HiveServer2 is not running"
    fi

    return $HPID 
}


pid=0
rt=0


case "$ACTION" in

    'start')
        get_process_pid $HIVEMETASTORE
        if [ $HPID -ne 0 ]; then
            echo " MetaStore is already running  [$HPID]"
            exit $HPID
        fi

        get_process_pid $HIVESERVER2
        if [ $HPID -ne 0 ]; then
            echo " HiveServer2 is already running [$HPID]"
            exit $HPID
        fi

        get_process_pid $METADB
        if [ $HPID -eq 0 ]; then
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
        if [ $HPID -ne 0 ]; then
            echo "Stopping Hive MetaStore [$HPID]..."
            ( sudo -u $HADOOP_USER kill $HPID )
        else
            echo "Hive Metastore process not found..."
        fi

        get_process_pid $HIVESERVER2
        if [ $HPID -ne 0 ]; then
            echo "Stopping HiveServer2 [$HPID]..."
            ( sudo -u $HADOOP_USER kill $HPID )
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
