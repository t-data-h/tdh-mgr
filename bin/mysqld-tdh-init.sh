#!/bin/bash
#
#  Init script for the core hadoop services HDFS and YARN.
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

TDHMYSQL="mysqld --"

## ----------- preamble
HADOOP_ENV="hadoop-env-user.sh"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "/opt/TDH/etc/$HADOOP_ENV" ]; then        # /opt/TDH   is default
    . /opt/TDH/etc/$HADOOP_ENV
elif [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then    # $HOME is last
    . $HOME/hadoop/etc/$HADOOP_ENV
fi

if [ -z "$HADOOP_ENV_USER_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
# -----------


usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  Version: $HADOOP_ENV_USER_VERSION"
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

if [ -z "$TDHDOCKER_MYSQL" ]; then
    exit 0;  # exit silently as no container name is provided or set
fi

echo " ------- MySQL ------- "

case "$ACTION" in
    'start')
        check_process "$TDHMYSQL"
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Mysql Daemon already running [$PID]"
        else
            ( docker start $TDHDOCKER_MYSQL > /dev/null )
        fi
        rt=0
        ;;

    'stop')
        check_process "$TDHMYSQL"
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Stopping Mysql Container $TDHDOCKER_MYSQL [$PID]..."

            ( docker stop $TDHDOCKER_MYSQL > /dev/null )
        else
            echo " Mysqld not running or not found."
        fi
        rt=0
        ;;

    'status')
        check_process "$TDHMYSQL"
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " MySQL Daemon          [$PID]"
        else
            echo " MySQL Daemon is not running"
        fi
        ;;
    *)
        usage
        ;;
esac

exit $rt
