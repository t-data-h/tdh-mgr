#!/bin/bash
#  Custom init script for starting Apache Zeppelin
#   (in a pseudo-distributed environment)
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HADOOP_ENV="hadoop-env-user.sh"

ZEPPELIN_HOME="$HADOOP_ROOT/zeppelin"
ZKEY="ZeppelinServer"
ZPID=0


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
fi



usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $HADOOP_ENV_USER_VERSION"
}


show_status()
{
    check_process "$ZKEY"

    rt=$?
    if [ $rt -ne 0 ]; then
        echo " Zeppelin              [$PID]"
        rt=0
    else
        echo " Zeppelin is not running"
        rt=1
    fi

    return $rt
}


## MAIN
#

ACTION="$1"
rt=0

echo " ----- Zeppelin ------ "

case "$ACTION" in
    'start')
        check_process "$ZKEY"

        rt=$?
        if [ $rt -ne 0 ]; then
            echo " Zeppelin is already running [$rt]"
            exit $rt
        fi

        echo "Starting Zeppelin..."
        ( cd $ZEPPELIN_HOME; sudo -u $HADOOP_USER $ZEPPELIN_HOME/bin/zeppelin-daemon.sh start )
        rt=0
        ;;

    'stop')

        check_process "$ZKEY"

        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Stopping Zeppelin [$ZPID]..."
            ( sudo -u $HADOOP_USER $ZEPPELIN_HOME/bin/zeppelin-daemon.sh stop )
            rt=0
            #sleep 1
        else
            echo "Zeppelin not found..."
            rt=1
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
