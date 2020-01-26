#!/bin/bash
#
#  Init script for HBase Services
#
#  Timothy C. Arland <tcarland@gmail.com>
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

HBASE_VER=$(readlink $HBASE_HOME)

HB_MASTERS="${HBASE_HOME}/conf/masters"

HB_MASTER_ID=".hbase.master.HMaster start"
HB_REGION_ID=".hbase.regionserver.HRegionServer"
HB_THRIFT_ID=".hbase.thrift.ThriftServer"

HBASE_LOGDIR="${HADOOP_LOGDIR}/hbase"
HBASE_THRIFTLOG="${HBASE_LOGDIR}/hbase-thriftserver.log"

HOST=$(hostname -s)
HBASE_MASTER=$(cat $HBASE_HOME/conf/masters 2>/dev/null)

if [ -z "$HBASE_MASTER" ]; then
    echo "$PNAME: Error determining hbase master. "
    exit 1
fi

# -----------

usage()
{
    echo "$TDH_PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    local rt=0
    local islo=1

    ( echo $HBASE_MASTER | grep $HOST >/dev/null 2>&1 )
    islo=$?

    if [ $islo -eq 0 ]; then
        check_process $HB_MASTER_ID
    else
        check_remote_process $HBASE_MASTER $HB_MASTER_ID
    fi

    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " HBase Master           | $C_GRN OK $C_NC | [${HBASE_MASTER}:${PID}]"
    else
        echo -e " HBase Master           | ${C_RED}DEAD$C_NC | [$HBASE_MASTER]"
    fi

    if [ $islo -eq 0 ]; then
        check_process $HB_THRIFT_ID
    else
        check_remote_process $HBASE_MASTER $HB_THRIFT_ID
    fi

    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " HBase ThriftServer     | $C_GRN OK $C_NC | [${HBASE_MASTER}:${PID}]"
    else
        echo -e " HBase ThriftServer     | ${C_RED}DEAD$C_NC | [$HBASE_MASTER]"
    fi

    echo -e "      -------------     |------|"

    set -f
    IFS=$'\n'

    for rs in $( cat ${HBASE_HOME}/conf/regionservers ); do

        check_remote_process $rs $HB_REGION_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo -e " HBase RegionServer     | $C_GRN OK $C_NC | [${rs}:${PID}]"
        else
            echo -e " HBase RegionServer     | ${C_RED}DEAD$C_NC | [$rs]"
        fi
    done

    return $ret
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

echo -e " -------- ${C_CYN}${HBASE_VER}${C_NC} ---------- "

if [ -z "$HBASE_MASTER" ]; then
    echo "Error determining HBase Master host! Aborting.."
    exit 1
fi

case "$ACTION" in
    'start')
        ( mkdir -p $HBASE_LOGDIR )

        check_process $HB_MASTER_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo " HBase Master is already running  [${HBASE_MASTER}:${PID}]"
        else
            echo "Starting HBase..."
            ( $HBASE_HOME/bin/start-hbase.sh 2>&1 > /dev/null )
        fi

        check_process $HB_THRIFT_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo " ThriftServer is already running  [${HBASE_MASTER}:${PID}]"
        else
            echo "Starting HBase ThriftServer..."
            ( sudo -u $HADOOP_USER nohup $HBASE_HOME/bin/hbase thrift start 2>&1 > $HBASE_THRIFTLOG & )
        fi
        rt=0
        ;;

    'stop')
        check_process $HB_MASTER_ID

        echo "Stopping HBase Master [${HBASE_MASTER}:${PID}]..."
        ( sudo -u $HADOOP_USER $HBASE_HOME/bin/stop-hbase.sh >/dev/null 2>&1 )

        check_process $HB_THRIFT_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping HBase ThriftServer [${HBASE_MASTER}:${PID}]..."
            ( sudo -u $HADOOP_USER kill $PID )
        else
            echo "HBase ThriftServer not found..."
        fi
        rt=0
        ;;

    'status'|'info')
        show_status
        ;;

    --version|-V)
        version
        ;;
    *)
        usage
        ;;
esac

exit $rt
