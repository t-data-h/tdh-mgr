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

# -----------

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi

if [ -z "$KAFKA_HOME" ]; then
    echo "Error! KAFKA_HOME is not set. Check your hadoop env."
    exit 1
fi

KAFKA_VER=$(readlink $KAFKA_HOME)
HOST=$(hostname -s)
BROKERS="${KAFKA_HOME}/config/brokers"

# -----------

usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    local rt=0

    for broker in $( cat ${KAFKA_HOME}/config/brokers ); do
        check_remote_process $broker $KAFKA_ID
        rt=$?

        if [ $rt -eq 0 ]; then
            echo -e "   Kafka Broker         | \e[32m\e[1m OK \e[0m | [${broker}:${PID}]"
        else
            echo -e "   Kafka Broker         | \e[31m\e[1mDEAD\e[0m | [${broker}]"
        fi
    done

    return $rt
}


# =================
#  MAIN
# =================


ACTION="$1"
CONFIG="$2"
rt=0

if [ -n "$CONFIG" ]; then
    KAFKA_CFG="$CONFIG"
fi

if ! [ -e ${BROKERS} ]; then
    echo "Error locating broker host config: '${BROKERS}'"
    exit 1
fi

echo -e " ------ \e[96m$KAFKA_VER\e[0m ------- "

case "$ACTION" in
    'start')
        for broker in $( cat ${BROKERS} ); do
            check_remote_process $broker $KAFKA_ID
        
            rt=$?
        
            if [ $rt -eq 0 ]; then
                echo " Kafka Broker [${broker}:${PID}] is already running"
                exit $rt
            fi
            
            echo "Starting Kafka Broker  [${broker}]"
            #( sudo -u $HADOOP_USER $KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/$KAFKA_CFG 2>&1 > /dev/null )
            ( ssh $broker "${KAFKA_HOME}/bin/kafka-server-start.sh -daemon $KAFKA_HOME/$KAFKA_CFG 2>&1 > /dev/null" )

            rt=$?
        done
        ;;

    'stop')
        for broker in $( cat ${BROKERS} ); do
            check_remote_process $broker $KAFKA_ID
            
            rt=$?
            if [ $rt -eq 0 ]; then
                echo "Stopping Kafka Broker [${broker}:${PID}]"
                #( sudo -u $HADOOP_USER $KAFKA_HOME/bin/kafka-server-stop.sh 2>&1 > /dev/null )
                ( ssh $broker "$KAFKA_HOME/bin/kafka-server-stop.sh 2>&1 > /dev/null" )
                rt=0
            else
                echo "Kafka Broker not found."
            fi
        done
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
