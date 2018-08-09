#!/bin/bash
#
#  Init script for HBase Services 
#
#  Timothy C. Arland <tcarland@gmail.com>
#
ACTION="$1"
PNAME=${0##*\/}
VERSION="0.512"
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"


HADOOP_ENV="hadoop-env-user.sh"

# source the hadoop-env-user script
if [ -z "$HADOOP_ENV_USER" ]; then
    if [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then
        HADOOP_ENV="$HOME/hadoop/etc/$HADOOP_ENV"
    elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
        HADOOP_ENV="/etc/hadoop/$HADOOP_ENV"
    elif [ -r "./$HADOOP_ENV" ]; then
        HADOOP_ENV="./$HADOOP_ENV"
    fi
    source $HADOOP_ENV
fi

if [ -z "$HADOOP_USER" ]; then
    HADOOP_USER="$USER"
fi


HB_PIDFILE="/tmp/hbase-${HADOOP_USER}-master.pid"
RS_PIDFILE="/tmp/hbase-${HADOOP_USER}-1-regionserver.pid"
ZK_PIDFILE="/tmp/hbase-${HADOOP_USER}-zookeeper.pid"
HB_THRIFT_PSKEY=".hbase.thrift.ThriftServer"
HB_THRIFTLOG="hbase-thriftserver.log"
PID=


if [ -n "$HADOOP_LOGDIR" ]; then
    HB_THRIFTLOG="$HADOOP_LOGDIR/hbase/$HB_THRIFTLOG"
else
    HB_THRIFTLOG="/tmp/$HB_THRIFTLOG"
fi


usage() 
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $VERSION"
}
 

get_process_pid()
{
    local key="$1"
    local pids=

    PID=0
    pids=$(ps awwwx | grep "$key" | grep -v "grep" | awk '{ print $1 }')

    for p in $pids; do
        PID=$p
        break
    done

    return 0
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
    local pidf="$1"
    local ret=0
    local pid=0

    if [ -r $pidf ]; then
        pid=$(cat $pidf)
        check_process_pid $pid
        ret=$?
    fi

    return $ret
}


show_status()
{
    local rt=0

    check_process_pidfile $ZK_PIDFILE
    rt=$?
    if [ $rt -ne 0 ]; then
        echo " Zookeeper             [$PID]"
    else
        echo " Zookeeper is not running"
    fi

    check_process_pidfile $HB_PIDFILE
    rt=$?
    if [ $rt -ne 0 ]; then
        echo " HBase Master          [$PID]"
    else
        echo " HBase Master is not running"
    fi

    check_process_pidfile $RS_PIDFILE
    rt=$?
    if [ $rt -ne 0 ]; then
        echo " HBase RegionServer    [$PID]"
    else
        echo " RegionServer is not running"
    fi

    get_process_pid $HB_THRIFT_PSKEY
    if [ $PID -ne 0 ]; then
        echo " HBase ThriftServer    [$PID]"
    else
        echo " ThriftServer is not running" 
    fi

    return $ret
}


# =================
#  MAIN
# =================

rt=0

echo " ------ HBase -------- "

case "$ACTION" in
    'start')
        check_process_pidfile $HB_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " HBase Master is already running  [$PID]"
        fi

        check_process_pidfile $RS_PIDFILE
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " RegionServer is already running  [$PID]"
        fi

        if [ $rt -eq 0 ]; then
            ( sudo -u $HADOOP_USER $HBASE_HOME/bin/start-hbase.sh )
        fi

        get_process_pid $HB_THRIFT_PSKEY
        if [ $PID -ne 0 ]; then
            echo " ThriftServer is already running  [$PID]"
        else
            echo "Starting HBase ThriftServer..."
            ( sudo -u $HADOOP_USER nohup $HBASE_HOME/bin/hbase thrift start > $HB_THRIFTLOG & )
        fi
        ;;

    'stop')
        ( sudo -u $HADOOP_USER $HBASE_HOME/bin/stop-hbase.sh )

        get_process_pid $HB_THRIFT_PSKEY
        if [ $PID -ne 0 ]; then
            echo "Stopping HBase ThriftServer [$PID]..."
            ( sudo -u $HADOOP_USER kill $PID )
        else
            echo "HBase Thrift Server not found..."
        fi
        ;;

    'status'|'info')
        rt= show_status
        ;;
    *)
        usage
        ;;
esac

exit $rt

