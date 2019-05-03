#!/bin/bash
#
#  Init script for the core hadoop services HDFS and YARN.
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HADOOP_ENV="hadoop-env-user.sh"

NN_PIDFILE="-namenode.pid"
SN_PIDFILE="-secondarynamenode.pid"
DN_PIDFILE="-datanode.pid"
RM_PIDFILE="-resourcemanager.pid"
NM_PIDFILE="-nodemanager.pid"

# source the hadoop-env-user script
if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then
    . $HOME/hadoop/etc/$HADOOP_ENV
fi

if [ -z "$HADOOP_ENV_USER_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi


usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $HADOOP_ENV_USER_VERSION"
}


check_process_pidfile()
{
    local pidf=$(ls /tmp/*-${HADOOP_USER}$1 2> /dev/null)
    local rt=$?

    if [ -n "$pidf" ] && [ -r $pidf ]; then
        PID=$(cat ${pidf})
        check_process_pid $PID
        rt=$?
    fi

    return $rt
}


show_status()
{
    local rt=0

    hostip_is_valid
    rt=$?
    if [ $rt -ne 0 ]; then
        echo "    Unable to find a network interface. "
        echo "    Please verify networking is configured properly."
        return $rt
    fi

    echo " ------ Hadoop ------- "
    check_process_pidfile $NN_PIDFILE
    rt=$?
    if [ $rt -ne 0 ]; then
        echo " HDFS Namenode         [$PID]"
    else
        echo " HDFS Primary Namenode is not running"
    fi

    check_process_pidfile $SN_PIDFILE
    rt=$?
    if [ $rt -ne 0 ]; then
        echo " HDFS Sec.NameNode     [$PID]"
    else
        echo " HDFS Secondary Namenode is not running"
    fi

    check_process_pidfile $DN_PIDFILE
    rt=$?
    if [ $rt -ne 0 ]; then
        echo " HDFS Datanode         [$PID]"
    else
        echo " HDFS Datanode is not running"
    fi

    check_process_pidfile $RM_PIDFILE
    rt=$?
    if [ $rt -ne 0 ]; then
        echo " YARN ResourceManager  [$PID]"
    else
        echo " YARN ResourceManager is not running"
    fi

    check_process_pidfile $NM_PIDFILE
    rt=$?
    if [ $rt -ne 0 ]; then
        echo " YARN NodeManager      [$PID]"
    else
        echo " YARN NodeManager is not running"
    fi

    return $rt
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0


case "$ACTION" in
    'start')
        check_process_pidfile $RM_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " YARN Resource Manager is already running  [$PID]"
            exit $rt
        fi

        check_process_pidfile $NN_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " HDFS Namenode is already running  [$PID]"
            exit $rt
        fi
#
        hostip_is_valid
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " Error! Unable to find a network interface. Please verify networking is configured properly."
            exit $rt
        fi

        echo " ------ Hadoop ------- "
        echo "Starting HDFS..."
        ( sudo -u $HADOOP_USER $HADOOP_HDFS_HOME/sbin/start-dfs.sh 2>&1 > /dev/null )
        echo "Starting YARN..."
        ( sudo -u $HADOOP_USER $YARN_HOME/sbin/start-yarn.sh 2>&1 > /dev/null )
        ;;

    'stop')
        echo " ------ Hadoop ------- "
        check_process_pidfile $RM_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Stopping YARN [$PID]..."
            ( sudo -u $HADOOP_USER $YARN_HOME/sbin/stop-yarn.sh 2>&1 > /dev/null )
        else
            echo " YARN ResourceManager not running or not found."
        fi

        check_process_pidfile $NM_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            ( sudo -u $HADOOP_USER $YARN_HOME/sbin/stop-yarn.sh 2>&1 > /dev/null )
        fi

        check_process_pidfile $NN_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Stopping HDFS [$PID]..."
            ( sudo -u $HADOOP_USER $HADOOP_HDFS_HOME/sbin/stop-dfs.sh 2>&1 > /dev/null )
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
