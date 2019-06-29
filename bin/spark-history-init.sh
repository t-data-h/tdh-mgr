#!/bin/bash
#
##  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

SPARK_ID="org.apache.spark.deploy.history.HistoryServer"

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

if [ -z "$SPARK_USER" ]; then
    SPARK_USER="$HADOOP_USER"
fi

SPARK_VER=$(readlink $SPARK_HOME)
# -----------


usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    local ret=0

    check_process "$SPARK_ID"
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

ACTION="$1"
rt=0

echo " ------ $SPARK_VER ---------- "

case "$ACTION" in
    'start')
        check_process "$SPARK_ID"
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Error: Spark2 HistoryServer is already running [$PID]"
            exit $rt
        fi

        echo "Starting Spark2 HistoryServer"
        ( sudo -u $HADOOP_USER $SPARK_HOME/sbin/start-history-server.sh 2>&1 > /dev/null  )
        ;;

    'stop')
        check_process "$SPARK_ID"
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Stopping Spark2 HistoryServer [$PID]"
            ( sudo -u $HADOOP_USER $SPARK_HOME/sbin/stop-history-server.sh 2>&1 > /dev/null )
        else
            echo "Spark2 HistoryServer not found.."
        fi
        rt=0
        ;;

    'status'|'info')
        show_status
        ;;
    *)
        usage
        ;;
esac

exit $rt
