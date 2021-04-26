#!/usr/bin/env bash
#
#  Init script for Hive Services
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
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
# -----------

HOST=$(hostname -s)
HIVE_VER=$(readlink $HIVE_HOME)
HIVEMETASTORE="MetaStore"
HIVESERVER2="HiveServer2"
METADB="mysqld"
HIVE_LOG_DIR="${HADOOP_LOG_DIR}/hive"
HIVE_METASTORE_LOG="${HIVE_LOG_DIR}/hive-metastore.log"
HIVE_SERVER2_LOG="${HIVE_LOG_DIR}/hive-server2.log"
HIVE_SERVER=$( grep -A1 'hive.metastore.uris' ${HIVE_HOME}/conf/hive-site.xml | \
    grep value 2>/dev/null | \
    sed  -E 's/.*<value>thrift:\/\/(.*)<\/value>/\1/' | \
    awk -F':' '{ print $1 }' )

# -------------------------------------------

usage="
$TDH_PNAME {start|stop|status}
  TDH $TDH_VERSION
"


show_status()
{
    check_remote_process $HIVE_SERVER $HIVEMETASTORE

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " Hive Metastore         | $C_GRN OK $C_NC |  ${HIVE_SERVER} [${PID}]\n"
    else
        printf " Hive Metastore         | ${C_RED}DEAD$C_NC |  ${HIVE_SERVER}\n"
    fi

    check_remote_process $HIVE_SERVER $HIVESERVER2

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " Hive Server            | $C_GRN OK $C_NC |  ${HIVE_SERVER} [${PID}]\n"
    else
        printf " Hive Server            | ${C_RED}DEAD$C_NC |  ${HIVE_SERVER}\n"
    fi

    return $rt
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0
hs=0

tdh_show_header $HIVE_VER

case "$ACTION" in
    'start')
        check_remote_process $HIVE_SERVER $HIVEMETASTORE

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Hive MetaStore is already running: ${HIVE_SERVER} [${PID}]"
        fi

        check_remote_process $HIVE_SERVER $HIVESERVER2

        hs=$?
        if [ $hs -eq 0 ]; then
            echo "Hive Server2 is already running:   ${HIVE_SERVER} [${PID}]"
        fi

        ( ssh $HIVE_SERVER "mkdir -p $HIVE_LOG_DIR" )

        if [ $rt -gt 0 ]; then
            echo "Starting HiveMetaStore: '$HIVE_SERVER'"
            ( ssh -n $HIVE_SERVER "nohup $HIVE_HOME/bin/hive --service metastore > $HIVE_METASTORE_LOG 2>&1 &" )
            rt=$?
        fi

        if [ $hs -gt 0 ]; then 
            echo "Starting HiveServer2: '$HIVE_SERVER'"
            ( ssh -n $HIVE_SERVER "nohup $HIVE_HOME/bin/hive --service hiveserver2 > $HIVE_SERVER2_LOG 2>&1 &" )
        fi
        ;;

    'stop')
        check_remote_process $HIVE_SERVER $HIVEMETASTORE

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Hive MetaStore: ${HIVE_SERVER} [${PID}]"
            ( ssh $HIVE_SERVER "kill $PID" )
        else
            echo "Hive Metastore not found."
        fi

        check_remote_process $HIVE_SERVER $HIVESERVER2

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Hive Server2:   ${HIVE_SERVER} [${PID}]"
            ( ssh $HIVE_SERVER "kill $PID" )
        else
            echo "Hive Server not found."
        fi
        rt=0
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
