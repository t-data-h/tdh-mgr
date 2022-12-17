#!/bin/bash
#
#  tdh-env.sh - Environment file for TDH.
#
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"
VERSION="v22.08"

export TDH_VERSION="$VERSION"
export TDH_HOME="/opt/TDH"
export TDH_ENV="tdh-env.sh $VERSION"

export HADOOP_USER="$USER"
export HADOOP_ROOT="$TDH_HOME"
export HADOOP_HOME="${HADOOP_ROOT}/hadoop"
export HADOOP_LOG_DIR="/var/log/tdh"
export HADOOP_TMP_DIR="/tmp"
export HADOOP_PID_DIR="$HADOOP_TMP_DIR"

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
export FLINK_HOME="$HADOOP_ROOT/flink"
export FLINK_CONF_DIR="$FLINK_HOME/conf"

export HADOOP_PATH="\
$HADOOP_ROOT/bin:\
$HADOOP_ROOT/sbin:\
$HADOOP_HOME/bin:\
$HBASE_HOME/bin:\
$HIVE_HOME/bin:\
$KAFKA_HOME/bin:\
$SPARK_HOME/bin:\
$FLINK_HOME/bin"

# Highlighting
C_RED='\e[31m\e[1m'
C_GRN='\e[32m\e[1m'
C_YEL='\e[93m'  # 33 dim, 93 bright
C_BLU='\e[34m\e[1m'
C_MAG='\e[95m'
C_CYN='\e[96m'
C_WHT='\e[97m\e[1m'
C_NC='\e[0m'

if [ -z "$HADOOP_CONF_DIR" ]; then
    printf " -> ${C_YEL}WARNING${C_NC}, variable HADOOP_CONF_DIR is not set! \n"
    export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
    printf " -> Using default: HADOOP_CONF_DIR=${HADOOP_CONF_DIR} \n"
fi

if [ -z "$JAVA_HOME" ]; then
    printf " -> ${C_YEL}WARNING!${C_NC} JAVA_HOME is not set \n" >&2
fi

# this alone has no effect, but enabled w/ TDH_ECOSYSTEM_INITS+=('mysqld-tdh-init.sh')
export TDH_DOCKER_MYSQL="tdh-mysql01"

# Kafka
if [ -f "/etc/kafka/jaas.conf" ]; then
    export KAFKA_OPTS="-Djava.security.auth.login=/etc/kafka/jaas.conf"
fi
if [ -f "/etc/kafka/conf/kafka-client.conf" ]; then
    export ZKS=$( cat /etc/kafka/conf/kafka-client.conf 2>/dev/null | awk -F '=' '{ print $2 }' )
fi


# -----------------------------------------------
#  Do not edit below this line.
#
#  tdh-env.sh
#
TDH_PNAME=${0##*\/}
PID=

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${HADOOP_HOME}/lib/native

if [ -n "$HADOOP_PATH" ]; then
    export PATH=${PATH:+${PATH}:}$HADOOP_PATH
fi

export HADOOP_CLASSPATH=$(hadoop classpath)

# -------------------

function tdh_version()
{
    printf "${TDH_PNAME} ${TDH_VERSION} (${HADOOP_ENV_PATH}/${HADOOP_ENV})\n"
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

function tdh_show_cols()
{
    printf "    == Component ==      Status     Host     PID \n"
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


# Validates that the configured hostname, eg. as provided by `hostname -f`,
# resolves to a locally defined interface other than the loopback
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
        printf " : <$iface>"
    fi
    printf "\n"

    return $rt
}


# shows or sets HADOOP_CONF_DIR
function hconfdir()
{
    if [ -n "$1" ]; then
        export HADOOP_CONF_DIR="$1"
    fi
    printf "HADOOP_CONF_DIR=$HADOOP_CONF_DIR\n"
}


# populates the BROKERS variable with currently configured broker list
function getBrokers()
{
    local brokersfile=${1:-${KAFKA_HOME}/config/brokers}
    local tmpifs=$IFS

    IFS=$'\n'
    BROKERS=$(cat ${brokersfile} 2>/dev/null | awk '{ print $1 }' | paste -s -d, -)
    IFS=$tmpifs

    printf "%s" ${BROKERS}

    export BROKERS
}


# populates the variable 'ZKS' with the currently defined zookeepers
function getZookeepers()
{
    local zoomasters=${1:-${ZOOKEEPER_HOME}/conf/masters}
    local tmpifs=$IFS

    IFS=$'\n'
    ZKS=$(cat ${zoomasters} 2>/dev/null | paste -s -d, -)
    IFS=$tmpifs

    printf "%s" ${ZKS}

    export ZKS
}


# xq is a python3 app from https://github.com/kislyuk/yq, which is installed 
# with this version of yq, but the *other* [yq](https://github.com/mikefarah/yq) 
# project (golang) is more widely used for yaml. 
#
# Convert a config XML to key=value pairs
function xmlFile_toKV()
{
    local xml="$1"
    if [ -n "$xml" ]; then
        ( cat $xml | xq ".configuration[]" | jq ".[]" | jq -r ".name + \"=\" + .value" )
    fi
}


# convert a key=value pair to an XML Property stanza
function kv_toXml()
{
    local kv="$1"
    local fs=${2:-'='}
    local key=$(echo $kv | awk -F$fs '{ print $1 }')
    local val=$(echo $kv | awk -F$fs '{ print $2 }')

    echo "    <property>
        <name>${key}</name>
        <value>${val}</value>
    </property>"

    return 0
}


# convert a file containing key-value pairs to XML Properties
function kvFile_toXml()
{
    local kvfile="$1"
    local key=
    local val=

    for kv in $(cat $kvfile); do
        kv_toXml "$kv"
    done
    
    return 0
}

# tdh-env.sh