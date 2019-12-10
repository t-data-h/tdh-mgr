#!/bin/bash
#
#  Init script for Hive Services
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

HIVE_VER=$(readlink $HIVE_HOME)

HIVEMETASTORE="MetaStore"
HIVESERVER2="HiveServer2"
METADB="mysqld"

HIVE_LOGDIR="${HADOOP_LOGDIR}/hive"
HIVE_METASTORE_LOG="${HIVE_LOGDIR}/hive-metastore.log"
HIVE_SERVER2_LOG="${HIVE_LOGDIR}/hive-server2.log"

HOST=$(hostname -s)
HIVE_SERVER=$( grep -A1 'hive.metastore.uris' ${HIVE_HOME}/conf/hive-site.xml | \
    grep value | \
    sed  -E 's/.*<value>thrift:\/\/(.*)<\/value>/\1/' | \
    awk -F':' '{ print $1 }' )

# -----------

usage()
{
    echo "$TDH_PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    check_remote_process $HIVE_SERVER $HIVEMETASTORE

    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " Hive Metastore         | \e[32m\e[1m OK \e[0m | [${HIVE_SERVER}:${PID}]"
    else
        echo -e " Hive Metastore         | \e[31m\e[1mDEAD\e[0m | [${HIVE_SERVER}]"
    fi

    check_remote_process $HIVE_SERVER $HIVESERVER2

    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " Hive Server            | \e[32m\e[1m OK \e[0m | [${HIVE_SERVER}:${PID}]"
    else
        echo -e " Hive Server            | \e[31m\e[1mDEAD\e[0m | [${HIVE_SERVER}]"
    fi

    return $rt
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

echo -e " -------- \e[96m$HIVE_VER\e[0m ----------- "

case "$ACTION" in
    'start')
        check_remote_process $HIVE_SERVER $HIVEMETASTORE

        rt=$?
        if [ $rt -eq 0 ]; then
            echo " Hive MetaStore is already running  [${HIVE_SERVER}:${PID}]"
            exit $rt
        fi

        check_remote_process $HIVE_SERVER $HIVESERVER2

        rt=$?
        if [ $rt -eq 0 ]; then
            echo " HiveServer2 is already running [${HIVE_SERVER}:${PID}]"
            exit $rt
        fi

        ( ssh $HIVE_SERVER "mkdir -p $HIVE_LOGDIR" )

        echo "Starting Hive MetaStore on $HIVE_SERVER..."
        ( ssh -n $HIVE_SERVER "nohup $HIVE_HOME/bin/hive --service metastore >$HIVE_METASTORE_LOG 2>&1 &" )

        rt=$?

        echo "Starting HiveServer2 on $HIVE_SERVER..."
        ( ssh -n $HIVE_SERVER "nohup $HIVE_HOME/bin/hive --service hiveserver2 >$HIVE_SERVER2_LOG 2>&1 &" )
        ;;

    'stop')
        check_remote_process $HIVE_SERVER $HIVEMETASTORE

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Hive MetaStore [${HIVE_SERVER}:${PID}]..."
            ( ssh $HIVE_SERVER "kill $PID" )
        else
            echo "Hive Metastore not found..."
        fi

        check_remote_process $HIVE_SERVER $HIVESERVER2

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping HiveServer2 [${HIVE_SERVER}:${PID}]..."
            ( ssh $HIVE_SERVER "kill $PID" )
        else
            echo "Hive Server2 not found..."
        fi
        rt=0
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
