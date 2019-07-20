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
RS_PIDFILE="/tmp/hbase-${HADOOP_USER}-regionserver.pid"
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


check_remote_pidfile()
{
    local host="$1"
    local pidf="$2"
    local rt=1

    PID=$( ssh $host "pid=\$(cat $pidf 2> /dev/null); \
        if [[ -z \$pid ]]; then exit 1; fi; \
        if ps ax | grep \$pid | grep -v grep 2>&1> /dev/null ; then \
        echo \$pid; else exit 1; fi" )
    rt=$?

    return $rt
}


show_status()
{
    local rt=0

    if [ "$HB_ADDR" == "$HOST_ADDR" ]; then
        check_process_pidfile $HB_PIDFILE
    else
        check_remote_pidfile $(host $HB_ADDR) $HB_PIDFILE
    fi

    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e "  HBase Master          | \e[32m\e[1m OK \e[0m | [${HOST}:${PID}]"
    else
        echo -e "  HBase Master          | \e[31m\e[1mDEAD\e[0m | [$HOST]"
    fi

    check_process_pidfile $ZK_PIDFILE
    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e "    Zookeeper           | \e[32m\e[1m OK \e[0m | [${HOST}:${PID}]"
    else
        echo -e "    Zookeeper           | \e[31m\e[1mDEAD\e[0m | [$HOST]"
    fi

    check_process "$HB_THRIFT_PSKEY"
    if [ $rt -eq 0 ]; then
        echo -e "    ThriftServer        | \e[32m\e[1m OK \e[0m | [${HOST}:${PID}]"
    else
        echo -e "    ThriftServer        | \e[31m\e[1mDEAD\e[0m | [$HOST]"
    fi
        
    echo -e "    ------------        |------|"

    set -f
    IFS=$'\n'

    for rs in $( cat ${HBASE_HOME}/conf/regionservers ); do
        ( echo $rs | grep $HOST > /dev/null )
        rt=$?

        if [ $rt -eq 0 ] || [ "$rs" == "localhost" ]; then
            check_process_pidfile $RS_PIDFILE
        else
            check_remote_pidfile $rs $RS_PIDFILE
        fi
        rt=$?
        if [ $rt -eq 0 ]; then
            echo -e "    RegionServer        | \e[32m\e[1m OK \e[0m | [${rs}:${PID}]"
        else
            echo -e "    RegionServer        | \e[31m\e[1mDEAD\e[0m | [$rs]"
        fi
    done

    return $ret
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

echo -e " -------- \e[96m$HBASE_VER\e[0m ---------- "

case "$ACTION" in
    'start')
        ( mkdir -p $HBASE_LOGDIR )

        check_process_pidfile $HB_PIDFILE

        rt=$?
        if [ $rt -eq 0 ]; then
            echo " HBase Master is already running  [$PID]"
        else
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
        rt=0
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
