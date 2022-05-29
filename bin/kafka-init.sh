#!/usr/bin/env bash
#
#  Init script for Kafka Broker(s)
#
#  Timothy C. Arland <tcarland@gmail.com>
#

# ----------- preamble
HADOOP_ENV="tdh-env.sh"
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
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'" >&2
    exit 1
fi
# -----------

if [ -z "$KAFKA_HOME" ]; then
    echo "Fatal! KAFKA_HOME is not set. Check your hadoop env." >&2
    exit 1
fi

KAFKA_VER=$(readlink $KAFKA_HOME)
KAFKA_ID="kafka.Kafka"
KAFKA_CFG="config/server.properties"
HOST=$(hostname -s)

# -----------

usage="
$TDH_PNAME {start|stop|status}
  TDH $TDH_VERSION
"


show_status()
{
    local rt=0

    for broker in ${BROKERS}; do
        broker=$( echo $broker | awk -F: '{ print $1 }' )

        check_remote_process "$broker" "$KAFKA_ID"

        rt=$?
        if [ $rt -eq 0 ]; then
            printf " Kafka Broker           | $C_GRN OK $C_NC |  ${broker} [${PID}]\n"
        else
            printf " Kafka Broker           | ${C_RED}DEAD${C_NC} |  ${broker}\n"
        fi
    done

    return $rt
}


# =================
#  MAIN
# =================

ACTION="$1"
CONFIG="$2"
IFS=$','
rt=0

if [ -n "$CONFIG" ]; then
    KAFKA_CFG="$CONFIG"
fi

getBrokers >/dev/null

if [ -z "${BROKERS}" ]; then
    echo "$TDH_PNAME Error getting brokers from host config" >&2
    exit 1
fi

tdh_show_header $KAFKA_VER

case "$ACTION" in
    'start')
        for broker in ${BROKERS}; do
            broker=$( echo $broker | awk -F: '{ print $1 }' )
            check_remote_process "$broker" "$KAFKA_ID"

            rt=$?

            if [ $rt -eq 0 ]; then
                echo "Kafka Broker is already running: ${broker} [${PID}]"
                continue
            fi

            echo "Starting Kafka Broker: '${broker}'"
            ( ssh $broker "${KAFKA_HOME}/bin/kafka-server-start.sh -daemon $KAFKA_HOME/$KAFKA_CFG > /dev/null 2>&1" )

            rt=$?
        done
        ;;

    'stop')
        for broker in ${BROKERS}; do
            broker=$( echo $broker | awk -F: '{ print $1 }' )
            check_remote_process "$broker" "$KAFKA_ID"

            rt=$?
            if [ $rt -eq 0 ]; then
                echo "Stopping Kafka Broker: ${broker} [${PID}]"
                ( ssh $broker "$KAFKA_HOME/bin/kafka-server-stop.sh > /dev/null 2>&1" )
                rt=$?
            else
                echo "  Kafka Broker not found."
                rt=0
            fi
        done
        ;;

    'status'|'info')
        show_status
        rt=$?
        ;;

    'help'|--help|-h) 
        echo "$usage" 
        ;;

    'version'|--version|-V)
        tdh_version
        ;;

    *)
        echo "$usage"
        ;;
esac

exit $rt
