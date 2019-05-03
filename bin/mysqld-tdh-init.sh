#!/bin/bash
#
#  Init script for the core hadoop services HDFS and YARN.
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HADOOP_ENV="hadoop-env-user.sh"
TDHMYSQL="mysqld --"


# source the hadoop-env-user script
if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then
    . $HOME/hadoop/etc/$HADOOP_ENV
fi



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
            exit $rt
        fi

        ( docker start $TDHDOCKER_MYSQL )
        ;;

    'stop')
        check_process "$TDHMYSQL"
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Stopping Mysql Docker $TDHDOCKER_MYSQL [$PID]..."

            ( docker stop $TDHDOCKER_MYSQL > /dev/null )
        else
            echo " Mysqld not running or not found."
        fi
        ;;

    'status')
        check_process "$TDHMYSQL"
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "  MySQL                [$PID]"
        else
            echo " MySQL Daemon is not running"
        fi
        ;;
    *)
        usage
        ;;
esac

exit $rt
