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

SPARK_PATH=$(readlink -f $SPARK_HOME)

if ! [ -d $SPARK_PATH ]; then
    echo "Error determining real path to SPARK_HOME: $SPARK_HOME"
    exit 1
fi

SPARK_JAR=$(ls -1 $SPARK_PATH/yarn/*shuffle*.jar)
YARN_LINK=$(ls -1 $HADOOP_HOME/share/hadoop/yarn/lib/*shuffle*.jar 2> /dev/null)
YARN_JAR=$(readlink -f $YARN_LINK 2> /dev/null)

if [ -z "$SPARK_JAR" ]; then
    echo "Fatal Error locating the Spark Shuffle JAR"
    exit 1
fi

if [ "$YARN_JAR" == "$SPARK_JAR" ]; then
    echo "Spark External Shuffle Jar for YARN is already linked to: "
    echo "  $SPARK_JAR"
else
    if [ -n "$YARN_LINK" ]; then
        ( rm $YARN_LINK )
    fi
    echo "Spark External Shuffle Jar for YARN is now linked."
    ( ln -s $SPARK_JAR $HADOOP_HOME/share/hadoop/yarn/lib )
fi

echo "$PNAME Finished."
exit 0
