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
PID=

# source the hadoop-env-user script
if [ -z "$HADOOP_ENV_USER" ]; then
    if [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then
        . $HOME/hadoop/etc/$HADOOP_ENV
    elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
        . /etc/hadoop/$HADOOP_ENV
    elif [ -r "./etc/$HADOOP_ENV" ]; then
        . ./etc/$HADOOP_ENV
    fi
fi


usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $HADOOP_ENV_USER_VERSION"
}


#  Validates that our configured hostname as provided by `hostname -f`
#  locally resolves to an interface other than the loopback
hostip_is_valid()
{
    local hostid=$(hostname -s)
    local hostip=$(hostname -i)
    local fqdn=$(hostname -f)
    local iface=
    local ip=
    local rt=1

    echo ""
    echo "$fqdn"
    echo -n  "[$hostid] : $hostip"

    if [ "$hostip" == "127.0.0.1" ]; then
        echo "   <lo> "
        echo "  WARNING! Hostname is set to localhost, aborting.."
        return $rt
    fi

    IFS=$'\n'

    #for line in `ifconfig | grep inet`; do ip=$( echo $line | awk '{ print $2 }' )
    for line in `ip addr list | grep "inet "`
    do
        IFS=' '
        iface=$(echo $line | awk -F' ' '{ print $NF }')
        ip=$(echo $line | awk '{ print $2 }' | awk -F'/' '{ print $1 }')

        if [ "$ip" == "$hostip" ]; then
            rt=0
            break
        fi
    done

    if [ $rt -eq 0 ]; then
        echo " : <$iface>"
    fi
    echo ""

    return $rt
}


check_process_pid()
{
    local pid=$1
    PID=0

    if ps ax | grep $pid | grep -v grep 1> /dev/null 2> /dev/null ; then
        PID=$pid
        return 1
    fi

    return 0
}


check_process_pidfile()
{
    local pidf=$(ls /tmp/*-${HADOOP_USER}$1 2> /dev/null)
    local rt=$?
    local pid=0

    if [ -n "$pidf" ] && [ -r $pidf ]; then
        pid=$(cat ${pidf})
        check_process_pid $pid
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

rt=0
ACTION="$1"

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

        hostip_is_valid
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " Error! Unable to find a network interface. Please verify networking is configured properly."
            exit $rt
        fi

        echo " ------ Hadoop ------- "
        ( sudo -u $HADOOP_USER $HADOOP_HDFS_HOME/sbin/start-dfs.sh )
        ( sudo -u $HADOOP_USER $YARN_HOME/sbin/start-yarn.sh )
        ;;

    'stop')
        check_process_pidfile $RM_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            ( sudo -u $HADOOP_USER $YARN_HOME/sbin/stop-yarn.sh )
        else
            echo " YARN ResourceManager not running or not found."
        fi

        check_process_pidfile $NM_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            ( sudo -u $HADOOP_USER $YARN_HOME/sbin/stop-yarn.sh )
        fi

        check_process_pidfile $NN_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            ( sudo -u $HADOOP_USER $HADOOP_HDFS_HOME/sbin/stop-dfs.sh )
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
