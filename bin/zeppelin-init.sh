#!/usr/bin/env bash
#
#  Custom init script for starting Apache Zeppelin
#
#  Timothy C. Arland <tcarland@gmail.com>
#

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"
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
    echo "$TDH_PNAME {start|stop|status}"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    check_process "$ZKEY"

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " Zeppelin Server        | $C_GRN OK  $C_NC | [${HOST}:${PID}]\n"
        rt=0
    else
        printf " Zeppelin Server        | ${C_RED}DEAD$C_NC | [${HOST}]\n"
        rt=1
    fi

    return $rt
}


## MAIN
#
ACTION="$1"
rt=0

printf " ------- ${C_CYN}${ZEPPELIN_VER}${C_NC} -------- \n"

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
