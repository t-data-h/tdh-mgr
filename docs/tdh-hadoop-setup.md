TDH-HADOOP
===========

  TDH is a custom hadoop distribution with an initial configuration as a
pseudo-distributed cluster with 1 worker node. The distribution is based
entirely on direct apache versions. This project provides a set of scripts
for managing the environment.


### Building the Hadoop Distribution

  The ecosystem can be built using binary packages from the various
Apache projects or built from source. The supporting scripts and
instructions are based on building a distribution using the following
versions:

- Hadoop 2.7.x
- HBase  1.1.x - 1.2
- Hive   1.2.x
- Spark  1.6.x - 2.3.x
- Kafka  0.10.x

System Prerequisites: https://gist.github.com/tcarland/3d10c22885ec655a0c2435676c1ae7b1
Mysqld Configuration: https://gist.github.com/tcarland/64e300606d83782e4150ce2db053b733


#### Prerequisites
- **Oracle JDK 1.8**

 Note that this **must** be a JDK distribution, not JRE. Oracle is only needed
 by vendor distributions for the Strong Encryption security module.

- **Disable IPv6**

  There are known issues with Hadoop and IPv6 (especially with Ubuntu) and it is
  recommended to disable the IPv6 stack in the Linux Kernel.

  **sysctl.conf**
```
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```

- **Hadoop User and Group**

 The environment generally runs well as a single user, but for an actual
 distributed cluster create a hadoop user and group with a consistent UID and GID
 across systems.
 ```
 $ UID=xxx; GID=yyy
 $ groupadd -g $GID hadoop
 $ useradd -g -m -u $UID hadoop
 ```

- **Verify Networking**

  While it is functional to get services to run on localhost only (loopback), there
are some hacks involved for some services like Spark that traditionally have not
supported loopback. However, for development work, running on a laptop is nice,
but can suffer from not having a fixed available network interface and IP. The
easiest solution in such cases is to use a virtual interface.

  Additionally do NOT have the loopback entry in /etc/hosts set to the hostname.
Among the provided scripts, the 'hadoop-init.sh' script validates the configuration
prior to starting HDFS. Running either 'status' or 'start' will verify the detected
hostname configuration.

- **Configure SSH**

  SSH keyes are required for starting services (such as the secondary namenode).
```
    # su - hadoop
    $ ssh-keygen
    $ ssh-copy-id hadoop@myhost
# or
    $ cat .ssh/id_rsa.pub >> .ssh/authorized_keys
    $ chmod 600 !$
```

####  Installing Hadoop

  Choose a base path for the hadoop ecosystem. eg. /opt/tdh.  
From here, install the various ecosystem components complete with versions.

```
    # mkdir -p /opt/tdh && cd /opt/tdh
    # wget http://url/to/hadoop-2.7.1-bin.tar.gz
    # tar -zxvf hadoop-2.7.1.tar.gz
    # mv hadoop-2.7.1-bin hadoop-2.7.1
    # chown -R hadoop:hadoop hadoop-2.7.1
    # ln -s hadoop-2.7.1 hadoop
```

Use this pattern for other ecosystem components as well:
```
    $ ls -l /opt/tdh/
    lrwxrwxrwx 1 hadoop hadoop 12 Dec 29 12:44 hadoop -> hadoop-2.7.1
    drwxrwxr-x 10 hadoop hadoop 4096 Dec 29 13:07 hadoop-2.7.1
    lrwxrwxrwx 1 hadoop hadoop 11 Nov 7 20:38 hbase -> hbase-1.1.5
    drwxr-xr-x 8 hadoop hadoop 4096 Nov 6 11:38 hbase-1.1.5
    drwxr-xr-x 4 hadoop hadoop 4096 Nov 4 07:43 hdfs
    lrwxrwxrwx  1 hadoop hadoop   10 Feb 24 15:25 hive -> hive-1.2.1
    drwxr-xr-x  9 hadoop hadoop 4096 May  4 16:58 hive-1.2.1
    lrwxrwxrwx  1 hadoop hadoop    9 May  4 10:48 hue -> hue-4.1.0
    drwxr-xr-x 12 hadoop hadoop 4096 May  4 23:12 hue-4.1.0
    lrwxrwxrwx 1 hadoop hadoop 18 Nov 16 19:59 kafka -> kafka_2.11-0.10.2.0
    drwxr-xr-x 6 hadoop hadoop 4096 Nov 17 10:51 kafka_2.11-0.10.2.0
    lrwxrwxrwx 1 hadoop hadoop 11 Nov 19 11:05 spark -> spark-2.3.1
    drwxr-xr-x 12 hadoop hadoop 4096 Dec 2 10:23 spark-1.6.1
    lrwxrwxrwx 12 hadoop hadoop 4096 Dec 2 10:23 sqoop -> sqoop-1.99.6
    drwxr-xr-x 12 hadoop hadoop 4096 Dec 2 10:23 sqoop-1.99.6
    lrwxrwxrwx 12 hadoop hadoop 4096 Dec 2 10:23 zeppelin -> zeppelin-0.8.0
    drwxr-xr-x 12 hadoop hadoop 4096 Dec 2 10:23 zeppelin-0.8.0

```

#### Configuring Hadoop
 
 Update the configs in '/opt/tdh/hadoop/etc/hadoop'. Set JAVA_HOME  in the
***hadoop-env.sh*** file. This should be set to the Oracle JDK previously installed.

**core-site.xml:**

```
    <configuration>
        <property>
            <name>fs.default.name</name>
            <value>hdfs://hostname:8020</value>
        </property>
        <property>
            <name>hadoop.tmp.dir</name>
            <value>/var/tmp/hadoop/data</value>
        </property>
    </configuration>
```

**hdfs-site.xml:**

Choose a path for the Namenode and Datanode directories. Note that
the replication parameter must be set properly. Even though we are running
in distributed mode, this is still a single node so we do not want any
replication.

```
    <configuration>
        <property>
            <name>dfs.replication</name>
            <value>1</value>
        </property>
        <property>
            <name>dfs.name.dir</name>
            <value>file:///opt/tdh/hdfs/namenode</value>
        </property>
        <property>
            <name>dfs.data.dir</name>
            <value>file:///opt/tdh/hdfs/datanode</value>
        </property>
    </configuration>
```

**yarn-site.xml:**

```
    <configuration>
        <property>
            <name>yarn.resourcemanager.address</name>
            <value>hostname:8050</value>
        </property>
        <property>
            <name>yarn.resourcemanager.resource-tracker.address</name>
            <value>hostname:8025</value>
        </property>
        <property>
            <name>yarn.resourcemanager.scheduler.address</name>
            <value>hostname:8030</value>
        </property>
        <property>
            <name>yarn.nodemanager.aux-services</name>
            <value>mapreduce_shuffle</value>
        </property>
        <property>
            <name>yarn.nodemanager.aux-services.shuffle.class</name>
            <value>org.apache.hadoop.mapred.ShuffleHandler</value>
        </property>
    </configuration>
```

If intending to use Spark2.x and Dynamic Execution, then the external Spark Shuffle service should be configured:

```
<property>
  <name>yarn.nodemanager.aux-services</name>
  <value>mapreduce_shuffle,spark_shuffle</value>
</property>
<property>
  <name>yarn.nodemanager.aux-services.spark_shuffle.class</name>
  <value>org.apache.spark.network.yarn.YarnShuffleService</value>
</property>
```

#### Configuring the User Environment

This environment serves as example and can be added to a user's **.bashrc** file,
though I prefer to keep these in a separate env file like hadoop-env-user.sh which
can then be sourced from the .bashrc file. This also makes it easier to
share/use these settings with other users/accounts.

**.bashrc:**

```
if [ -f ~/hadoop-env-user.sh ]; then
    . ~/hadoop-env-user.sh
fi
```

**hadoop-env-user.sh:**

An example of this file is provided as *./etc/hadoop-env-user.sh*, and
would look something similar to the following:
```
# User oriented environment variables (for use with bash)

# The java implementation to use.
export JAVA_HOME=/usr/lib/jvm/oracle-jdk-bin-1.8

export HADOOP_ROOT="/opt/tdh"
export HADOOP_HOME="$HADOOP_ROOT/hadoop"

export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export HADOOP_COMMON_HOME="$HADOOP_HOME"
export HADOOP_HDFS_HOME="$HADOOP_COMMON_HOME"
export HADOOP_MAPRED_HOME="$HADOOP_COMMON_HOME"
export YARN_HOME="$HADOOP_COMMON_HOME"

export HBASE_HOME="$HADOOP_ROOT/hbase"
export HIVE_HOME="$HADOOP_ROOT/hive"
export KAFKA_HOME="$HADOOP_ROOT/kafka"
export SPARK_HOME="$HADOOP_ROOT/spark"
export OOZIE_HOME="$HADOOP_ROOT/oozie"

export HADOOP_PATH="\
$HADOOP_HOME/bin:\
$HBASE_HOME/bin:\
$HIVE_HOME/bin:\
$KAFKA_HOME/bin:\
$SPARK_HOME/bin"
```


#### Format the Namenode/Datanode

  Once the environment is setup, the **/opt/tdh/hadoop/bin/hadoop** binary should
be in the path. The following will format the name and datanodes as specified in
the **hdfs-site.xml**.
```
# mkdir -p /opt/hadoop/hdfs/namenode
# mkdir -p /opt/hadoop/hdfs/datanode
# sudo -u hadoop hadoop namenode -format
```

#### Start HDFS and Yarn

 Ensure various start scripts are run as the correct user if applicable
(eg. *sudo -i -u hadoop*).
```
$ $HADOOP_HOME/sbin/start-dfs.sh
$ $HADOOP_HOME/sbin/start-yarn.sh
```

Perform a quick test to verify that HDFS is working.
```
$ hdfs dfs -mkdir /user
$ hdfs dfs -ls /
```

#### Installing and Configuring HBase

This installation is fairly straightforward and follows the same pattern as earlier.

```
 $ cd /opt/tdh
 $ wget http://url/to/download/hbase-1.0.2-bin.tar.gz
 $ tar -zxvf hbase-1.1.5-bin.tar.gz
 $ mv hbase-1.1.5-bin hbase-1.1.5
 $ chown -R hadoop:hadoop hbase-1.1.5
 $ ln -s !$ hbase
```

 Set the *JAVA_HOME* variable in *$HBASE_HOME/conf/hbase-env.sh*. Then update
the *hbase-site.xml* file with the configuration below. Note that some of these
values are defaults and as such are not necessary, but are included for reference.

**hbase-site.xml:**
```
<configuration>
    <property>
        <name>hbase.master.port</name>
        <value>16000</value>
    </property>
    <property>
        <name>hbase.master.info.bindAddress</name>
        <value>10.10.10.60</value>
    </property>
    <property>
        <name>hbase.master.info.port</name>
        <value>16010</value>
    </property>
    <property>
        <name>hbase.regionserver.port</name>
        <value>16020</value>
    </property>
    <property>
        <name>hbase.regionserver.info.bindAddress</name>
        <value>10.10.10.60</value>
    </property>
    <property>
        <name>hbase.regionserver.info.port</name>
        <value>16030</value>
    </property>
    <property>
        <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>
    <property>
        <name>hbase.rootdir</name>
        <value>hdfs://host:8020/hbase</value>
    </property>
    <property>
        <name>hbase.zookeeper.quorum</name>
        <value>host</value>
    </property>
</configuration>
```

Use the script *$HBASE_HOME/bin/start-hbase.sh* and *$HBASE_HOME/bin/stop-hbase.sh*
to start and stop HBase respectively.  Note that HBase needs a running zookeeper,
which is done automatically. Since many other ecosystem components make use of
zookeeper, such as Spark and Kafka, it is important that HBase is started after
YARN and before other components. The hadoop-eco.sh script handles this properly.
Alternatively, Zookeeper can be installed and configured separately from HBase.

#### Installing and Configuring Spark (on YARN and Standalone)
```
$ cd /opt/tdh
$ wget http://url/to/spark-1.6.2-bin-hadoop2.6.tgz
$ tar -zxf spark-1.6.2-bin-hadoop2.6.tgz
$ rm !$
$ mv spark-1.6.2-bin-bin-hadoop2.6 spark-1.6.2
$ chown -R hadoop:hadoop !$
$ ln -s !$ spark
```

Configuring spark depends a bit on the requirements. The following configuration
options are simply an example and is not complete. You will likely want to tweak
the default number of worker cores, instances, and memory. Note that the settings
below applies primarily to a Spark Standalone configuration, however for Spark on
Yarn, there is no need to start the spark master. Additionally, there may be a
need to set *JAVA_HOME* and *SPARK_DIST_CLASSPATH* variables in *spark-env.sh*.
```
$ cd /opt/tdh/spark/conf
$ cp spark-env.sh.template spark-env.sh
$ cp spark-defaults.conf.template spark-defaults.conf
$ cp slaves.template slaves
$ cp log4j.properties.template log4j.properties
```

**spark-env.sh:**
```
export SPARK_DAEMON_JAVA_OPTS="-Dlog4j.configuration=file:///opt/tdh/spark/conf/log4j.pro
perties"
export SPARK_DIST_CLASSPATH=$(/opt/tdh/hadoop/bin/hadoop classpath)

# for standalone mode
export SPARK_MASTER_IP="localhost"
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080

export SPARK_EXECUTOR_INSTANCES=1
export SPARK_EXECUTOR_CORES=2
export SPARK_EXECUTOR_MEMORY="1g"

export SPARK_WORKER_DIR=/var/tmp/spark/work
export SPARK_LOCAL_DIRS=/var/tmp/spark
export SPARK_DAEMON_MEMORY=1g
```

**spark-defaults.conf:**
```
spark.serializer                                org.apache.spark.serializer.KryoSerializer
spark.streaming.receiver.writeAheadLog.enable   true
spark.streaming.backpressure.enabled            true
spark.eventLog.enabled                          true
spark.executor.memory                           1g
#spark.streaming.receiver.maxRate               0
#spark.streaming.kavak.maxRatePerPartition      0
```


#### Testing the Spark Installation

To test running a spark job on YARN, try the following spark example:
```
$SPARK_HOME/bin/spark-submit --class org.apache.spark.examples.SparkPi \
    --master yarn \
    --deploy-mode cluster \
    --num-executors 1 \
    --executor-cores 2 \
    lib/spark-examples*.jar \
    100
```

Check the YARN UI *http://host:8088/*

Jobs can be submitted directy to the spark master as well and viewed via the Spark UI at ***http://host:8080/***
```
  $SPARK_HOME/bin/spark-submit --class org.apache.spark.examples.SparkPi \
    --master spark://$host:7077 \
    --num-executors 1 \
    --executor-cores 2 \
    lib/spark-examples*.jar \
    100
```

For running *spark-shell* or *pyspark* use the '*--master*' switch with either
**yarn** as the target or the spark master URL.
```
pyspark --master spark://$host:7077
```

#### Spark 2.x.x

The following is a sample configuration for *spark-defaults.conf* and
*spark-env.sh* intended for Spark2.

**spark-defaults.conf**
```
spark.master=yarn
spark.submit.deployMode=client
spark.ui.killEnabled=true
spark.serializer=org.apache.spark.serializer.KryoSerializer

spark.eventLog.enabled=true
spark.eventLog.dir=hdfs://thebe:8020/tmp/spark
spark.yarn.historyServer.address=http://thebe:18088
spark.history.fs.logDirectory=hdfs://thebe:8020/tmp/spark

#spark.sql.hive.metastore.jars=${HIVE_HOME}/lib/*
#spark.sql.hive.metastore.version=1.1.0
#spark.sql.catalogImplementation=hive
#spark.yarn.jars=local:/opt/hadoop/spark/jars/*

spark.driver.extraLibraryPath=${HADOOP_COMMON_HOME}/lib/native
spark.executor.extraLibraryPath=${HADOOP_COMMON_HOME}/lib/native
spark.yarn.am.extraLibraryPath=${HADOOP_COMMON_HOME}/lib/native
spark.hadoop.mapreduce.application.classpath=
spark.hadoop.yarn.application.classpath=

spark.driver.memory=1g
spark.executor.memory=1g
```

**spark-env.sh:**
```
export STANDALONE_SPARK_MASTER_HOST=`hostname`
export SPARK_MASTER_IP=$STANDALONE_SPARK_MASTER_HOST

if [ -z "$SPARK_HOME" ]; then
    SELF="$(cd $(dirname $BASH_SOURCE) && pwd)"
    if [ -z "$SPARK_CONF_DIR" ]; then
        export SPARK_CONF_DIR="$SELF"
    fi
    export SPARK_HOME="/opt/hadoop/spark"
fi

SPARK_PYTHON_PATH=""
if [ -n "$SPARK_PYTHON_PATH" ]; then
  export PYTHONPATH="$PYTHONPATH:$SPARK_PYTHON_PATH"
fi

if [ -z "$HADOOP_HOME" ]; then
    export HADOOP_HOME="/opt/hadoop/hadoop"
fi

if [ -n "$HADOOP_HOME" ]; then
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${HADOOP_HOME}/lib/native
fi
export LD_LIBRARY_PATH

PYLIB="$SPARK_HOME/python/lib"
if [ -f "$PYLIB/pyspark.zip" ]; then
  PYSPARK_ARCHIVES_PATH=
  for lib in "$PYLIB"/*.zip; do
    if [ -n "$PYSPARK_ARCHIVES_PATH" ]; then
      PYSPARK_ARCHIVES_PATH="$PYSPARK_ARCHIVES_PATH,local:$lib"
    else
      PYSPARK_ARCHIVES_PATH="local:$lib"
    fi
  done
  export PYSPARK_ARCHIVES_PATH
fi

export SPARK_LIBRARY_PATH=${SPARK_HOME}/jars
export SPARK_MASTER_WEBUI_PORT=18080
export SPARK_MASTER_PORT=7077
export SPARK_WORKER_PORT=7078
export SPARK_WORKER_WEBUI_PORT=18081
export SPARK_WORKER_DIR=/var/run/spark/work
export SPARK_LOG_DIR=/var/log/spark
export SPARK_PID_DIR='/var/run/spark/'

export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-/etc/hadoop/conf}

if [[ -d $SPARK_HOME/python ]]
then
    for i in
    do
        SPARK_DIST_CLASSPATH=${SPARK_DIST_CLASSPATH}:$i
    done
fi

SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:$SPARK_LIBRARY_PATH/*"
SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:$(/opt/hadoop/hadoop/bin/hadoop classpath)"
SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:$HBASE_CONF_DIR:$HBASE_HOME/lib/*"
SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:$HIVE_HOME/conf/hive-site.xml:$HIVE_HOME/lib/*"
SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:$KAFKA_HOME/libs/*"
echo "SPARK_DIST_CLASSPATH=\"$SPARK_DIST_CLASSPATH\""
```

#### Spark2 Dynamic Allocation

This is a nice feature, especially with constrained resources and notebook users.
To enable dynamic allocation, the external spark shuffle service must be added to YARN.

yarn-site.xml:
```
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>spark_shuffle,mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services.spark_shuffle.class</name>
    <value>org.apache.spark.network.yarn.YarnShuffleService</value>
  </property>
```

spark-defaults.conf
```
spark.authenticate=false
spark.dynamicAllocation.enabled=true
spark.dynamicAllocation.executorIdleTimeout=60
spark.dynamicAllocation.minExecutors=0
spark.dynamicAllocation.schedulerBacklogTimeout=1
spark.shuffle.service.enabled=true
spark.shuffle.service.port=7337
```

#### Installing and Configuring Kafka
```
$ cd /opt/tdh
$ wget https://www.apache.org/dyn/closer.cgi?path=/kafka/0.8.2.2/kafka_2.11-0.8.2.2.tgz
$ tar -zxf kafka_2.11-0.8.2.2.tgz
$ rm !$
$ ln -s kafka_2.11-0.8.2.2 kafka
$ chown -R hadoop:hadoop kafka_2.11-0.8.2.2
```

For the configuration, Kafka comes out of the package, mostly ready for a single
node setup. Nonetheless, it would be good to peruse the various configurations in
the 'config' directory. For one, set the zookeeper.connect string in the
*consumer.properties*:
```
zookeeper.connect=10.10.10.11:2181
```

Additionally, verify the settings in *server.properties* are sane for your system.
Once complete, the Kafka service can be started by running the following command.
```
sudo -u hadoop $KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties &
```


#### Installing and Configuring Hive

* Install Mysql

* Create metastore database

* Locate schema $HIVE_HOME/scripts/metastore/upgrade/mysql/hive-schema-x.x.x.mysql.sql
   edit and search for the txn-schema file to update fully-qualified path.

* source schema

* configure hive-site.xml

```
<configuration>
  <property>
     <name>mapred.reduce.tasks</name>
     <value>-1</value>
     <description>The default number of reduce tasks per job.</description>
  </property>

  <property>
     <name>hive.exec.scratchdir</name>
     <value>/tmp/hive</value>
     <description>Scratch space for Hive jobs</description>
  </property>

  <property>
     <name>hive.metastore.warehouse.dir</name>
     <value>/user/hive/warehouse</value>
     <description>location of default database for the warehouse</description>
  </property>

  <property>
     <name>hive.enforce.bucketing</name>
     <value>true</value>
     <description>Whether bucketing is enforced. If true, while inserting into the table, bu
cketing is enforced. </description>
  </property>

  <property>
     <name>hive.hwi.war.file</name>
     <value>lib/hive-hwi-1.2.1.jar</value>
     <description>This sets the path to the HWI  file, relative to${HIVE_HOME}</description>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://dbhost/metastore?createDatabaseIfNotExist=true</value>
    <description>JDBC connect string for a JDBC metastore</description>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>com.mysql.jdbc.Driver</value>
    <description>Driver class name for a JDBC metastore</description>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hive</value>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>hivesql</value>
  </property>

  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://hostname:9083</value>
    <description>IP address (or fqdn) and port of the metastore host</description>
  </property>

  <property>
    <name>datanucleus.fixedDatastore</name>
    <value>true</value>
  </property>

  <property>
    <name>datanucleus.autoCreateSchema</name>
    <value>false</value>
  </property>

</configuration>
```

test with:

```
./bin/hive -hiveconf hive.root.logger=DEBUG,console
```

* Start the MetaStore via

```
$HIVE_HOME/bin/hive --service metastore
```

Note that this does not daemonize properly, so a better way might be to use nohup
```
nohup $HIVE_HOME/bin/hive --service metastore > /var/tmp/hivemetastore.log
```
