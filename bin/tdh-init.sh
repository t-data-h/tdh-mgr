#!/bin/bash
#
#   Wrapper script to operate on all hadoop ecosystem init scripts.
#   These can be provided via HADOOP_ECOSYSTEM_INITS
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

# default init script list
inits="hadoop-init.sh hbase-init.sh hive-init.sh kafka-init.sh \
spark-history-init.sh hue-init.sh"
force=0

HADOOP_ENV="hadoop-env-user.sh"


# source the hadoop-env-user script
if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then
    . $HOME/hadoop/etc/$HADOOP_ENV
fi

if [ -z "$HADOOP_ENV_USER_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
else
    echo ""
    echo "$PNAME v${HADOOP_ENV_USER_VERSION}"
    echo ""
fi

if [ -n "$HADOOP_ECOSYSTEM_INITS" ]; then
    inits="$HADOOP_ECOSYSTEM_INITS"
fi



usage()
{
    echo ""
    echo "Usage: $PNAME [-fh]  {start|stop|status}"
    echo "     -h|--help    : Show usage and exit"
    echo "     -f|--force   : Run all start/stop scripts ignoring any errors"
    echo "     -V|--version : Show TDH Environment version and exit"
    echo ""
    echo "  HADOOP_ECOSYSTEM_INITS=\"${HADOOP_ECOSYSTEM_INITS}\""
    if [ -z "$HADOOP_ECOSYSTEM_INITS" ]; then
        echo ""
        echo "  Using defaults:"
        echo "  '$inits'"
    fi
    echo ""
}


version()
{
    echo ""
    echo "  TDH Environment v${HADOOP_ENV_USER_VERSION}"
    echo ""
}


run_action()
{
    local action="$1"
    local rt=0
    local cmd=

    for cmd in $inits; do
        ( $cmd $action )
        rt=$?

        if [ $rt -ne 0 ] && [ $force -eq 0 ]; then
            echo "Error in init script! aborting.."
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
    for cmd in $inits; do
        if [ "$tmp" ]; then
            tmp="$cmd $tmp"
        else
            tmp="$cmd"
        fi
    done

    inits="$tmp"

    run_action "stop"
    rt=$?

    return $rt
}


show_status()
{
    local rt=0

    force=1
    run_action "status"
    rt=$?

    return $rt
}


# =================
#  MAIN
# =================

rt=0

if [ $# -eq 0 ]; then
    usage
fi

while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force)
            force=1
            echo "  --force : Ignoring errors.."
            ;;
        -h|--help)
            usage
            ;;
        -V|--version)
            version
            ;;
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
    shift
done

rt=$?

exit $rt
