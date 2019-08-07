#!/bin/bash
#
#  Ensure Spark's External Shuffle is configured properly
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"

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
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
# -----------

host=$(hostname -s)
broker=$(cat $KAFKA_HOME/config/brokers | grep $host)
brokerid=

if [ -z "$broker" ]; then
    echo "Broker Id not found for $host"
    exit 1
fi

if [[ $broker =~ ^.*\ .*$ ]]; then
    brokerid=${broker##* }
fi
broker=${broker%% *}

if [ -z "$brokerid" ]; then
    echo "Warning! Broker ID not configured"
    exit 1
fi

if [[ $brokerid =~ ^[0-9]+$ ]]; then
    echo "Setting Broker Id for '$broker' to '$brokerid'"
else
    echo "Broker ID is invalid"
    exit 1
fi

echo "( sed -i "s/\(^broker.id=\).*/\1$brokerid/" $KAFKA_HOME/config/server.properties )"
( sed -i "s/\(^broker.id=\).*/\1$brokerid/" $KAFKA_HOME/config/server.properties )

exit 0
