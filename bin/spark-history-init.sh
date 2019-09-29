#!/bin/bash
#
#   Spark History Server init
#

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

# -----------

SPARK_VER=$(readlink $SPARK_HOME)
SPARK_ID="org.apache.spark.deploy.history.HistoryServer"

HOST=$(hostname -s)
SHS_HOST=$( grep 'spark.yarn.historyServer.address' ${SPARK_HOME}/conf/spark-defaults.conf | \
  awk -F'=' '{ print $2 }' | \
  sed -E 's/http:\/\/(.*):.*/\1/' )

# -----------

usage()
{
    echo "$TDH_PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    local rt=0

    check_remote_process $SHS_HOST $SPARK_ID
    rt=$?
    
    if [ $rt -eq 0 ]; then
        echo -e "  Spark2 HistoryServer  | \e[32m\e[1m OK \e[0m | [${SHS_HOST}:${PID}]"
    else
        echo -e "  Spark2 HistoryServer  | \e[31m\e[1mDEAD\e[0m | [${SHS_HOST}]"
    fi

    return $rt
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

echo -e " -------- \e[96m$SPARK_VER\e[0m ---------- "

case "$ACTION" in
    'start')
        check_remote_process $SHS_HOST $SPARK_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Error: Spark2 HistoryServer is already running [${SHS_HOST}:${PID}]"
            exit $rt
        fi

        echo "Starting Spark2 HistoryServer"
        ( ssh $SHS_HOST "$SPARK_HOME/sbin/start-history-server.sh 2>&1 > /dev/null" )
        
        rt=$?
        ;;

    'stop')
        check_remote_process $SHS_HOST $SPARK_ID
        
        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Spark2 HistoryServer [$PID]"
            ( ssh $SHS_HOST "$SPARK_HOME/sbin/stop-history-server.sh 2>&1 > /dev/null" )
        else
            echo "Spark2 HistoryServer not found.."
        fi
        rt=0
        ;;

    'status'|'info')
        show_status
        ;;

    --version|-V)
        version
        ;;
    *)
        usage
        ;;
esac

exit $rt
