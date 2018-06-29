#!/bin/bash
#  hadoop-env-user.sh
#  Sets up PATH for various ecosystem components
#
#  Timothy C. Arland <tcarland@gmail.com>

export HADOOP_ENV_USER=1
export HADOOP_ENV_USER_VERSION="0.314"


# Assuming this is already set
#export JAVA_HOME=${JAVA_HOME}

export HADOOP_USER="tca"
export HADOOP_ROOT="/opt/hadoop"
export HADOOP_HOME="$HADOOP_ROOT/hadoop"
export HADOOP_LOGDIR="/var/log/hadoop"


# assume HADOOP_CONF_DIR is set elsewhere
#export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"

export HADOOP_COMMON_HOME="$HADOOP_HOME"
export HADOOP_HDFS_HOME="$HADOOP_COMMON_HOME"
export HADOOP_MAPRED_HOME="$HADOOP_COMMON_HOME"
export YARN_HOME="$HADOOP_COMMON_HOME"

# ecosystem components
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

# hadoop ecosystem classpath
#export HADOOP_CLASSPATH="\
#$HBASE_CONF_DIR:\
#$HBASE_HOME/lib/*:\
#$HIVE_HOME/lib/*:\
#$KAFKA_HOME/libs/*:\
#$SPARK_HOME/lib/*"


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


