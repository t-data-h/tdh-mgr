#!/bin/bash
#
#   Wrapper script to operate on all hadoop ecosystem init scripts.
#   These can be provided via HADOOP_ECOSYSTEM_INITS
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

# default init script list
INITS="hadoop-init.sh mysqld-tdh-init.sh hbase-init.sh hive-init.sh kafka-init.sh \
spark-history-init.sh hue-init.sh"
force=0

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"
HADOOP_ENV_PATH=

if [ -r "./etc/$HADOOP_ENV" ]; then                 # local directory 1st
    . ./etc/$HADOOP_ENV
    HADOOP_ENV_PATH="./etc"
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then         # /etc/hadoop/  primary
    . /etc/hadoop/$HADOOP_ENV
    HADOOP_ENV_PATH="/etc/hadoop"
elif [ -r "/opt/TDH/etc/$HADOOP_ENV" ]; then                # /opt/TDH   is default
    . $HADOOP_ENV_PATH/$HADOOP_ENV
    HADOOP_ENV_PATH="/opt/TDH/etc"
elif [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then    # $HOME is last
    . $HOME/hadoop/etc/$HADOOP_ENV
    HADOOP_ENV_PATH="$HOME/hadoop/etc"
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
else
    echo ""
    echo "$PNAME v${TDH_VERSION} (${HADOOP_ENV_PATH}/${HADOOP_ENV})"
    echo ""
fi

if [ -n "$HADOOP_ECOSYSTEM_INITS" ]; then
    INITS="$HADOOP_ECOSYSTEM_INITS"
fi
# -----------


usage()
{
    echo ""
    echo "Usage: $PNAME [-fh]  {start|stop|status}"
    echo "     -h|--help    : Show usage and exit"
    echo "     -f|--force   : Run all start/stop scripts ignoring any errors"
    echo "     -V|--version : Show TDH version and exit"
    echo ""
    echo "  HADOOP_ECOSYSTEM_INITS=\"${HADOOP_ECOSYSTEM_INITS}\""
    if [ -z "$HADOOP_ECOSYSTEM_INITS" ]; then
        echo ""
        echo "  Using default list:"
        echo "  '$INITS'"
    fi
    echo ""
}


version()
{
    echo ""
    echo "  TDH Environment v${TDH_VERSION}"
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
