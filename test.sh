#!/bin/bash
#
#  Timothy C. Arland <tcarland@gmail.com>
#
PNAME=${0##*\/}


# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "/opt/TDH/etc/$HADOOP_ENV" ]; then
    . /opt/TDH/etc/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi

HADOOP_VER=$(readlink $HADOOP_HOME)


for x in $(cat ${HADOOP_HOME}/etc/hadoop/slaves); do
    echo "datanode: $x"
done


exit 0
