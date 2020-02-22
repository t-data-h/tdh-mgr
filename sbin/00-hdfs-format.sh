#!/bin/bash
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
MASTERS="${HADOOP_HOME}/etc/hadoop/masters"
HDFS_CONF="${HADOOP_HOME}/etc/hadoop/hdfs-site.xml"
JNS=$(cat $MASTERS 2>/dev/null)

NS_NAME=$( grep -A1 'dfs.nameservices' ${HDFS_CONF} | \
  grep value | \
  sed -E 's/.*<value>(.*)<\/valude>/\1/' 2>/dev/null )

if [ -n "$NS_NAME" ]; then
    SN_HOST=$( grep -A1 'dfs.namenode.http-address' ${HDFS_CONF} | \
      grep -A1 'nn2' | grep value | \
      sed -E 's/.*<value>(.*)<\/value>/\1/' | \
      awk -F':' '{ print $1 }' )

      if [ -z "$JNS" ]; then
          echo "$TDH_PNAME Error determining Journal Nodes"
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
else
    SN_HOST=$( grep -A1 'dfs.namenode.secondary' ${HDFS_CONF} | \
      grep value | \
      sed -E 's/.*<value>(.*)<\/value>/\1/' | \
      awk -F':' '{ print $1 }' )
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
      --script "$HADOOP_HOME/bin/hdfs" start namenode )
    ( sleep 3 )

    # Bootstrap secondary
    ( ssh $SN_HOST "$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby" )
    rt=$?

    # Start the second Namenode
    if [ $rt -eq 0 ]; then
        ( ssh $SN_HOST "$HADOOP_HOME/sbin/hadoop-daemon.sh --config /etc/hadoop/conf \
          --script /opt/TDH/hadoop/bin/hdfs start namenode" )
    fi
fi

echo "$TDH_PNAME Finished."

exit $rt
