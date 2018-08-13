#!/bin/bash
#  Custom init script for starting Apache Zeppelin 
#   (in a pseudo-distributed environment)
# 
#  Timothy C. Arland <tcarland@gmail.com>
#
ACTION="$1"
PNAME=${0##*\/}
VERSION="0.511"
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


ZEPPELIN_HOME="/opt/hadoop/zeppelin"
ZKEY="ZeppelinServer"
ZLOGDIR="/var/log/hadoop"
ZPID=0


if [ -z "$HADOOP_USER" ]; then
    HADOOP_USER="$USER"
fi

if [ -n "$HADOOP_LOGDIR" ]; then
    ZLOGDIR="$HADOOP_LOGDIR"
fi



usage() 
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $VERSION"
}


get_process_pid()
{
    local key="$1"
    local pids=
    
    ZPID=0
    pids=$(ps awwwx | grep "$key" | grep -v "grep" | awk '{ print $1 }')

    # this is ugly, but the key with a space (even quoted) in it caused 
    # some reliability issues with the above grep
    for p in $pids; do   
        ZPID=$p
        break
    done

    return 0
}

show_status()
{
    get_process_pid "$ZKEY"
    if [ $ZPID -ne 0 ]; then
        echo " Zeppelin              [$ZPID]"
    else
        echo " Zeppelin is not running"
    fi

    return $ZPID
}


pid=0
rt=0

echo " ----- Zeppelin ------ "

case "$ACTION" in
    'start')
        get_process_pid "$ZKEY"

        if [ $ZPID -ne 0 ]; then
            echo " Zeppelin is already running [$ZPID]"
            exit $ZPID
        fi

        echo "Starting Zeppelin..."
        ( cd $ZEPPELIN_HOME; sudo -u $HADOOP_USER $ZEPPELIN_HOME/bin/zeppelin-daemon.sh start )
        ;;

    'stop')

        get_process_pid "$ZKEY"
        
        if [ $ZPID -ne 0 ]; then
            echo "Stopping Zeppelin [$ZPID]..."
            ( sudo -u $HADOOP_USER $ZEPPELIN_HOME/bin/zeppelin-daemon.sh stop )
            #sleep 1
        else
            echo "Zeppelin not found..."
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






