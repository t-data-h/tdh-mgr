README-hadoop-conf.md
=====================

The environment variable *HADOOP_CONF_DIR* is used by hadoop clients to
govern which set of client configurations are used, thereby controlling which
cluster is being utilized. This is usually set in the profile of a given user
environment. Note that *JAVA_HOME* should also be set by all clients.

TDH uses soft links for `/etc/hadoop/conf` allowing for switching of the default
cluster configuration.
```
$ ln -s /opt/TDH/etc /etc/hadoop
$ cd /opt/TDH/etc
$ ln -s /opt/TDH/hadoop/etc/hadoop hadoop.local
$ ln -s hadoop.local conf
$ export HADOOP_CONF_DIR=/etc/hadoop/conf

$ ls -l /opt/TDH/etc | grep hadoop
lrwxrwxrwx 1 tca tca   12 Jun 21  2019 conf -> hadoop.local
lrwxrwxrwx 1 tca tca   26 Aug 30 09:01 hadoop.local -> /opt/TDH/hadoop/etc/hadoop

$ ls -l $HADOOP_CONF_DIR/*-site.xml
-rw-r--r-- 1 tca tca 1202 Oct 15  2017 /etc/hadoop/conf/core-site.xml
-rw-r--r-- 1 tca tca 1897 Jul 16  2019 /etc/hadoop/conf/hdfs-site.xml
lrwxrwxrwx 1 tca tca   35 Oct 16  2017 /etc/hadoop/conf/hive-site.xml -> /opt/hadoop/hive/conf/hive-site.xml
-rw-r--r-- 1 tca tca  620 Jul 31  2017 /etc/hadoop/conf/httpfs-site.xml
-rw-r--r-- 1 tca tca 5540 Jul 31  2017 /etc/hadoop/conf/kms-site.xml
-rw-r--r-- 1 tca tca 2984 Dec  3  2017 /etc/hadoop/conf/yarn-site.xml
```

The default /etc/hadoop/conf link is to /opt/TDH/etc/hadoop.local
which in turn uses the hadoop home of `/opt/TDH/hadoop`. The linkage
above is configured at install by the *tdh-gcp* project.

To configure local clients in /opt/TDH (eg. spark2) to communicate with
another cluster, provide an alternate *HADOOP_CONF_DIR* and set the variable
to the alternate *conf* path.
```
export HADOOP_CONF_DIR="/opt/TDH/etc/hadoop.myCluster"
mkdir -p $HADOOP_CONF_DIR; cd $HADOOP_CONF_DIR
wget https://myCluster:7183/configurations/hadoop-hdfs
```
