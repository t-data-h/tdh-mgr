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
HADOOP_ENV="tdh-env-user.sh"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "/opt/TDH/etc/$HADOOP_ENV" ]; then
    . /opt/TDH/etc/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
# -----------


usage()
{
    echo "$PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

if [ -z "$TDH_DOCKER_MYSQL" ]; then
    exit 0;  # exit silently as no container name is provided or set
fi

echo " ------ mysql-5.7.26 --------- "

case "$ACTION" in
    'start')
        check_process "$TDHMYSQL"
        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Mysql Daemon already running [$PID]"
        else
            echo "Starting mysqld docker..."
            ( docker start $TDH_DOCKER_MYSQL > /dev/null )
        fi
        rt=0
        ;;

    'stop')
        check_process "$TDHMYSQL"
        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Mysql Container $TDH_DOCKER_MYSQL [$PID]..."
            ( docker stop $TDH_DOCKER_MYSQL > /dev/null )
        else
            echo " Mysqld not running or not found."
        fi
        rt=0
        ;;

    'status')
        check_process "$TDHMYSQL"
        rt=$?
        if [ $rt -eq 0 ]; then
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
