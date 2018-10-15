#!/bin/bash
#
#  Init script for Spark Standalone
#
#  Timothy C. Arland <tcarland@gmail.com>
#
ACTION="$1"
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HADOOP_ENV="hadoop-env-user.sh"
SPARK_PID="org.apache.spark.deploy.master.Master"
PID=

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


if [ -z "$SPARK_USER" ]; then
    SPARK_USER="$USER"
fi
if [ -z "$HADOOP_USER" ]; then
    HADOOP_USER="$SPARK_USER"
fi



usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $HADOOP_ENV_USER_VERSION"
}


check_process_pid()
{
    local pid=$1

    if ps ax | grep $pid | grep -v grep 1> /dev/null 2> /dev/null ; then
        return 1
    fi

    return 0
}

get_pid()
{
    PID=`ps ax | grep java | grep $SPARK_PID | grep -v grep | awk '{ print $1 }'`
}

check_process()
{
    local ret=0

    get_pid

    if [ -n "$PID" ]; then
        check_process_pid $PID
        ret=$?
    fi

    return $ret
}

show_status()
{
    local ret=0

    check_process
    ret=$?
    if [ $ret -ne 0 ]; then
        echo " Spark Standalone      [$PID]"
    else
        echo " Spark Standalone Server is not running"
    fi

    return $ret
}



r=0

case "$ACTION" in
    'start')
        check_process
        r=$?
        if [ $r -ne 0 ]; then
            echo "Error: Spark Master is already running [$PID]"
            exit $r
        fi

        echo "Starting Spark Standalone..."
        ( sudo -u $HADOOP_USER $SPARK_HOME/sbin/start-all.sh )
        ;;

    'stop')
        check_process $SPARK_PID
        r=$?
        if [ $r -ne 0 ]; then
            echo "Stopping Spark Standalone..."
            ( sudo -u $HADOOP_USER $SPARK_HOME/sbin/stop-all.sh )
        else
            echo " Spark Master not running.."
            exit $r
        fi
        ;;

    'status'|'info')
        show_status
        ;;
    *)
        usage
        ;;
esac

exit $r
