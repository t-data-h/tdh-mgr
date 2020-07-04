#!/usr/bin/env bash
#
#  Spark History Server init
#
#  Timothy C. Arland <tcarland@gmail.com>
#

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"
HADOOP_ENV_PATH="/opt/TDH/etc"

if [ -r "./etc/${HADOOP_ENV}" ]; then
    . ./etc/$HADOOP_ENV
    HADOOP_ENV_PATH="./etc"
elif [ -r "/etc/hadoop/${HADOOP_ENV}" ]; then
    . /etc/hadoop/$HADOOP_ENV
    HADOOP_ENV_PATH="/etc/hadoop"
elif [ -r "${HADOOP_ENV_PATH}/${HADOOP_ENV}" ]; then
    . $HADOOP_ENV_PATH/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
# -----------

if [ -z "$SPARK_USER" ]; then
    SPARK_USER="$HADOOP_USER"
fi

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
        printf " Spark2 HistoryServer   | $C_GRN OK $C_NC | [${SHS_HOST}:${PID}]\n"
    else
        printf " Spark2 HistoryServer   | ${C_RED}DEAD$C_NC | [${SHS_HOST}]\n"
    fi

    return $rt
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

printf " -------- ${C_CYN}${SPARK_VER}${C_NC} ---------- \n"

case "$ACTION" in
    'start')
        check_remote_process $SHS_HOST $SPARK_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Error: Spark2 HistoryServer is already running [${SHS_HOST}:${PID}]"
            exit $rt
        fi

        echo "Starting Spark2 HistoryServer [$SHS_HOST]"
        ( ssh $SHS_HOST "$SPARK_HOME/sbin/start-history-server.sh > /dev/null 2>&1" )

        rt=$?
        ;;

    'stop')
        check_remote_process $SHS_HOST $SPARK_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Spark2 HistoryServer [$PID]"
            ( ssh $SHS_HOST "$SPARK_HOME/sbin/stop-history-server.sh > /dev/null 2>&1" )
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
