#!/bin/bash
#  hadoop-env-user.sh
#  Sets up the environment for TDH components.
#
#  Timothy C. Arland <tcarland@gmail.com>

export TDH_ENV_USER=1
export TDH_VERSION="0.7.3"


# Assume that JAVA_HOME is already set or managed by the system.
#export JAVA_HOME=${JAVA_HOME}
if [ -z "$JAVA_HOME" ]; then
    echo "Error JAVA_HOME is not set"
    exit 1
fi

export HADOOP_USER="${USER}"
export HADOOP_ROOT="/opt/TDH"
export HADOOP_HOME="$HADOOP_ROOT/hadoop"
export HADOOP_LOGDIR="/var/log/hadoop"
export HADOOP_PID_DIR="/tmp"

# enable mysqld docker container by name
export TDHDOCKER_MYSQL="tdh-mysql1"

# HADOOP_CONF_DIR should always be set by user prior to sourcing the Environment
# to support switching environments.
if [ -z "$HADOOP_CONF_DIR" ]; then
    echo "Warning! HADOOP_CONF_DIR is not set!"
    export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
    echo "=> Setting default HADOOP_CONF_DIR=${HADOOP_CONF_DIR}"
fi

# Set components home
export HADOOP_COMMON_HOME="$HADOOP_HOME"
export HADOOP_HDFS_HOME="$HADOOP_COMMON_HOME"
export HADOOP_MAPRED_HOME="$HADOOP_COMMON_HOME"
export HADOOP_YARN_HOME="$HADOOP_COMMON_HOME"
export HBASE_HOME="$HADOOP_ROOT/hbase"
export HBASE_CONF_DIR="$HBASE_HOME/conf"
export HIVE_HOME="$HADOOP_ROOT/hive"
export KAFKA_HOME="$HADOOP_ROOT/kafka"
export SPARK_HOME="$HADOOP_ROOT/spark"

# bin path
export HADOOP_PATH="\
$HADOOP_ROOT/bin:\
$HADOOP_ROOT/sbin:\
$HADOOP_HOME/bin:\
$HBASE_HOME/bin:\
$HIVE_HOME/bin:\
$KAFKA_HOME/bin:\
$SPARK_HOME/bin"


# Kafka
if [ -f "/etc/kafka/jaas.conf" ]; then
    export KAFKA_OPTS="-Djava.security.auth.login=/etc/kafka/jaas.conf"
fi

if [ -f "/etc/kafka/conf/kafka-client.conf" ]; then
    export ZKS=$( cat /etc/kafka/conf/kafka-client.conf | awk -F '=' '{ print $2 }' )
fi

# -----------------------------------------------
#  NOTE:  Do not edit below this line.
#
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${HADOOP_HOME}/lib/native

if [ -n "$HADOOP_PATH" ]; then
    export PATH=${PATH:+${PATH}:}$HADOOP_PATH
fi

PID=


check_process_pid()
{
    local pid=$1

    if ps ax | grep $pid | grep -v grep 2>&1> /dev/null ; then
        PID=$pid
        return 1
    fi

    return 0
}


check_process()
{
    local key="$1"
    local rt=0

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


#  Validates that our configured hostname as provided by `hostname -f`
#  locally resolves to an interface other than the loopback
hostip_is_valid()
{
    local hostid=$(hostname -s)
    local hostip=$(hostname -i)
    local fqdn=$(hostname -f)
    local iface=
    local ip=
    local rt=1

    echo "$fqdn"
    echo -n  "[$hostid] : $hostip"

    if [ "$hostip" == "127.0.0.1" ]; then
        echo "   <lo> "
        echo "  WARNING! Hostname is set to localhost, aborting.."
        return $rt
    fi

    IFS=$'\n'

    #for line in `ifconfig | grep inet`; do ip=$( echo $line | awk '{ print $2 }' )
    for line in `ip addr list | grep "inet "`
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
