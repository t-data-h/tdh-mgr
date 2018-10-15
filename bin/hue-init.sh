#!/bin/bash
#  Custom init script for starting Hue
#   (in a pseudo-distributed environment)
#
#  Timothy C. Arland <tcarland@gmail.com>
#
ACTION="$1"
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"


HADOOP_ENV="hadoop-env-user.sh"

# source the hadoop-env-user script
if [ -z "$HADOOP_ENV_USER" ]; then
    if [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then
        HADOOP_ENV="$HOME/hadoop/etc/$HADOOP_ENV"
    elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
        HADOOP_ENV="/etc/hadoop/$HADOOP_ENV"
    elif [ -r "./$HADOOP_ENV" ]; then
        HADOOP_ENV="./$HADOOP_ENV"
    fi
    source $HADOOP_ENV
fi


HUE_HOME="/opt/hadoop/hue"
HUE_KEY="hue runserver"
HUE_LOGDIR="/var/log/hadoop"
HPID=0


if [ -z "$HADOOP_USER" ]; then
    HADOOP_USER="$USER"
fi

if [ -n "$HADOOP_LOGDIR" ]; then
    HUE_LOGDIR="$HADOOP_LOGDIR"
fi



usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $HADOOP_ENV_USER_VERSION"
}


get_process_pid()
{
    local key="$1"
    local pids=

    HPID=0
    pids=$(ps awwwx | grep "$key" | grep -v "grep" | awk '{ print $1 }')

    # this is ugly, but the key with a space (even quoted) in it caused
    # some reliability issues with the above grep
    for p in $pids; do
        HPID=$p
        break
    done

    return 0
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


pid=0
rt=0


case "$ACTION" in
    'start')
        get_process_pid "$HUE_KEY"

        if [ $HPID -ne 0 ]; then
            echo " Hue is already running [$HPID]"
            exit $HPID
        fi

        echo "Starting Hue..."
        ( cd $HUE_HOME; sudo -u $HADOOP_USER nohup $HUE_HOME/build/env/bin/hue runserver > $HUE_LOGDIR/hue.log & )
        ;;

    'stop')

        get_process_pid "$HUE_KEY"

        if [ $HPID -ne 0 ]; then
            echo "Stopping Hue [$HPID]..."
            ( sudo -u $HADOOP_USER kill $HPID )
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
