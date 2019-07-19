#!/bin/bash
#  Custom init script for starting Apache Zeppelin
#   (in a pseudo-distributed environment)
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "opt/TDH/etc/$HADOOP_ENV" ]; then
    . /opt/TDH/etc/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi

# -----------

ZEPPELIN_VER=$(readlink $ZEPPELIN_HOME)
ZEPPELIN_HOME="$HADOOP_ROOT/zeppelin"
ZKEY="ZeppelinServer"
ZPID=0
HOST=$(hostname -s)

# -----------

usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    check_process "$ZKEY"

    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " Zeppelin Server          \e[32m\e[1m OK   \e[0m [${HOST}:${PID}]"
        rt=0
    else
        echo -e " Zeppelin Server          \e[31m\e[1m DEAD \e[0m [${HOST}]"
        rt=1
    fi

    return $rt
}


## MAIN
#
ACTION="$1"
rt=0

echo " ----- $ZEPPELIN_VER -------- "

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
            echo "Stopping Zeppelin [$PID]..."
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
