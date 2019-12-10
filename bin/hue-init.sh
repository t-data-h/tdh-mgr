#!/bin/bash
#  Custom init script for starting Hue
#   (in a pseudo-distributed environment)
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

HUE_VER=$(readlink $HUE_HOME)

HUE_HOME="$HADOOP_ROOT/hue"
HUE_KEY="hue runserver"
HUE_LOGDIR="$HADOOP_LOGDIR"

# -----------

usage()
{
    echo "$TDH_PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    get_process_pid "$HUE_KEY"
    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " Hue Web Server          [$PID]"
    else
        echo -e " Hue Web Server          not running"
    fi

    return $rt
}


ACTION="$1"
rt=0


case "$ACTION" in
    'start')
        check_process "$HUE_KEY"

        rt=$?
        if [ $rt -eq 0 ]; then
            echo " Hue is already running [$PID]"
            exit $rt
        fi

        echo "Starting Hue..."
        ( cd $HUE_HOME; sudo -u $HADOOP_USER nohup $HUE_HOME/build/env/bin/hue runserver > $HUE_LOGDIR/hue.log & )
        ;;

    'stop')
        check_process "$HUE_KEY"

        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Hue [$PID]..."
            ( sudo -u $HADOOP_USER kill $PID )
            sleep 1
            ( sudo -u $HADOOP_USER killall hue > /dev/null )
        else
            echo "Hue Server not found..."
        fi
        ;;

    'status'|'info')
        show_status
        rt=$?
        ;;
    *)
        usage
        ;;
esac

exit $rt
