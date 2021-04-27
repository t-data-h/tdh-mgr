# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Set Hive and Hadoop environment variables here. These variables can be used
# to control the execution of Hive. It should be used by admins to configure
# the Hive installation (so that users do not have to set environment variables
# or set command line parameters to get correct behavior).
#
# The hive service being invoked (CLI etc.) is available via the environment
# variable SERVICE

export HIVE_CLIENT_HEAPSIZE=1024
export HIVE_METASTORE_HEAPSIZE=2048
export HIVE_SERVER2_HEAPSIZE=4096


if [ "$SERVICE" = "hiveserver2" ]; then
    
    export HADOOP_HEAPSIZE=$HIVE_SERVER2_HEAPSIZE
    if [ -n "$DEBUG" ]; then
        export HADOOP_OPTS="$HADOOP_OPTS -server -verbose:gc \
            -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps \
            -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/hive"
    fi

elif [ "$SERVICE" = "metastore" ]; then

    export HADOOP_HEAPSIZE=$HIVE_METASTORE_HEAPSIZE

elif [ "$SERVICE" = "cli" ]; then
    
    export HADOOP_HEAPSIZE=$HIVE_CLIENT_HEAPSIZE

    if [ -z "$DEBUG" ]; then
        export HADOOP_OPTS="$HADOOP_OPTS -XX:NewRatio=12 -Xmx1024m -Xms10m \
            -XX:MaxHeapFreeRatio=40 -XX:MinHeapFreeRatio=15 -XX:+useParNewGC -XX:-useGCOverheadLimit"
    else
        export HADOOP_OPTS="$HADOOP_OPTS -XX:NewRatio=12 -Xmx1204m -Xms10m \
            -XX:MaxHeapFreeRatio=40 -XX:MinHeapFreeRatio=15 -XX:-useGCOverheadLimit"
    fi
fi


# Set HADOOP_HOME to point to a specific hadoop install directory
HADOOP_HOME=/opt/TDH/hadoop

# Hive Configuration Directory can be controlled by:
# export HIVE_CONF_DIR=

# Folder containing extra libraries required for hive compilation/execution can be controlled by:
# export HIVE_AUX_JARS_PATH=
