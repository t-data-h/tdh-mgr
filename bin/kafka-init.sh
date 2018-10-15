#!/bin/bash
#
#  Init script for Kafka Broker(s)
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

ACTION="$1"
CONFIG="$2"

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

if [ -z "$HADOOP_USER" ]; then
    echo "Error! HADOOP_USER is not set. Aborting..."
    exit 1
fi
if [ -z "$KAFKA_HOME" ]; then
    echo "Error! KAFKA_HOME is not set. Check your hadoop env."
    exit 1
fi

KAFKA_PID="kafka.Kafka"
KAFKA_CFG="config/server.properties"
PID=


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
    PID=$(ps ax | grep java | grep $KAFKA_PID | grep -v grep | awk '{ print $1 }')
}


check_process()
{
    local rt=0

    get_pid

    if [ -n "$PID" ]; then
        check_process_pid $PID
        rt=$?
    fi

    return $rt
}


show_status()
{
    local rt=0

    check_process
    rt=$?
    if [ $rt -ne 0 ]; then
        echo " Kafka Broker          [$PID]"
    else
        echo " Kafka Broker is not running"
    fi

    return $rt
}


# =================
#  MAIN
# =================


rt=0

echo " ------ Kafka -------- "

case "$ACTION" in
    'start')
        check_process
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " Kafka Broker is already running"
            exit $rt
        fi

        if [ -n "$CONFIG" ]; then
            KAFKA_CFG="$CONFIG"
        fi

        echo "Starting Kafka Broker"
        ( sudo -u $HADOOP_USER $KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/$KAFKA_CFG )
        ;;

    'stop')
        check_process
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Stopping Kafka Broker [$PID]"
            ( sudo -u $HADOOP_USER $KAFKA_HOME/bin/kafka-server-stop.sh )
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
