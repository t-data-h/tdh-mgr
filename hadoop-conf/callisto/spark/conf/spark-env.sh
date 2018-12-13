#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This file is sourced when running various Spark programs.
# Copy it as spark-env.sh and edit that to configure Spark for your site.

# Options read when launching programs locally with
# ./bin/run-example or ./bin/spark-submit
# - HADOOP_CONF_DIR, to point Spark towards Hadoop configuration files
# - SPARK_LOCAL_IP, to set the IP address Spark binds to on this node
# - SPARK_PUBLIC_DNS, to set the public dns name of the driver program
# - SPARK_CLASSPATH, default classpath entries to append

# Options read by executors and drivers running inside the cluster
# - SPARK_LOCAL_IP, to set the IP address Spark binds to on this node
# - SPARK_PUBLIC_DNS, to set the public DNS name of the driver program
# - SPARK_CLASSPATH, default classpath entries to append
# - SPARK_LOCAL_DIRS, storage directories to use on this node for shuffle and RDD data
# - MESOS_NATIVE_JAVA_LIBRARY, to point to your libmesos.so if you use Mesos

# Options read in YARN client mode
# - HADOOP_CONF_DIR, to point Spark towards Hadoop configuration files
# - SPARK_EXECUTOR_INSTANCES, Number of executors to start (Default: 2)
# - SPARK_EXECUTOR_CORES, Number of cores for the executors (Default: 1).
# - SPARK_EXECUTOR_MEMORY, Memory per Executor (e.g. 1000M, 2G) (Default: 1G)
# - SPARK_DRIVER_MEMORY, Memory for Driver (e.g. 1000M, 2G) (Default: 1G)

# Options for the daemons used in the standalone deploy mode
# - SPARK_MASTER_HOST, to bind the master to a different IP address or hostname
# - SPARK_MASTER_PORT / SPARK_MASTER_WEBUI_PORT, to use non-default ports for the master
# - SPARK_MASTER_OPTS, to set config properties only for the master (e.g. "-Dx=y")
# - SPARK_WORKER_CORES, to set the number of cores to use on this machine
# - SPARK_WORKER_MEMORY, to set how much total memory workers have to give executors (e.g. 1000m, 2g)
# - SPARK_WORKER_PORT / SPARK_WORKER_WEBUI_PORT, to use non-default ports for the worker
# - SPARK_WORKER_INSTANCES, to set the number of worker processes per node
# - SPARK_WORKER_DIR, to set the working directory of worker processes
# - SPARK_WORKER_OPTS, to set config properties only for the worker (e.g. "-Dx=y")
# - SPARK_DAEMON_MEMORY, to allocate to the master, worker and history server themselves (default: 1g).
# - SPARK_HISTORY_OPTS, to set config properties only for the history server (e.g. "-Dx=y")
# - SPARK_SHUFFLE_OPTS, to set config properties only for the external shuffle service (e.g. "-Dx=y")
# - SPARK_DAEMON_JAVA_OPTS, to set config properties for all daemons (e.g. "-Dx=y")
# - SPARK_PUBLIC_DNS, to set the public dns name of the master or workers

# Generic options for the daemons used in the standalone deploy mode
# - SPARK_CONF_DIR      Alternate conf dir. (Default: ${SPARK_HOME}/conf)
# - SPARK_LOG_DIR       Where log files are stored.  (Default: ${SPARK_HOME}/logs)
# - SPARK_PID_DIR       Where the pid file is stored. (Default: /tmp)
# - SPARK_IDENT_STRING  A string representing this instance of spark. (Default: $USER)
# - SPARK_NICENESS      The scheduling priority for daemons. (Default: 0)

SPARK_MASTER_HOST="10.10.10.60"
SPARK_WORKER_CORES="4"

export STANDALONE_SPARK_MASTER_HOST=`hostname`
export SPARK_MASTER_IP=$STANDALONE_SPARK_MASTER_HOST

if [ -z "$SPARK_HOME" ]; then
    SELF="$(cd $(dirname $BASH_SOURCE) && pwd)"
    if [ -z "$SPARK_CONF_DIR" ]; then
        export SPARK_CONF_DIR="$SELF"
    fi
    export SPARK_HOME="/opt/hadoop/spark"
fi

SPARK_PYTHON_PATH=""
if [ -n "$SPARK_PYTHON_PATH" ]; then
  export PYTHONPATH="$PYTHONPATH:$SPARK_PYTHON_PATH"
fi

if [ -z "$HADOOP_HOME" ]; then
    export HADOOP_HOME="/opt/hadoop/hadoop"
fi

if [ -n "$HADOOP_HOME" ]; then
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${HADOOP_HOME}/lib/native
fi
export LD_LIBRARY_PATH

PYLIB="$SPARK_HOME/python/lib"
if [ -f "$PYLIB/pyspark.zip" ]; then
  PYSPARK_ARCHIVES_PATH=
  for lib in "$PYLIB"/*.zip; do
    if [ -n "$PYSPARK_ARCHIVES_PATH" ]; then
      PYSPARK_ARCHIVES_PATH="$PYSPARK_ARCHIVES_PATH,local:$lib"
    else
      PYSPARK_ARCHIVES_PATH="local:$lib"
    fi
  done
  export PYSPARK_ARCHIVES_PATH
fi

export SPARK_LIBRARY_PATH=${SPARK_HOME}/jars
export SPARK_MASTER_WEBUI_PORT=18080
export SPARK_MASTER_PORT=7077
export SPARK_WORKER_PORT=7078
export SPARK_WORKER_WEBUI_PORT=18081
export SPARK_WORKER_DIR=/var/run/spark/work
export SPARK_LOG_DIR=/var/log/hadoop/spark
export SPARK_PID_DIR=/tmp

export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-/etc/hadoop/conf}

if [[ -d $SPARK_HOME/python ]]
then
    for i in 
    do
        SPARK_DIST_CLASSPATH=${SPARK_DIST_CLASSPATH}:$i
    done
fi

# spark
SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:$SPARK_LIBRARY_PATH/*"
# hadoop
SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:$(/opt/hadoop/hadoop/bin/hadoop classpath)"
# hbase
SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:$HBASE_CONF_DIR:$HBASE_HOME/lib/*"
# hive
SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:$HIVE_HOME/conf/hive-site.xml:$HIVE_HOME/lib/*"
# kafka
SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:$KAFKA_HOME/libs/*"
#echo "SPARK_DIST_CLASSPATH=\"$SPARK_DIST_CLASSPATH\""

