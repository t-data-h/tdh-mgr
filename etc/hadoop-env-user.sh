#!/bin/bash
#  hadoop-env-user.sh
#  Sets up the environment for TDH components.
#
#  Timothy C. Arland <tcarland@gmail.com>

export HADOOP_ENV_USER=1
export HADOOP_ENV_USER_VERSION="0.516"


# Assume that JAVA_HOME is already set or managed by the system.
#export JAVA_HOME=${JAVA_HOME}
if [ -z "$JAVA_HOME" ]; then
    echo "Error JAVA_HOME is not set"
    exit 1
fi

# HADOOP_CONF_DIR should always be set by user prior to sourcing the Environment
# to support switching environments.
if [ -z "$HADOOP_CONF_DIR" ]; then
    echo "Warning! HADOOP_CONF_DIR is not set!"
    export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
    echo "=> Setting default HADOOP_CONF_DIR=${HADOOP_CONF_DIR}"
fi

export HADOOP_USER="tca"
export HADOOP_ROOT="/opt/hadoop"
export HADOOP_HOME="$HADOOP_ROOT/hadoop"
export HADOOP_LOGDIR="/var/log/hadoop"

# Set components home
export HADOOP_COMMON_HOME="$HADOOP_HOME"
export HADOOP_HDFS_HOME="$HADOOP_COMMON_HOME"
export HADOOP_MAPRED_HOME="$HADOOP_COMMON_HOME"
export YARN_HOME="$HADOOP_COMMON_HOME"
export HBASE_HOME="$HADOOP_ROOT/hbase"
export HBASE_CONF_DIR="$HBASE_HOME/conf"
export HIVE_HOME="$HADOOP_ROOT/hive"
export KAFKA_HOME="$HADOOP_ROOT/kafka"
export SPARK_HOME="$HADOOP_ROOT/spark"

# bin path
export HADOOP_PATH="\
$HADOOP_ROOT/bin:\
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
