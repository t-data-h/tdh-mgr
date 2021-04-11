#!/usr/bin/env bash
#
#  Init script for HBase Services
#
#  Timothy C. Arland <tcarland@gmail.com>
#

# ----------- preamble
HADOOP_ENV="tdh-env.sh"
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
    printf "ERROR, Unable to locate TDH Environment '$HADOOP_ENV' \n"
    exit 1
fi
# -----------

HOST=$(hostname -s)
HBASE_VER=$(readlink $HBASE_HOME)
HB_MASTERS="${HBASE_HOME}/conf/masters"
HB_MASTER_ID=".hbase.master.HMaster start"
HB_REGION_ID=".hbase.regionserver.HRegionServer"
HB_THRIFT_ID=".hbase.thrift.ThriftServer"
HBASE_LOGDIR="${HADOOP_LOGDIR}/hbase"
HBASE_THRIFTLOG="${HBASE_LOGDIR}/hbase-thriftserver.log"
HBASE_MASTER=$(cat $HBASE_HOME/conf/masters 2>/dev/null)

if [ -z "$HBASE_MASTER" ]; then
    printf "$TDH_PNAME Error determining HBase Master. \n"
    exit 1
fi

# --------------------------------------------

usage="
$TDH_PNAME {start|stop|status}
  TDH $TDH_VERSION
"

show_status()
{
    local rt=0

    check_remote_process $HBASE_MASTER $HB_MASTER_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " HBase Master           | $C_GRN OK $C_NC |  ${HBASE_MASTER} [${PID}]\n"
    else
        printf " HBase Master           | ${C_RED}DEAD$C_NC |  $HBASE_MASTER\n"
    fi

    check_remote_process $HBASE_MASTER $HB_THRIFT_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " HBase ThriftServer     | $C_GRN OK $C_NC |  ${HBASE_MASTER} [${PID}]\n"
    else
        printf " HBase ThriftServer     | ${C_RED}DEAD$C_NC |  $HBASE_MASTER\n"
    fi

    tdh_show_separator

    set -f
    IFS=$'\n'

    for rs in $( cat ${HBASE_HOME}/conf/regionservers ); do

        check_remote_process $rs $HB_REGION_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            printf " HBase RegionServer     | $C_GRN OK $C_NC |  ${rs} [${PID}]\n"
        else
            printf " HBase RegionServer     | ${C_RED}DEAD$C_NC |  $rs\n"
        fi
    done

    return $rt
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

tdh_show_header $HBASE_VER

if [ -z "$HBASE_MASTER" ]; then
    printf "$TDH_PNAME Error determining HBase Master host! Aborting.. \n"
    exit 1
fi

case "$ACTION" in
    'start')
        ( mkdir -p $HBASE_LOGDIR )

        check_remote_process $HBASE_MASTER $HB_MASTER_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            printf "  HBase Master is already running: ${HBASE_MASTER} [${PID}] \n"
        else
            printf "Starting HBase Master: '${HBASE_MASTER}' \n"
            ( ssh $HBASE_MASTER "$HBASE_HOME/bin/start-hbase.sh 2>&1 > /dev/null" )
        fi

        check_remote_process $HBASE_MASTER $HB_THRIFT_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            printf "  ThriftServer is already running: ${HBASE_MASTER} [${PID}] \n"
        else
            printf "Starting HBase ThriftServer '${HBASE_MASTER}' \n"
            ( ssh $HBASE_MASTER "sudo -u $HADOOP_USER nohup $HBASE_HOME/bin/hbase thrift start > $HBASE_THRIFTLOG 2>&1 &" )
        fi
        rt=0
        ;;

    'stop')
        check_remote_process $HBASE_MASTER $HB_MASTER_ID

        printf "Stopping HBase Master: ${HBASE_MASTER} [${PID}] \n"
        ( ssh $HBASE_MASTER "sudo -u $HADOOP_USER kill $PID >/dev/null 2>&1" )
        ( ssh $HBASE_MASTER "sudo -u $HADOOP_USER $HBASE_HOME/bin/stop-hbase.sh > /dev/null 2>&1" )

        check_remote_process $HBASE_MASTER $HB_THRIFT_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            printf "Stopping HBase ThriftServer: ${HBASE_MASTER} [${PID}] \n"
            ( ssh $HBASE_MASTER "sudo -u $HADOOP_USER kill $PID" )
        else
            printf "  HBase ThriftServer not found \n"
        fi
        rt=0
        ;;

    'status'|'info')
        show_status
        rt=$?
        ;;

    'help'|--help|-h)
        echo "$usage"
        ;;

    'version'|--version|-V)
        tdh_version
        ;;

    *)
        echo "$usage"
        ;;
esac

exit $rt
