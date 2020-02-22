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

NS_NAME=$( grep -A1 'dfs.nameservices' ${HDFS_CONF} | \
  grep value | \
  sed -E 's/.*<value>(.*)<\/valude>/\1/' 2>/dev/null )

if [ -n "$NS_NAME" ]; then
    SN_HOST=$( grep -A1 'dfs.namenode.http-address' ${HDFS_CONF} | \
      grep -A1 'nn2' | grep value | \
      sed -E 's/.*<value>(.*)<\/value>/\1/' | \
      awk -F':' '{ print $1 }' )
else
    SN_HOST=$( grep -A1 'dfs.namenode.secondary' ${HDFS_CONF} | \
      grep value | \
      sed -E 's/.*<value>(.*)<\/value>/\1/' | \
      awk -F':' '{ print $1 }' )
fi


( $HADOOP_HDFS_HOME/bin/hdfs namenode -format )

rt=$?
if [ $rt -ne 0 ]; then
    echo "$TDH_NAME : Error during namenode format, aborting.."
    exit $rt
fi

if [ -n "$NS_NAME" ]; then 
    ( ssh $SN_HOST "$HADOOP_HDFS_HOME/bin/hdfs namenode -bootstrapStandby" )
    rt=$?
fi

echo "$TDH_PNAME Finished."

exit $rt


