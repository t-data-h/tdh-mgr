#!/bin/bash
#
#  Init script for Kafka Broker(s)
#
#  Timothy C. Arland <tcarland@gmail.com>
#

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"
HADOOP_ENV_PATH="/opt/TDH/etc"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
    HADOOP_ENV_PATH="./etc"
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
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

if [ -z "$KAFKA_HOME" ]; then
    echo "Error! KAFKA_HOME is not set. Check your hadoop env."
    exit 1
fi

KAFKA_VER=$(readlink $KAFKA_HOME)

KAFKA_ID="kafka.Kafka"
KAFKA_CFG="config/server.properties"

HOST=$(hostname -s)
BROKERSFILE="${KAFKA_HOME}/config/brokers"

# -----------

usage()
{
    echo "$TDH_PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    local rt=0

    for broker in ${BROKERS}; do
        broker=$( echo $broker | awk -F: '{ print $1 }' )
        #broker=${broker%% *}

        check_remote_process $broker $KAFKA_ID
        rt=$?

        if [ $rt -eq 0 ]; then
            echo -e " Kafka Broker           | $C_GRN OK $C_NC | [${broker}:${PID}]"
        else
            echo -e " Kafka Broker           | ${C_RED}DEAD${C_NC} | [${broker}]"
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

BROKERS=$(getBrokers $brokersfile)

if [ -z "${BROKERS}" ]; then
    echo "Error getting brokers from host config: '${BROKERSFILE}'"
    exit 1
fi

IFS=$','

echo -e " ------ ${C_CYN}${KAFKA_VER}${C_NC} ------- "

case "$ACTION" in
    'start')
        for broker in ${BROKERS}; do
            broker=$( echo $broker | awk -F: '{ print $1 }' )
            check_remote_process $broker $KAFKA_ID

            rt=$?

            if [ $rt -eq 0 ]; then
                echo " Kafka Broker [${broker}:${PID}] is already running"
                exit $rt
            fi

            echo "Starting Kafka Broker.. [${broker}]"
            ( ssh $broker "${KAFKA_HOME}/bin/kafka-server-start.sh -daemon $KAFKA_HOME/$KAFKA_CFG > /dev/null 2>&1" )

            rt=$?
        done
        ;;

    'stop')
        for broker in ${BROKERS}; do
            broker=$( echo $broker | awk -F: '{ print $1 }' )
            check_remote_process $broker $KAFKA_ID

            rt=$?
            if [ $rt -eq 0 ]; then
                echo "Stopping Kafka Broker [${broker}:${PID}]"
                ( ssh $broker "$KAFKA_HOME/bin/kafka-server-stop.sh > /dev/null 2>&1" )
                rt=$?
            else
                echo "Kafka Broker not found."
                rt=0
            fi
        done
        ;;

    'status'|'info')
        show_status
        rt=$?
        ;;

    --version|-V)
        version
        ;;
    *)
        usage
        ;;
esac

exit $rt
