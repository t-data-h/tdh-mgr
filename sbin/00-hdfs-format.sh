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
NS_NAME=$($HADOOP_HOME/bin/hdfs getconf -confKey 'dfs.nameservices' 2>/dev/null)
JN_EDITS=$($HADOOP_HOME/bin/hdfs getconf -confKey dfs.namenode.shared.edits.dir 2>&-)
NNS=$(${HADOOP_HOME}/bin/hdfs getconf -namenodes 2>/dev/null)
JNS=$(echo "$JN_EDITS" | sed 's,qjournal://\([^/]*\)/.*,\1,g; s/;/ /g; s/:[0-9]*//g')
NN1=$(echo $NNS | awk '{ print $1 }')
NN2=$(echo $NNS | awk '{ print $2 }')

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

    sleep 5

    # Format ZK node
    echo " -> Format ZK node for ZKFC"
    ( $HADOOP_HOME/bin/hdfs zkfc -formatZK )
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

    sleep 5

    # Start 1st ZKFC service
    ( $HADOOP_HOME/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR \
      --script "$HADOOP_HOME/bin/hdfs" start zkfc )

    # Bootstrap secondary
    ( ssh $NN2 "$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby" )
    rt=$?

    # Start the second Namenode
    if [ $rt -eq 0 ]; then
        ( ssh $NN2 "$HADOOP_HOME/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR \
          --script $HADOOP_HOME/bin/hdfs start namenode" )
        sleep 3
        # Start 2nd ZKFC service
        ( ssh $NN2 "$HADOOP_HOME/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR \
            --script $HADOOP_HOME/bin/hdfs start zkfc" )
    fi
fi

echo "$TDH_PNAME Finished."

exit $rt
