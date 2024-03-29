#!/usr/bin/env bash
#
#  Init script for tdh mysql instance 
#
#  Timothy C. Arland <tcarland@gmail.com>
#

## ----------- preamble
HADOOP_ENV="tdh-env.sh"
HADOOP_ENV_PATH="/opt/TDH/etc"

if [ -r "./etc/${HADOOP_ENV}" ]; then
    . ./etc/$HADOOP_ENV
    HADOOP_ENV_PATH="./etc"
elif [ -r "/etc/hadoop/${HADOOP_ENV}" ]; then
    . /etc/hadoop/$HADOOP_ENV
    HADOOP_ENV_PATH="/etc/hadoop"
elif [ -r "${HADOOP_ENV_PATH}/${HADOOP_ENV}" ]; then
    . $HADOOP_ENV_PATH/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'" >&2
    exit 1
fi
# -----------

TDH_MYSQL="mysqld --"
MYSQL_VER="mysql-5.7.27"


usage="
$TDH_PNAME {start|stop|status}
  TDH $TDH_VERSION
"


# =================
#  MAIN
# =================

ACTION="$1"
rt=0

if [ -z "$TDH_MYSQL_CONTAINER" ]; then
    exit 0;  # exit silently as no container name is provided or set
fi

tdh_show_header "$MYSQL_VER"

case "$ACTION" in
    'start')
        check_process "$TDH_MYSQL"
        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Mysql Daemon already running [$PID]"
        else
            echo "Starting mysqld container: '${TDH_MYSQL_CONTAINER}'"
            ( docker start $TDH_MYSQL_CONTAINER > /dev/null )
        fi
        rt=0
        ;;

    'stop')
        check_process "$TDH_MYSQL"
        rt=$?
        if [ $rt -eq 0 ]; then
            echo "Stopping Mysql Container: ${TDH_MYSQL_CONTAINER} [$PID]"
            ( docker stop $TDH_MYSQL_CONTAINER > /dev/null )
        else
            echo "  $TDH_PNAME 'mysqld' not running or not found."
        fi
        rt=0
        ;;

    'status')
        check_process "$TDH_MYSQL"
        rt=$?
        if [ $rt -eq 0 ]; then
            printf " MySQL Server           | $C_GRN OK $C_NC |  $TDH_MYSQL_CONTAINER [$PID]\n"
        else
            printf " MySQL Server           | ${C_RED}DEAD$C_NC |  $TDH_MYSQL_CONTAINER\n"
        fi
        ;;
    
    'help'|--help|-h)
        echo "$usage" 
        ;;

    'version'|--version|-V)
        tdh_version
        ;;

    *)
        echo "$usage"
        ;;
esac

exit $rt
