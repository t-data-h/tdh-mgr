TDH-HADOOP
===========

  TDH is a custom hadoop distribution with an initial configuration as a
pseudo-distributed cluster with 1 worker node. The distribution is based
entirely on Apache versions. This project provides a set of scripts
for managing the environment. Note that much of this document describing
the TDH setup is automated through a separate project via Ansible
called *tdh-gcp*, so while somewhat deprecated, it remains for informational
purposes.


## Building the Hadoop Distribution

  The ecosystem can be built using binary packages from the various
Apache projects or built from source. The supporting scripts and
instructions are based on building a distribution using the following
versions:

- Hadoop 3.3.x
- HBase  2.4.x
- Hive   3.1.x
- Spark  3.2.x 
- Kafka  3.1.x 
- Zookeeper 3.6.x

[System Prerequisites:](tdh-prereq.md) 
[Mysqld Configuration:](mysql-hive-metastore.md)

TDH supports running Mysql via a container instance or it can be installed and
configured via Ansible (from tdh-gcp).


## Prerequisites

Prerequisites are described in detail by the above gists and is also automated
via Ansible in the **tdh-gcp** project.

- Java JDK 1.8 or 11
  Note that this **must** be a JDK distribution, not JRE. Oracle is only needed
  by vendor distributions for the Strong Encryption security module though more
  recent versions of OpenJDK 1.8 (>171?) now support strong encryption by default.
  Java 11 is not supported fully in Hadoop 2.x, but works with Hadoop3. However,
  only as of Hive 3.1.3 is a JDK11 functional.

- Disable IPv6  
  There are known issues with Hadoop and IPv6 (especially with Ubuntu) and it is
  recommended to disable the IPv6 stack in the Linux Kernel.

- sysctl.conf
  ```
  net.ipv6.conf.all.disable_ipv6 = 1
  net.ipv6.conf.default.disable_ipv6 = 1
  net.ipv6.conf.lo.disable_ipv6 = 1
  ```

- Hadoop User and Group  
  The environment generally runs well as a single user, but for an actual
  distributed cluster it may make more sense to create a hadoop user and group
  with a consistent UID and GID across systems.
  ```
  $ UID=xxx; GID=yyy
  $ groupadd -g $GID hadoop
  $ useradd -g -m -u $UID hadoop
  ```

- Networking and DNS  
  While it is possible to run services on localhost only (loopback) for a single
  node setup, the use of loopback does not work well with distributed systems.
  Spark especially, even in a single node setup, relies on `hostname -f` resolving
  to the correct interface of the host. Essentially, all nodes should have properly
  defined hosts file where hostname is defined to a reachable IPv4 address.
  ```
  127.0.0.1    localhost
  10.10.10.65  callisto.trace3.com callisto
  ```
  It's worth mentioning that no connected Unix system should set the loopback
  address to the hostname unless intended to be completely sequestered. All
  nodes in a distributed system should map hostname to a valid, reachable
  interface, that matches the IP of the Fully Qualified DomainName of the host
  with matching forward and reverse DNS Records on resolution. The following
  example compares the system configured hostname with DNS using the `host` tool
  from the `bind-tools` system package.
  ```
  $ hostname -i
  10.10.10.65
  $ hostname -f
  callisto.trace3.com
  $ hostname -s
  callisto
  $ host callisto.trace3.com
  ```
  In the case of laptop development work which can result in unstable interfaces
  and addresses, one could use a virtual interface for the hostname under which
  the cluster is running. The script `./sbin/pseudoint.sh` can be used to set this
  accordingly.

- Configure SSH  
  SSH keys are required for starting services (such as the secondary namenode).
  ```
  # su - hadoop
  $ ssh-keygen
  $ ssh-copy-id hadoop@myhost
  # or
  $ mkdir -p .ssh; chmod 700 .ssh
  $ cat .ssh/id_rsa.pub >> .ssh/authorized_keys
  $ chmod 600 !$
  ```

- Configure MySQL  
  Mysql is the preferred db type for use with the Hive Metastore. For distributed
  clusters, Mysql can be configured to run in a master-slave setup by the `tdh-gcp`
  project via Ansible.  Alternatively, for Dev setups or single host
  'pseudo-distributed' mode, a docker instance can be used effectively and is
  described in further detail below in the Hive section.

- Cluster configuration  
  While these instructions go into some detail about configurations, a base
  template version can be used to initiate the configs and is found in the `tdh-config`
  directory.  Generally, this directory should be copied away to its own separate
  repository for tracking the cluster configurations. Additionally, as previously
  stated, much of these instructions are for seeding a TDH installation from
  scratch but most of these steps are automated via the `tdh-gcp` project and
  corresponding Ansible.

##  Hadoop

Choose a base path for the hadoop ecosystem. eg. /opt/tdh.  
From here, install the various ecosystem components complete with versions.
```
# mkdir -p /opt/TDH && cd /opt/TDH
# wget http://url/to/hadoop-2.7.1-bin.tar.gz
# tar -zxvf hadoop-2.7.7.tar.gz
# mv hadoop-2.7.7-bin hadoop-2.7.7
# chown -R hadoop:hadoop hadoop-2.7.7
# ln -s hadoop-2.7.7 hadoop
```

Use this pattern for other ecosystem components as well:
```
drwxrwxr-x  2 tca tca 4096 Feb 13 14:57 bin
drwxr-xr-x  2 tca tca 4096 Dec 13  2021 docs
drwxr-xr-x  2 tca tca 4096 May  9  2021 etc
lrwxrwxrwx  1 tca tca   12 Jun 19 16:16 hadoop -> hadoop-3.3.3
drwxr-xr-x 11 tca tca 4096 Jun 19 16:32 hadoop-3.3.3
lrwxrwxrwx  1 tca tca   11 Feb 12 14:11 hbase -> hbase-2.4.8
drwxrwxr-x  7 tca tca 4096 Feb 12 15:30 hbase-2.4.8
lrwxrwxrwx  1 tca tca   10 May 29 10:58 hive -> hive-3.1.3
drwxrwxr-x 11 tca tca 4096 May 29 11:19 hive-3.1.3
lrwxrwxrwx  1 tca tca   11 Jun 19 16:25 kafka -> kafka-3.1.1
drwxr-xr-x  8 tca tca 4096 Jun 19 16:31 kafka-3.1.1
lrwxrwxrwx  1 tca tca   12 Nov 13  2021 logs -> /var/log/tdh
-rw-rw-r--  1 tca tca 1021 Dec 21  2019 README.md
drwxr-xr-x  2 tca tca 4096 Jun 20 09:33 sbin
lrwxrwxrwx  1 tca tca   11 Jun 19 17:08 spark -> spark-3.2.1
drwxr-xr-x 13 tca tca 4096 Apr 24 16:24 spark-3.2.1
drwxr-xr-x 20 tca tca 4096 Mar  4  2018 sqoop-1.99.6
lrwxrwxrwx  1 tca tca   15 Nov 13  2021 zookeeper -> zookeeper-3.6.3
drwxrwxr-x  6 tca tca 4096 Nov 13  2021 zookeeper-3.6.3
```

### Configuring Hadoop
 
 Update the configs in '/opt/TDH/hadoop/etc/hadoop'. Set `JAVA_HOME` in the
***hadoop-env.sh*** file. This should be set to the JDK previously installed.
Note that base config samples are provided in the `tdh-config` directory.
Use these as the template to configure an install. Some important settings are
shown here, but only scratch the surface.

**core-site.xml:**
```xml
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
```xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.name.dir</name>
        <value>file:///data01/hdfs/nn</value>
    </property>
    <property>
        <name>dfs.data.dir</name>
        <value>file:///data01/hdfs/dn,file:///data02/hdfs/dn</value>
    </property>
</configuration>
```

**yarn-site.xml:**
```xml
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

    <property>
        <name>yarn.nodemanager.local-dirs</name>
        <value>/data01/hdfs/nm/nm-local-dir,/data02/hdfs/nm/nm-local-dir</value>
    </property>
</configuration>
```

If intending to use Spark2.x and Dynamic Execution, then the external Spark Shuffle 
service should be configured:
```xml
<property>
  <name>yarn.nodemanager.aux-services</name>
  <value>mapreduce_shuffle,spark_shuffle</value>
</property>
<property>
  <name>yarn.nodemanager.aux-services.spark_shuffle.class</name>
  <value>org.apache.spark.network.yarn.YarnShuffleService</value>
</property>
```

### Configuring the User Environment

This environment serves as example. `tdh-mgr` provides this configuration
via the file `tdh-env-user.sh`, which can be sourced from a users *.bashrc*.

**.bashrc:**
```bash
if [ -f /opt/TDH/etc/tdh-env-user.sh ]; then
    . /opt/TDH/etc/tdh-env-user.sh
fi
```

**tdh-env-user.sh:**

The complete version of this file is provided as *./etc/tdh-env-user.sh*, and
would look something similar to the following as a minimum to set up the
hadoop environment properly:
```bash
# User oriented environment variables (for use with bash)

# The java implementation to use.
export JAVA_HOME=/usr/lib/jvm/default

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

### Formatting the Namenode/Datanode

  Once the environment is setup, the **hadoop** and **hdfs* binary should
be in the path. The following will format the NameNode as specified in **hdfs-site.xml**.
```
# mkdir -p /data/hdfs/nn
# mkdir -p /data/hdfs/dn
# mkdir -p /data/hdfs/nm
# sudo -u $USER hadoop namenode -format
```

### Start HDFS and Yarn

  Init scripts are provided to wrap the various component versions.
```
$ $HADOOP_ROOT/bin/hadoop-init.sh start
```

Perform a quick test to verify that HDFS is working.
```
$ hdfs dfs -mkdir /user
$ hdfs dfs -ls /
```

## Installing and Configuring HBase

This installation is fairly straightforward and follows the same pattern as earlier.
```
 $ cd /opt/TDH
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
```xml
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

## Installing and Configuring Hive

* Install Mysql.

* Create the metastore database. Some options are discussed in the prerequisites
  section. See the section below for using a Docker Container of MySQL.

- Provisioning the database can be performed using the helper script 
*sbin/01-tdh-mysql-provision.sh*. This script expects that the config `.my.cnf`
has been setup accordingly.

- The `hive-init.sh' script performs the init start|stop service.


### Using a Docker container for the Mysql Metastore

Assuming the TDH host in question already has Docker configured and working,
the script `tdh-mgr/sbin/tdh-mysqld-docker.sh` will instantiate a Mysql 5.7 Docker
Container with a temporary password.
```
./sbin/tdh-mysqld-docker.sh run
```

The temp password is provided once the script completes successfully. The
instance can then be fully configured via a mysql client from within the 
container by using the `./sbin/tdh-mysql-client.sh` script.

Steps for configuring the container:
```bash
$ ./sbin/tdh-mysql-client.sh
# prompts for temp password, which should be changed first
# replace the following password accordingly
mysql> ALTER USER 'root'@'localhost' IDENTFIED BY 'myrootsqlpw';

# add root login grant from the host system using fqdn.
# replace the hostname below
mysql> GRANT ALL PRIVILEGES TO 'root'@'my.host.fqdn' IDENTFIED BY 'myrootsqlpw';

# Create Metastore DB and Hive user privileges.
mysql> CREATE DATABASE metastore DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
mysql> GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'my.host.fqdn' IDENTIFIED BY 'myhivepw';
```

This should now allow us to connect and further provision the instance from the
host OS.
```
$ cd /opt/TDH/hive/scripts/metastore/upgrade
$ mysql -h myhost -u hive -p metastore < hive-schema-1.2.0.mysql.sql
```


## Installing and Configuring Spark (on YARN and Standalone)
```bash
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
```bash
export SPARK_DAEMON_JAVA_OPTS="-Dlog4j.configuration=file:///opt/tdh/spark/conf/log4j.properties"
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


### Testing the Spark Installation

To test running a spark job on YARN, try the following spark example:
```bash
$SPARK_HOME/bin/spark-submit --class org.apache.spark.examples.SparkPi \
    --master yarn \
    --deploy-mode cluster \
    --num-executors 1 \
    --executor-cores 2 \
    lib/spark-examples*.jar \
    100
```

Check the YARN UI *http://host:8088/*

Jobs can be submitted directly to the spark master as well and viewed via
the Spark UI at *http://host:8080/*
```bash
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

### Spark 2.x.x

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
```bash
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

### Spark2 Dynamic Allocation

This is a nice feature, especially with constrained resources and notebook users.
To enable dynamic allocation, the external spark shuffle service must be added to YARN.

**yarn-site.xml**:
```xml
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>spark_shuffle,mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services.spark_shuffle.class</name>
    <value>org.apache.spark.network.yarn.YarnShuffleService</value>
  </property>
```

**spark-defaults.conf**:
```
spark.authenticate=false
spark.dynamicAllocation.enabled=true
spark.dynamicAllocation.executorIdleTimeout=60
spark.dynamicAllocation.minExecutors=0
spark.dynamicAllocation.schedulerBacklogTimeout=1
spark.shuffle.service.enabled=true
spark.shuffle.service.port=7337
```

## Installing and Configuring Kafka
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
