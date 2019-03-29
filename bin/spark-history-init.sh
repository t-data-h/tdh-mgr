#!/bin/bash
#
##  Timothy C. Arland <tcarland@gmail.com>
#
ACTION="$1"
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HADOOP_ENV="hadoop-env-user.sh"
SPARK_PID="org.apache.spark.deploy.history.HistoryServer"
PID=


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


if [ -z "$SPARK_USER" ]; then
    SPARK_USER="$HADOOP_USER"
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
    PID=$(ps ax | grep java | grep $SPARK_PID | grep -v grep | awk '{ print $1 }')
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
        echo " Spark2 HistoryServer  [$PID]"
    else
        echo " Spark2 HistoryServer is not running"
    fi

    return $ret
}


# =================
#  MAIN
# =================


r=0

echo " ------ Spark2 ------- "

case "$ACTION" in
    'start')
        check_process
        r=$?
        if [ $r -ne 0 ]; then
            echo "Error: Spark2 HistoryServer is already running [$PID]"
            exit $r
        fi

        echo "Starting Spark2 HistoryServer"
        ( sudo -u $HADOOP_USER $SPARK_HOME/sbin/start-history-server.sh 2>&1 > /dev/null  )
        ;;

    'stop')
        check_process
        r=$?
        if [ $r -ne 0 ]; then
            echo "Stopping Spark2 HistoryServer [$PID]"
            ( sudo -u $HADOOP_USER $SPARK_HOME/sbin/stop-history-server.sh 2>&1 > /dev/null )
            r=0
        else
            echo "Spark2 HistoryServer not found.."
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
