#!/bin/bash
#
#  Init script for Hive
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HIVEMETASTORE="MetaStore"
HIVESERVER2="HiveServer2"
METADB="mysqld"

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

# -----------

HIVE_VER=$(readlink $HIVE_HOME)
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
    echo "$PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    check_remote_process $HIVE_SERVER $HIVEMETASTORE
    
    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e "   Hive Metastore       | \e[32m\e[1m OK \e[0m | [${HIVE_SERVER}:${PID}]"
    else
        echo -e "   Hive Metastore       | \e[31m\e[1mDEAD\e[0m | [${HIVE_SERVER}]"
    fi

    check_remote_process $HIVE_SERVER $HIVESERVER2
    
    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e "   Hive Server          | \e[32m\e[1m OK \e[0m | [${HIVE_SERVER}:${PID}]"
    else
        echo -e "   Hive Server          | \e[31m\e[1mDEAD\e[0m | [${HIVE_SERVER}]"
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

        echo "Starting Hive MetaStore..."
        #( sudo -u $HADOOP_USER nohup $HIVE_HOME/bin/hive --service metastore 2>&1 > $HIVE_METASTORE_LOG & )
        ( ssh $HIVE_SERVER "nohup $HIVE_HOME/bin/hive --service metastore 2>&1 > $HIVE_METASTORE_LOG &" )

        rt=$?

        echo "Starting HiveServer2..."
        #( sudo -u $HADOOP_USER nohup $HIVE_HOME/bin/hive --service hiveserver2 2>&1 > $HIVE_SERVER2_LOG & )
        ( ssh $HIVE_SERVER "nohup $HIVE_HOME/bin/hive --service hiveserver2 2>&1 > $HIVE_SERVER2_LOG &" )
        ;;

    'stop')
        check_remote_process $HIVE_SERVER $HIVEMETASTORE
        
        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Hive MetaStore [${HIVE_SERVER}:${PID}]..."
            #( sudo -u $HADOOP_USER kill $PID )
            ( ssh $HIVE_SERVER "kill $PID" )
        else
            echo "Hive Metastore process not found..."
        fi

        check_remote_process $HIVE_SERVER $HIVESERVER2
        
        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping HiveServer2 [${HIVE_SERVER}:${PID}]..."
            #( sudo -u $HADOOP_USER kill $PID )
            ( ssh $HIVE_SERVER "kill $PID" )
        else
            echo "HiveServer2 process not found..."
        fi
        rt=0
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
