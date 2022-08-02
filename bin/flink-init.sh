#!/usr/bin/env bash
#
#  Init script for Flink
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

if [ -z "$FLINK_HOME" ]; then
    echo "Fatal! FLINK_HOME is not set. Check your hadoop env." >&2
    exit 1
fi

HOST=$(hostname -s)
FLINK_VER=$(readlink $FLINK_HOME)
FLINK_ID="flink"

# -----------

usage="
$TDH_PNAME {start|stop|status}
  TDH $TDH_VERSION
"


show_status()
{
    local rt=0

    for zk in ${ZKS}; do
        zk=$( echo $zk | awk -F: '{ print $1 }' )

        check_remote_process "$zk" "$ZK_ID"

        rt=$?
        if [ $rt -eq 0 ]; then
            printf " Flink              | $C_GRN OK $C_NC |  ${zk} [${PID}] \n"
        else
            printf " Flink              | ${C_RED}DEAD$C_NC |  ${zk} \n"
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

tdh_show_header "$FLINK_VER"

case "$ACTION" in
    'start')
        for zk in ${ZKS}; do
            zk=$( echo $zk | awk -F: '{ print $1 }' )

            check_remote_process "$zk" "$ZK_ID"
            rt=$?

            if [ $rt -eq 0 ]; then
                echo "Zookeeper is already running: ${zk} [${PID}]"
                exit $rt
            fi

            echo "Starting Zookeeper: '${zk}'"
            ( ssh $zk "${ZOOKEEPER_HOME}/bin/zkServer.sh start > /dev/null 2>&1" )
            rt=$?
        done
        sleep 5
        ;;

    'stop')
        for zk in ${ZKS}; do
            zk=$( echo $zk | awk -F: '{ print $1 }' )

            check_remote_process "$zk" "$ZK_ID"
            rt=$?

            if [ $rt -eq 0 ]; then
                echo "Stopping Zookeeper: ${zk} [${PID}]"
                ( ssh $zk "$ZOOKEEPER_HOME/bin/zkServer.sh stop > /dev/null 2>&1" )
                rt=$?
            else
                echo "$TDH_PNAME Error, Zookeeper not found."
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
