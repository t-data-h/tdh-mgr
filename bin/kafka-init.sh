#!/bin/bash
#
#  Init script for Kafka Broker(s)
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

KAFKA_ID="kafka.Kafka"
KAFKA_CFG="config/server.properties"

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

if [ -z "$KAFKA_HOME" ]; then
    echo "Error! KAFKA_HOME is not set. Check your hadoop env."
    exit 1
fi

KAFKA_VER=$(readlink $KAFKA_HOME)
# -----------


usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    local rt=0

    check_process "$KAFKA_ID"
    rt=$?

    if [ $rt -eq 0 ]; then
        echo " Kafka Broker          [$PID]"
    else
        echo " Kafka Broker is not running"
    fi

    return $rt
}


# =================
#  MAIN
# =================


ACTION="$1"
CONFIG="$2"
rt=0

echo " ----- $KAFKA_VER ------ "

case "$ACTION" in
    'start')
        check_process $KAFKA_ID
        rt=$?
        if [ $rt -eq 0 ]; then
            echo " Kafka Broker is already running"
            exit $rt
        fi

        if [ -n "$CONFIG" ]; then
            KAFKA_CFG="$CONFIG"
        fi

        echo "Starting Kafka Broker..."
        ( sudo -u $HADOOP_USER $KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/$KAFKA_CFG 2>&1 > /dev/null )
        ;;

    'stop')
        check_process $KAFKA_ID
        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Kafka Broker [$PID]"
            ( sudo -u $HADOOP_USER $KAFKA_HOME/bin/kafka-server-stop.sh 2>&1 > /dev/null )
            rt=0
        else
            echo "Kafka Broker not found."
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
