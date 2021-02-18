#!/bin/bash
#
#  tdh-env-user.sh - Bash environment for TDH.
#
#
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"
VERSION="v21.02.18"

export TDH_VERSION="$VERSION"
export TDH_ENV_USER=1

# JAVA_HOME should be set or managed by the system.
if [ -z "$JAVA_HOME" ]; then
    echo "WARNING! JAVA_HOME is not set"
fi

export HADOOP_USER="${USER}"
export HADOOP_ROOT="/opt/TDH"
export HADOOP_HOME="$HADOOP_ROOT/hadoop"
export HADOOP_LOGDIR="/var/log/hadoop"
export HADOOP_PID_DIR="/tmp"

if [ -z "$HADOOP_CONF_DIR" ]; then
    echo " -> Warning, HADOOP_CONF_DIR is not set!"
    export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
    echo " -> Using default: HADOOP_CONF_DIR=${HADOOP_CONF_DIR}"
fi

export HADOOP_COMMON_HOME="$HADOOP_HOME"
export HADOOP_HDFS_HOME="$HADOOP_COMMON_HOME"
export HADOOP_MAPRED_HOME="$HADOOP_COMMON_HOME"
export HADOOP_YARN_HOME="$HADOOP_COMMON_HOME"
export ZOOKEEPER_HOME="$HADOOP_ROOT/zookeeper"
export HBASE_HOME="$HADOOP_ROOT/hbase"
export HBASE_CONF_DIR="$HBASE_HOME/conf"
export HIVE_HOME="$HADOOP_ROOT/hive"
export HIVE_CONF_DIR="$HIVE_HOME/conf"
export KAFKA_HOME="$HADOOP_ROOT/kafka"
export SPARK_HOME="$HADOOP_ROOT/spark"
export SPARK_CONF_DIR="$SPARK_HOME/conf"

export HADOOP_PATH="\
$HADOOP_ROOT/bin:\
$HADOOP_ROOT/sbin:\
$HADOOP_HOME/bin:\
$HBASE_HOME/bin:\
$HIVE_HOME/bin:\
$KAFKA_HOME/bin:\
$SPARK_HOME/bin"

# set a mysqld docker container by name
# this alone has no effect, but with TDH_ECOSYSTEM_INITS+='mysqld-tdh-init.sh'
export TDH_DOCKER_MYSQL="tdh-mysql01"

# Kafka
if [ -f "/etc/kafka/jaas.conf" ]; then
    export KAFKA_OPTS="-Djava.security.auth.login=/etc/kafka/jaas.conf"
fi
if [ -f "/etc/kafka/conf/kafka-client.conf" ]; then
    export ZKS=$( cat /etc/kafka/conf/kafka-client.conf 2>/dev/null | awk -F '=' '{ print $2 }' )
fi

# Highlighting
C_RED='\e[31m\e[1m'
C_GRN='\e[32m\e[1m'
C_YEL='\e[93m'  # 33 dim, 93 bright
C_BLU='\e[34m\e[1m'
C_MAG='\e[95m'
C_CYN='\e[96m'
C_WHT='\e[97m'
C_NC='\e[0m'

# -----------------------------------------------
#  WARNING! Do not edit below this line.
#
#  tdh-env-functions
#
TDH_PNAME=${0##*\/}
PID=

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${HADOOP_HOME}/lib/native

if [ -n "$HADOOP_PATH" ]; then
    export PATH=${PATH:+${PATH}:}$HADOOP_PATH
fi

# -------------------

function tdh_version()
{
    printf "${TDH_PNAME} ${TDH_VERSION} (${HADOOP_ENV_PATH}/${HADOOP_ENV})\n"
    return 0
}

function tdh_show_header()
{
    local ver="$1"
    printf " -------- ${C_CYN}${ver}${C_NC} --------- \n"

}

function tdh_show_separator()
{
    printf "      -------------     |------|\n"
}

function check_process_pid()
{
    local pid=$1

    if ps ax | grep $pid | grep -v grep 2>&1> /dev/null ; then
        PID=$pid
        return 0
    fi

    return 1
}

function check_process()
{
    local key="$1"
    local rt=1

    if [ -z "$key" ]; then
        return $rt
    fi

    pid=$(ps ax | grep "$key" | grep -v grep | awk '{ print $1 }')

    if [ -n "$pid" ]; then
        check_process_pid $pid
        rt=$?
    fi

    return $rt
}

# Check a process on a remote host (via ssh) and set PID accordingly.
function check_remote_process()
{
    local host="$1"
    local pkey="$2"
    local rt=1

    PID=$( ssh $host "ps ax | grep $pkey | grep -v grep | awk '{ print \$1 }'" )

    rt=$?
    if [ -z "$PID" ]; then
        rt=1
    fi

    return $rt
}

# Validates that our configured hostname as provided by `hostname -f`
# locally resolves to an interface other than the loopback
function hostip_is_valid()
{
    local hostid=$(hostname -s)
    local hostip=$(hostname -i)
    local fqdn=$(hostname -f)
    local iface=
    local ip=
    local rt=1

    printf "%s \n [%s] : %s" $fqdn $hostid $hostip

    if [ "$hostip" == "127.0.0.1" ]; then
        printf "  <lo>\n  WARNING! Hostname is set to localhost, aborting..\n"
        return $rt
    fi

    IFS=$'\n'

    #for line in `ifconfig | grep inet`; do ip=$( echo $line | awk '{ print $2 }' )
    for line in $(/sbin/ip addr list | grep "inet ")
    do
        IFS=' '
        iface=$(echo $line | awk -F' ' '{ print $NF }')
        ip=$(echo $line | awk '{ print $2 }' | awk -F'/' '{ print $1 }')

        if [ "$ip" == "$hostip" ]; then
            rt=0
            break
        fi
    done

    if [ $rt -eq 0 ]; then
        echo " : <$iface>"
    fi
    echo ""

    return $rt
}

function hconf()
{
    if [ -n "$1" ]; then
        export HADOOP_CONF_DIR="$1"
    fi
    echo "HADOOP_CONF_DIR=$HADOOP_CONF_DIR"
}

function getBrokers()
{
    local brokersfile=${1:-${KAFKA_HOME}/config/brokers}
    local tmpifs=$IFS

    IFS=$'\n'
    BROKERS=$( cat ${brokersfile} 2>/dev/null | awk '{ print $1 }' | paste -s -d, - )
    IFS=$tmpifs

    export BROKERS
}

function getZookeepers()
{
    local zoomasters=${1:-${ZOOKEEPER_HOME}/conf/masters}
    local tmpifs=$IFS

    IFS=$'\n'
    ZKS=$( cat ${zoomasters} 2>/dev/null | paste -s -d, - )
    IFS=$tmpifs

    export ZKS
}
