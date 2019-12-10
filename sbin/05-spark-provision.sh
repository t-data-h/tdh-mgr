#!/bin/bash
#
#  Ensure Spark's External Shuffle is configured properly
#

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"

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
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
# -----------

SPARK_PATH=$(readlink -f $SPARK_HOME)
rt=1

# -----------

if ! [ -d $SPARK_PATH ]; then
    echo "Error determining path to SPARK_HOME: $SPARK_HOME"
    exit $rt
fi


SPARK_JAR=$(ls -1 $SPARK_PATH/yarn/*shuffle*.jar)
YARN_LINK=$(ls -1 $HADOOP_HOME/share/hadoop/yarn/lib/*shuffle*.jar 2> /dev/null)
YARN_JAR=$(readlink -f $YARN_LINK 2> /dev/null)


if [ -z "$SPARK_JAR" ]; then
    echo "Fatal Error locating the Spark Shuffle JAR"
    exit $rt
fi

# -----------

echo "$TDH_PNAME validating the Spark External Shuffle Jar for YARN..."
echo ""

if [ "$YARN_JAR" == "$SPARK_JAR" ]; then
    echo "Spark External Shuffle Jar for YARN is already linked to: "
    echo "  $SPARK_JAR"
else
    if [ -n "$YARN_LINK" ]; then
        ( rm $YARN_LINK )
    fi

    echo "( ln -s $SPARK_JAR $HADOOP_HOME/share/hadoop/yarn/lib )"
    ( ln -s $SPARK_JAR $HADOOP_HOME/share/hadoop/yarn/lib )

    rt=$?
    if [ $rt -ne 0 ]; then
        echo "Error in creating link"
    else
        echo "Spark External Shuffle Jar for YARN is now linked."
    fi
fi

echo "$TDH_PNAME Finished."
exit 0
