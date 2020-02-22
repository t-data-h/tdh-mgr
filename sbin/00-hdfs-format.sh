#!/bin/bash
#
#  Initial Namenode format. Will also detect HA NN 
#  Settings and format Zookeeper for the failover controller.
#
#  @Author  Timothy C. Arland <tcarland@gmail.com>
#  

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"
HADOOP_ENV_PATH="/opt/TDH/etc"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
    HADOOP_ENV_PATH="./etc"
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
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

HOST=$( hostname -s )
MASTERS="${HADOOP_CONF_DIR}/masters"
NS_NAME=$($HADOOP_HOME/bin/hdfs getconf -confKey 'dfs.nameservices' 2>/dev/null)
NNS=$(${HADOOP_HOME}/bin/hdfs getconf -namenodes 2>/dev/null)
NN1=$(echo $NNS | awk '{ print $1 }')
NN2=$(echo $NNS | awk '{ print $2 }')
JNS=$(cat $MASTERS 2>/dev/null)

if [ "$NN1" != "$HOST" ]; then
    echo "$TDH_PNAME Error: Host '$HOST' not the Namenode '$NN1'"
    exit 1
fi

if [ -n "$NS_NAME" ]; then
    if [ -z "$JNS" ]; then
        echo "$TDH_PNAME Error determining Journal Nodes"
        exit 1
    fi

    if [ -z "$NN2" ]; then 
        echo "$TDH_PNAME Error determining Standby Namenode"
        exit 1
    fi

    # Ensure Journal Nodes and Zookeepers are started first
    ( $HADOOP_ROOT/bin/hadoop-init.sh start journal )
    ( $HADOOP_ROOT/bin/zookeeper-init.sh start )

    # Format ZK node
    ( $HADOOP_HOME/bin/hdfs zkfc -formatZK )

    # Start ZKFC service
    ( $HADOOP_HOME/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR \
      --script "$HADOOP_HOME/bin/hdfs" start zkfc )
fi

# Format the Namenode
( $HADOOP_HOME/bin/hdfs namenode -format )

rt=$?
if [ $rt -ne 0 ]; then
    echo "$TDH_NAME : Error during namenode format, aborting.."
    exit $rt
fi

# Set up HA
if [ -n "$NS_NAME" ]; then
    # Start the first Namenode
    ( $HADOOP_HOME/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR \
      --script $HADOOP_HOME/bin/hdfs start namenode )
    ( sleep 5 )

    # Bootstrap secondary
    ( ssh $NN2 "$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby" )
    rt=$?

    # Start the second Namenode
    if [ $rt -eq 0 ]; then
        ( ssh $NN2 "$HADOOP_HOME/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR \
          --script $HADOOP_HOME/bin/hdfs start namenode" )
    fi
fi

echo "$TDH_PNAME Finished."

exit $rt
