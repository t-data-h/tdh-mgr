#!/usr/bin/env bash
#
#  Wrapper script to operate on all hadoop ecosystem init scripts.
#  The list of services can be provided via HADOOP_ECOSYSTEM_INITS
#  environment variable.
#
#  Timothy C. Arland <tcarland@gmail.com>
#

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"
HADOOP_ENV_PATH="/opt/TDH/etc"

if [ -r "./etc/${HADOOP_ENV}" ]; then
    . ./etc/$HADOOP_ENV
    HADOOP_ENV_PATH="./etc"
elif [ -r "/etc/hadoop/${HADOOP_ENV}" ]; then
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

# default init list
# add 'mysqld-tdh-init.sh' for a local docker instance of mysql
INITS="hadoop-init.sh zookeeper-init.sh hbase-init.sh hive-init.sh \
kafka-init.sh spark-history-init.sh"
force=0

if [ -n "$TDH_ECOSYSTEM_INITS" ]; then
    INITS="$TDH_ECOSYSTEM_INITS"
fi

# -----------

usage="
Script to operate on all TDH ecosystem init scripts.
The list of services is configured via HADOOP_ECOSYSTEM_INITS

Synopsis:
  $TDH_PNAME [-fhV] {start|stop|status}

Options:
     -h|--help    : Show usage and exit
     -f|--force   : Run all start/stop scripts ignoring any errors
     -V|--version : Show TDH version and exit
  

HADOOP_ECOSYSTEM_INITS=\"${TDH_ECOSYSTEM_INITS}\"
"

# -----------

run_action()
{
    local action="$1"
    local rt=0
    local cmd=

    for cmd in $INITS; do
        ( $cmd $action )
        rt=$?

        if [ $rt -ne 0 ] && [ $force -eq 0 ]; then
            echo "Caught Error in: '$cmd $action' (use '--force' to ignore)"
            return $rt
        fi
    done

    return $rt
}


start_all()
{
    local rt=0

    run_action "start"
    rt=$?

    return $rt
}


stop_all()
{
    local cmd=
    local tmp=
    local rt=0

    # reverse our list for stop
    for cmd in $INITS; do
        if [ "$tmp" ]; then
            tmp="$cmd $tmp"
        else
            tmp="$cmd"
        fi
    done

    INITS="$tmp"

    run_action "stop"
    rt=$?

    return $rt
}


show_status()
{
    local rt=0

    run_action "status"
    rt=$?

    echo " ------------------------------- "

    return $rt
}


#  MAIN
#

while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force)
            force=1
            ;;
        *)
            action="$1"
            ;;
    esac
    shift
done

case "$action" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    status|info)
        show_status
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

exit $?
