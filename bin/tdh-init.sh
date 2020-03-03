#!/bin/bash
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
# add mysqld-tdh-init.sh  for a local docker instance of mysql
INITS="hadoop-init.sh zookeeper-init.sh hbase-init.sh hive-init.sh \
kafka-init.sh spark-history-init.sh"
force=0

if [ -n "$TDH_ECOSYSTEM_INITS" ]; then
    INITS="$TDH_ECOSYSTEM_INITS"
fi

# -----------

usage()
{
    echo ""
    echo "Usage: $TDH_PNAME [-fh]  {start|stop|status}"
    echo "     -h|--help    : Show usage and exit"
    echo "     -f|--force   : Run all start/stop scripts ignoring any errors"
    echo "     -V|--version : Show TDH version and exit"
    echo ""
    echo "  HADOOP_ECOSYSTEM_INITS=\"${TDH_ECOSYSTEM_INITS}\""
    if [ -z "$TDH_ECOSYSTEM_INITS" ]; then
        echo ""
        echo "  Using default list:"
        echo "  '$INITS'"
    fi
    echo ""
}


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


# =================
#  MAIN
# =================


if [ $# -eq 0 ]; then
    usage
    exit 1
fi

version

while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force)
            force=1
            echo "  --force : Ignoring errors.."
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -V|--version)
            version
            exit 0
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
    *)
        usage
        ;;
esac

exit $?
