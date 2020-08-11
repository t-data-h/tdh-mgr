#!/usr/bin/env bash
#
#  Init script for Spark Standalone
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
SPARK_PID="org.apache.spark.deploy.master.Master"

# -----------


usage()
{
    echo "$TDH_PNAME {start|stop|status}"
    echo "  TDH $TDH_VERSION"
}


show_status()
{
    local rt=0

    check_process $SPARK_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " Spark Standalone       | $C_GRN OK $C_NC | [$PID]\n"
    else
        printf " Spark Standalone       | ${C_RED}DEAD${C_NC} |\n"
    fi

    return $rt
}


ACTION="$1"
rt=0

printf " ------ ${C_CYN}${SPARK_VER}${C_NC} ------- \n"

case "$ACTION" in
    'start')
        check_process $SPARK_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Error: Spark Master is already running [$PID]"
            exit $rt
        fi

        echo "Starting Spark Standalone..."
        ( sudo -u $HADOOP_USER $SPARK_HOME/sbin/start-all.sh > /dev/null 2>&1 )
        ;;

    'stop')
        check_process $SPARK_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Spark Standalone..."
            ( sudo -u $HADOOP_USER $SPARK_HOME/sbin/stop-all.sh > /dev/null 2>&1 )
        else
            echo " Spark Master not running.."
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
