#!/bin/bash
#
#  Init script for Zookeeper
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

if [ -z "$ZOOKEEPER_HOME" ]; then
    echo "Error! ZOOKEEPER_HOME is not set. Check your hadoop env."
    exit 1
fi

HOST=$(hostname -s)
ZK_VER=$(readlink $ZOOKEEPER_HOME)
ZK_ID="server.quorum"

# -----------

usage()
{
    echo "$TDH_PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    local rt=0

    for zk in ${ZKS}; do
        zk=$( echo $zk | awk -F: '{ print $1 }' )

        check_remote_process $zk $ZK_ID
        rt=$?

        if [ $rt -eq 0 ]; then
            echo -e " Zookeeper              | $C_GRN OK $C_NC | [${zk}:${PID}]"
        else
            echo -e " Zookeeper              | ${C_RED}DEAD$C_NC | [${zk}]"
        fi
    done

    return $rt
}


# =================
#  MAIN
# =================

ACTION="$1"
IFS=$','
rt=0

getZookeepers

if [ -z "$ZKS" ]; then
    echo "Error locating Zookeeper host config: '${ZK_CONFIG}'"
    exit 1
fi

echo -e " ------ ${C_CYN}${ZK_VER}${C_NC} ------- "

case "$ACTION" in
    'start')
        for zk in ${ZKS}; do
            zk=$( echo $zk | awk -F: '{ print $1 }' )

            check_remote_process $zk $ZK_ID
            rt=$?

            if [ $rt -eq 0 ]; then
                echo " Zookeeper [${zk}:${PID}] is already running"
                exit $rt
            fi

            echo "Starting Zookeeper..  [${zk}]"
            ( ssh $zk "${ZOOKEEPER_HOME}/bin/zkServer.sh start > /dev/null 2>&1" )

            rt=$?
        done
        ;;

    'stop')
        for zk in ${ZKS}; do
            zk=$( echo $zk | awk -F: '{ print $1 }' )

            check_remote_process $zk $ZK_ID
            rt=$?

            if [ $rt -eq 0 ]; then
                echo "Stopping Zookeeper.. [${zk}:${PID}]"
                ( ssh $zk "$ZOOKEEPER_HOME/bin/zkServer.sh stop > /dev/null 2>&1" )
                rt=$?
            else
                echo "Zookeeper not found."
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
