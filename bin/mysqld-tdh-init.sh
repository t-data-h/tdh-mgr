#!/bin/bash
#
#  Init script for the core hadoop services HDFS and YARN.
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HADOOP_ENV="hadoop-env-user.sh"
TDHMYSQL="mysqld"
TDHDOCKER_MYSQL="tdh-mysql1"


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


echo " ----- TDH MySQL ----- "

case "$ACTION" in
    'start')
        check_process "$TDHMYSQL"
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "TDH Mysql Daemon already running [$PID]"
            exit $rt
        fi

        ( docker start $TDHDOCKER_MYSQL )
        ;;

    'stop')
        check_process "$TDHMYSQL"
        rt=$?
        if [ $rt -ne 0 ]; then
            echo "Stopping TDH-Mysql [$PID]..."

            ( docker stop $TDHDOCKER_MYSQL )
        else
            echo " TDH Mysql not running or not found."
        fi
        ;;

    'status')
        check_process "$TDHMYSQL"
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " TDH MySQL             [$PID]"
        else
            echo " TDH MySQL is not running"
        fi
        ;;
    *)
        usage
        ;;
esac

exit $rt
