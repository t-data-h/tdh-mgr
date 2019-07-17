#!/bin/bash
#
#  Init script for the core hadoop services HDFS and YARN.
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

NN_PIDFILE="-namenode.pid"
SN_PIDFILE="-secondarynamenode.pid"
DN_PIDFILE="-datanode.pid"
RM_PIDFILE="-resourcemanager.pid"
NM_PIDFILE="-nodemanager.pid"

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

( echo $NN_HOST | grep $HOST )
IS_NN=$?
( echo $SN_HOST | grep $HOST )
IS_SN=$?
( echo $RM_HOST | grep $HOST )
IS_RM=$?

# -----------


usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
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
        echo "    Unable to locate the host network interface. "
        echo "    Please verify networking is configured properly."
        echo ""
        return $rt
    fi

    echo " ------ $HADOOP_VER --------- "

    if [ $IS_NN -eq 0 ]; then
        check_process_pidfile $NN_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " HDFS Namenode         [$PID]"
        else
            echo " HDFS Primary Namenode is not running"
        fi
    else
        echo " HDFS Namenode         [$NN_HOST]"
    fi

    if [ $IS_SN -eq 0 ]; then
        check_process_pidfile $SN_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " HDFS Sec.NameNode     [$PID]"
        else
            echo " HDFS Secondary Namenode is not running"
        fi
    else
        echo " HDFS Sec.Namenode     [$SN_HOST]"
    fi

    if [ $IS_RM -eq 0 ]; then
        check_process_pidfile $RM_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " YARN ResourceManager  [$PID]"
        else
            echo " YARN ResourceManager is not running"
        fi
    else
        echo " YARN ResourceManager  [$RM_HOST]"
    fi

    set -f
    IFS=$'\n'

    for dn in $( cat ${HADOOP_HOME}/etc/hadoop/slaves ); do
        ( echo $dn | grep $HOST )
        if [ $? -eq 0 ] || [ "$dn" == "localhost" ]; then
            check_process_pidfile $DN_PIDFILE
            rt=$?
            if [ $rt -ne 0 ]; then
                echo " HDFS Datanode         [$PID]"
            else
                echo " HDFS Datanode is not running"
            fi

            check_process_pidfile $NM_PIDFILE
            rt=$?
            if [ $rt -ne 0 ]; then
                echo " YARN NodeManager      [$PID]"
            else
                echo " YARN NodeManager is not running"
            fi
        else
                echo " HDFS Datanode         [$dn]"
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

        echo " ------ $HADOOP_VER --------- "
        echo "Starting HDFS..."
        ( sudo -u $HADOOP_USER $HADOOP_HDFS_HOME/sbin/start-dfs.sh 2>&1 > /dev/null )
        echo "Starting YARN..."
        ( sudo -u $HADOOP_USER $HADOOP_YARN_HOME/sbin/start-yarn.sh 2>&1 > /dev/null )
        ;;

    'stop')
        echo " ------ $HADOOP_VER --------- "
        check_process_pidfile $RM_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Stopping YARN [$PID]..."
            ( sudo -u $HADOOP_USER $HADOOP_YARN_HOME/sbin/stop-yarn.sh 2>&1 > /dev/null )
        else
            echo " YARN ResourceManager not running or not found."
        fi

        check_process_pidfile $NM_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            ( sudo -u $HADOOP_USER $HADOOP_YARN_HOME/sbin/stop-yarn.sh 2>&1 > /dev/null )
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
