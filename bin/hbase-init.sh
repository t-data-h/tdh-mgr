#!/bin/bash
#
#  Init script for HBase Services
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

HBASE_VER=$(readlink $HBASE_HOME)

HB_PIDFILE="/tmp/hbase-${HADOOP_USER}-master.pid"
RS_PIDFILE="/tmp/hbase-${HADOOP_USER}-1-regionserver.pid"
ZK_PIDFILE="/tmp/hbase-${HADOOP_USER}-zookeeper.pid"
HB_THRIFT_PSKEY=".hbase.thrift.ThriftServer"

HBASE_LOGDIR="${HADOOP_LOGDIR}/hbase"
HBASE_THRIFTLOG="${HBASE_LOGDIR}/hbase-thriftserver.log"

HOST=$(hostname -s)
HOST_ADDR=$(hostname -i)
HB_ADDR=$( grep -A1 'hbase.master.info.bindAddress' ${HBASE_HOME}/conf/hbase-site.xml | \
  grep value | \
  sed -E 's/.*<value>(.*)<\/value>/\1/' | \
  awk -F':' '{ print $1 }' )

# -----------

usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


check_process_pidfile()
{
    local pidf="$1"
    local pid=0
    local rt=1

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
    if [ $rt -eq 0 ]; then
        echo " Zookeeper             [$PID]"
    else
        echo " Zookeeper is not running"
    fi

    if [ "$HB_ADDR" == "$HOST_ADDR" ]; then
        check_process_pidfile $HB_PIDFILE
        rt=$?
        if [ $rt -eq 0 ]; then
            echo " HBase Master          [$PID]"
        else
            echo " HBase Master is not running"
        fi
    #else
        #echo " HBase Master          [$( host $HB_ADDR )]"
    fi

    set -f
    IFS=$'\n'

    for rs in $( cat ${HBASE_HOME}/conf/regionservers ); do
        ( echo $rs | grep $HOST )
        if [ $? -eq 0 ] || [ "$dn" == "localhost" ]; then
            check_process_pidfile $RS_PIDFILE
            rt=$?
            if [ $rt -eq 0 ]; then
                echo " HBase RegionServer    [$PID]"
            else
                echo " HBase RegionServer is not running"
            fi
        else
            echo " HBase RegionServer    [$rs]"
        fi
    done

    #get_process_pid $HB_THRIFT_PSKEY
    check_process "$HB_THRIFT_PSKEY"
    if [ $rt -eq 0 ]; then
        echo " HBase ThriftServer    [$PID]"
    else
        echo " HBase ThriftServer is not running"
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
        if [ $rt -eq 0 ]; then
            echo " HBase Master is already running  [$PID]"
        fi

        check_process_pidfile $RS_PIDFILE
        rt=$?
        if [ $rt -eq 0 ]; then
            echo " RegionServer is already running  [$PID]"
        fi

        ( mkdir -p $HBASE_LOGDIR )

        if [ $rt -eq 0 ]; then
            echo "Starting HBase..."
            ( sudo -u $HADOOP_USER $HBASE_HOME/bin/start-hbase.sh 2>&1 > /dev/null )
        fi

        check_process $HB_THRIFT_PSKEY
        rt=$?
        if [ $rt -eq 0 ]; then
            echo " ThriftServer is already running  [$PID]"
        else
            echo "Starting HBase ThriftServer..."
            ( sudo -u $HADOOP_USER nohup $HBASE_HOME/bin/hbase thrift start 2>&1 > $HBASE_THRIFTLOG & )
        fi
        ;;

    'stop')
        check_process_pidfile $HB_PIDFILE

        echo "Stopping HBase [$PID]..."
        ( sudo -u $HADOOP_USER $HBASE_HOME/bin/stop-hbase.sh 2>&1 > /dev/null )

        check_process $HB_THRIFT_PSKEY
        rt=$?

        if [ $rt -eq 0 ]; then
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
