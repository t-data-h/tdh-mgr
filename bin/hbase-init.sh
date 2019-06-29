#!/bin/bash
#
#  Init script for HBase Services
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HB_PIDFILE="/tmp/hbase-${HADOOP_USER}-master.pid"
RS_PIDFILE="/tmp/hbase-${HADOOP_USER}-1-regionserver.pid"
ZK_PIDFILE="/tmp/hbase-${HADOOP_USER}-zookeeper.pid"
HB_THRIFT_PSKEY=".hbase.thrift.ThriftServer"
HB_THRIFTLOG="${HADOOP_LOGDIR}/hbase/hbase-thriftserver.log"

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

HBASE_VER=$(readlink $HBASE_HOME)
# -----------


usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


get_process_pids()
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


check_process_pidfile()
{
    local pidf="$1"
    local pid=0
    local rt=0

    if [ -r $pidf ]; then
        pid=$(cat $pidf)
        check_process_pid $pid
        rt=$?
    fi

    return $rt
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

    #get_process_pid $HB_THRIFT_PSKEY
    check_process "$HB_THRIFT_PSKEY"
    if [ $rt -ne 0 ]; then
        echo " HBase ThriftServer    [$PID]"
    else
        echo " ThriftServer is not running"
    fi

    return $ret
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

echo " ------ $HBASE_VER ---------- "

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
            echo "Starting HBase..."
            ( sudo -u $HADOOP_USER $HBASE_HOME/bin/start-hbase.sh 2>&1 > /dev/null )
        fi

        check_process $HB_THRIFT_PSKEY
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " ThriftServer is already running  [$PID]"
        else
            echo "Starting HBase ThriftServer..."
            ( sudo -u $HADOOP_USER nohup $HBASE_HOME/bin/hbase thrift start 2>&1 > $HB_THRIFTLOG & )
        fi
        ;;

    'stop')
        check_process_pidfile $HB_PIDFILE

        echo "Stopping HBase..."
        ( sudo -u $HADOOP_USER $HBASE_HOME/bin/stop-hbase.sh 2>&1 > /dev/null )

        check_process $HB_THRIFT_PSKEY
        rt=$?

        if [ $rt -ne 0 ]; then
            echo "Stopping HBase ThriftServer [$PID]..."
            ( sudo -u $HADOOP_USER kill $PID )
        else
            echo "HBase Thrift Server not found..."
        fi
        rt=0
        ;;

    'status'|'info')
        rt= show_status
        ;;
    *)
        usage
        ;;
esac

exit $rt
