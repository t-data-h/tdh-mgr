#!/bin/bash
#
#  Init script for Spark Standalone
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

SPARK_PID="org.apache.spark.deploy.master.Master"

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
    local rt=0

    check_process $SPARK_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " Spark Standalone        [$PID]"
    else
        echo -e " Spark Standalone Server not running"
    fi

    return $rt
}


ACTION="$1"
rt=0

echo " ------ $SPARK_VER ------- "

case "$ACTION" in
    'start')
        check_process $SPARK_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Error: Spark Master is already running [$PID]"
            exit $rt
        fi

        echo "Starting Spark Standalone..."
        ( sudo -u $HADOOP_USER $SPARK_HOME/sbin/start-all.sh )
        ;;

    'stop')
        check_process $SPARK_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Spark Standalone..."
            ( sudo -u $HADOOP_USER $SPARK_HOME/sbin/stop-all.sh )
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
