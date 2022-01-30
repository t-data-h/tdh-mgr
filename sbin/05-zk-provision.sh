#!/bin/bash
#
#  Ensure Zookeeper Id's are configured properly.
#

# ----------- preamble
HADOOP_ENV="tdh-env.sh"

if [ -z "$JAVA_HOME" ]; then
    if [ -e '/etc/profile.d/jdk.sh' ]; then
        . /etc/profile.d/jdk.sh
    fi
fi

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "/opt/TDH/etc/$HADOOP_ENV" ]; then
    . /opt/TDH/etc/$HADOOP_ENV
elif [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then
    . $HOME/hadoop/etc/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'" >&2
    exit 1
fi

# -----------

host=$(hostname -s)
zk=$(grep $host $ZOOKEEPER_HOME/conf/zoo.cfg 2>/dev/null)
dataDir=$(grep 'dataDir' $ZOOKEEPER_HOME/conf/zoo.cfg | awk -F= '{ print $2 }')
zkid=

if [ -z "$zk" ]; then
    echo "$TDH_PNAME Error, Zookeeper not found for '$host'" >&2
    exit 0
fi

if [ -z "$dataDir" ]; then
    echo "$TDH_PNAME Error, ZooKeeper dataDir config not found!" >&2
    exit 1
fi

if [[ $zk =~ ^server\.([0-9]).* ]]; then
    zkid=${BASH_REMATCH[1]}
fi

if [ -z "$zkid" ]; then
    echo "$TDH_PNAME Error, ZooKeeper ID not configured." >&2
    exit 1
fi

if [[ $zkid =~ ^[0-9]+$ ]]; then
    echo "$TDH_PNAME Setting ZooKeeper Id for '$host' to '$zkid'"
else
    echo "$TDH_PNAME Error, ZooKeeper ID is invalid" >&2
    exit 1
fi

( echo "$zkid" > ${dataDir}/myid )

echo "$TDH_PNAME Finished."
exit 0
