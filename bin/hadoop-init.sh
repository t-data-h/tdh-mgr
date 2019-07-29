#!/bin/bash
#
#  Init script for the core hadoop services HDFS and YARN.
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

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

HADOOP_VER=$(readlink $HADOOP_HOME)

NN_ID="namenode.NameNode"
SN_ID="namenode.SecondaryNameNode"
RM_ID="resourcemanager.ResourceManager"
DN_ID="datanode.DataNode"
NM_ID="nodemanager.NodeManager"

HOST=$( hostname -s )
NN_HOST=$( grep -A1 'dfs.namenode.http-address' ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml | \
  grep value | \
  sed -E 's/.*<value>(.*)<\/value>/\1/' | \
  awk -F':' '{ print $1 }' )
SN_HOST=$( grep -A1 secondary ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml | \
  grep value | \
  sed -E 's/.*<value>(.*)<\/value>/\1/' | \
  awk -F':' '{ print $1 }' )
RM_HOST=$( grep -A1 'yarn.resourcemanager.address' ${HADOOP_HOME}/etc/hadoop/yarn-site.xml | \
  grep value | \
  sed -E 's/.*<value>(.*)<\/value>/\1/' | \
  awk -F':' '{ print $1 }' )

( echo $NN_HOST | grep $HOST 2>&1 > /dev/null )
IS_NN=$?
( echo $SN_HOST | grep $HOST 2>&1 > /dev/null )
IS_SN=$?
( echo $RM_HOST | grep $HOST 2>&1 > /dev/null )
IS_RM=$?

# -----------


usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    local rt=0

    hostip_is_valid
    rt=$?
    if [ $rt -ne 0 ]; then
        echo "    Unable to locate the host network interface. "
        echo "    Please verify networking is configured properly."
        echo ""
        return 3
    fi

    echo -e " -------- \e[96m$HADOOP_VER\e[0m --------- "

    # HDFS Primary Namenode
    #
    if [ $IS_NN -eq 0 ]; then
        check_process $NN_ID
    else
        check_remote_process $NN_HOST $NN_ID
    fi
    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " HDFS Namenode (pri)    | \e[32m\e[1m OK \e[0m | [${NN_HOST}:${PID}]"
    else
        echo -e " HDFS Namenode (pri)    | \e[31m\e[1mDEAD\e[0m | [$NN_HOST]"
    fi

    # HDFS Secondary Namenode
    #
    if [ $IS_SN -eq 0 ]; then
        check_process $SN_ID
    else
        check_remote_process $SN_HOST $SN_ID
    fi
    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " HDFS NameNode (sec)    | \e[32m\e[1m OK \e[0m | [${SN_HOST}:${PID}]"
    else
        echo -e " HDFS Namenode (sec)    | \e[31m\e[1mDEAD\e[0m | [${SN_HOST}]"
    fi

    # YARN ResourceManager
    #
    if [ $IS_RM -eq 0 ]; then
        check_process $RM_ID
    else
        check_remote_process $RM_HOST $RM_ID
    fi
    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " YARN ResourceManager   | \e[32m\e[1m OK \e[0m | [${RM_HOST}:${PID}]"
    else
        echo -e " YARN ResourceManager   | \e[31m\e[1mDEAD\e[0m | [${RM_HOST}]"
    fi
    
    set -f
    IFS=$'\n'

    nodes="${HADOOP_HOME}/etc/hadoop/workers"
    if ! [ -e $nodes ]; then
        nodes="${HADOOP_HOME}/etc/hadoop/slaves"
    fi

    for dn in $( cat ${nodes} ); do
        echo -e "    ------------        |------|"

        check_remote_process $dn $DN_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo -e "    Datanode            | \e[32m\e[1m OK \e[0m | [${dn}:${PID}]"
        else
            echo -e "    Datanode            | \e[31m\e[1mDEAD\e[0m | [${dn}]"
        fi

        check_remote_process $dn $NM_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo -e "    NodeManager         | \e[32m\e[1m OK \e[0m | [${dn}:${PID}]"
        else
            echo -e "    NodeManager         | \e[31m\e[1mDEAD\e[0m | [$dn]"
        fi
    done

    return $rt
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0


case "$ACTION" in
    'start')
        if [ $IS_RM -eq 0 ]; then
            check_process $RM_ID
            rt=$?
            if [ $rt -eq 0 ]; then
                echo " YARN Resource Manager is already running  [$PID]"
                exit $rt
            fi
        fi

        if [ $IS_NN -eq 0 ]; then 
            check_process $NN_ID
            rt=$?
            if [ $rt -eq 0 ]; then
                echo " HDFS Namenode is already running  [$PID]"
                exit $rt
            fi
        fi

        hostip_is_valid
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " Error! Unable to find a network interface. Please verify networking is configured properly."
            exit $rt
        fi

        echo -e " -------- \e[96m$HADOOP_VER\e[0m --------- "
        echo "Starting HDFS..."
        ( sudo -u $HADOOP_USER $HADOOP_HDFS_HOME/sbin/start-dfs.sh 2>&1 > /dev/null )
        echo "Starting YARN..."
        ( sudo -u $HADOOP_USER $HADOOP_YARN_HOME/sbin/start-yarn.sh 2>&1 > /dev/null )
        ;;

    'stop')
        echo -e " -------- \e[96m$HADOOP_VER\e[0m --------- "
        echo "Stopping YARN [${RM_HOST}:${PID}]..."
        ( sudo -u $HADOOP_USER $HADOOP_YARN_HOME/sbin/stop-yarn.sh 2>&1 > /dev/null )

        echo "Stopping HDFS [${NN_HOST}:${PID}]..."
        ( sudo -u $HADOOP_USER $HADOOP_HDFS_HOME/sbin/stop-dfs.sh 2>&1 > /dev/null )
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
