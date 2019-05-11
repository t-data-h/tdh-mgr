#!/bin/bash
#  Custom init script for starting Hue
#   (in a pseudo-distributed environment)
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HUE_HOME="$HADOOP_ROOT/hue"
HUE_KEY="hue runserver"
HUE_LOGDIR="$HADOOP_LOGDIR"

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "/opt/TDH/etc/$HADOOP_ENV" ]; then        # /opt/TDH   is default
    . /opt/TDH/etc/$HADOOP_ENV
elif [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then    # $HOME is last
    . $HOME/hadoop/etc/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
# -----------



usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $TDH_VERSION"
}


show_status()
{
    get_process_pid "$HUE_KEY"
    if [ $HPID -ne 0 ]; then
        echo " Hue Web Server        [$HPID]"
    else
        echo " Hue is not running"
    fi

    return $HPID
}


ACTION="$1"
rt=0


case "$ACTION" in
    'start')
        check_process "$HUE_KEY"

        rt=$?
        if [ $rt -ne 0 ]; then
            echo " Hue is already running [$PID]"
            exit $rt
        fi

        echo "Starting Hue..."
        ( cd $HUE_HOME; sudo -u $HADOOP_USER nohup $HUE_HOME/build/env/bin/hue runserver > $HUE_LOGDIR/hue.log & )
        ;;

    'stop')
        check_process "$HUE_KEY"

        rt=$?
        if [ $rt -ne 0 ]; then
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
