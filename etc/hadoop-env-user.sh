#!/bin/bash
#  hadoop-env-user.sh
#  Sets up the environment for TDH components.
#
#  Timothy C. Arland <tcarland@gmail.com>

export HADOOP_ENV_USER=1
export HADOOP_ENV_USER_VERSION="0.514"


# This should already be set
#export JAVA_HOME=${JAVA_HOME}
if [ -z "$JAVA_HOME" ]; then
    echo "Error JAVA_HOME is not set"
    exit 1
fi

export HADOOP_USER="tca"
export HADOOP_ROOT="/opt/hadoop"
export HADOOP_HOME="$HADOOP_ROOT/hadoop"
export HADOOP_LOGDIR="/var/log/hadoop"

# HADOOP_CONF_DIR should be set by user
#export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"

# Set component homes
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

# Classpath set by $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Kafka
if [ -f "/etc/kafka/jaas.conf" ]; then
    export KAFKA_OPTS="-Djava.security.auth.login=/etc/kafka/jaas.conf"
fi
if [ -f "/etc/kafka/conf/kafka-client.conf" ]; then
    export ZKS=$( cat /etc/kafka/conf/kafka-client.conf | awk -F '=' '{ print $2 }' )
fi

# -----------------------------------------------
#  NOTE:  Do not add or change below this line!
#
if [ "$LD_LIBRARY_PATH" ]; then
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native"
else
    export LD_LIBRARY_PATH="$HADOOP_HOME/lib/native"
fi

if [ "$HADOOP_PATH" ]; then
    if [ "$PATH" ]; then
        export PATH="$PATH:$HADOOP_PATH"
    else
        export PATH="$HADOOP_PATH"
    fi
fi
