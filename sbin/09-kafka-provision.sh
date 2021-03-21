#!/bin/bash
#
#  Ensure Kafka Broker Id's are configured properly.
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
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
# -----------

host=$(hostname -s)
broker=$(cat $KAFKA_HOME/config/brokers | grep $host 2>/dev/null)
brokerid=

if [ -z "$broker" ]; then
    echo "$TDH_PNAME Error, Broker Id not found for $host"
    exit 0
fi

if [[ $broker =~ ^.*\ .*$ ]]; then
    brokerid=${broker##* }
fi
broker=${broker%% *}

if [ -z "$brokerid" ]; then
    echo "$TDH_PNAME Error, Broker ID not configured"
    exit 1
fi

if [[ $brokerid =~ ^[0-9]+$ ]]; then
    echo "$TDH_PNAME Setting Broker Id for '$broker' to '$brokerid'"
else
    echo "$TDH_PNAME Error, Broker ID is invalid"
    exit 1
fi

echo "( sed -i "s/\(^broker.id=\).*/\1$brokerid/" $KAFKA_HOME/config/server.properties )"
( sed -i "s/\(^broker.id=\).*/\1$brokerid/" $KAFKA_HOME/config/server.properties )

echo "$TDH_PNAME Finished."
exit 0
