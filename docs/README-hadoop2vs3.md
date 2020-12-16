Hadoop 3 Changes from Hadoop v2
===============================

## Heapsize

For Hadoop v3, `HADOOP_HEASIZE` has been replaced by `HADOOP_HEAPSIZE_MAX` and 
`HADOOP_HEAPSIZE_MIN`. eg.
```
HADOOP_HEAPSIZE_MAX=4096
HADOOP_HEAPSIZE_MAX=4g
```

## Hadoop 2.8.x Default ephemeral port numbers
```
  public static final int     DFS_NAMENODE_HTTP_PORT_DEFAULT = 50070;
  public static final String  DFS_NAMENODE_HTTP_ADDRESS_KEY = "dfs.namenode.http-address";
  public static final int     DFS_NAMENODE_HTTPS_PORT_DEFAULT = 50470;
  public static final String  DFS_NAMENODE_HTTPS_ADDRESS_KEY = "dfs.namenode.https-address";
  public static final String  DFS_NAMENODE_SECONDARY_HTTP_ADDRESS_DEFAULT = "0.0.0.0:50090";
  public static final String  DFS_NAMENODE_SECONDARY_HTTPS_ADDRESS_DEFAULT = "0.0.0.0:50091";
  
  public static final int     DFS_DATANODE_HTTP_DEFAULT_PORT = 50075;
  public static final int     DFS_DATANODE_HTTPS_DEFAULT_PORT = 50475;
  public static final int     DFS_DATANODE_DEFAULT_PORT = 50010;
  public static final int     DFS_DATANODE_IPC_DEFAULT_PORT = 50020;
```

## Hadoop 3.x Port Mapping from v2
```
Namenode ports
----------------
ui:
50470 -> 9871  (secured)
50070 -> 9870  (unsecured)
rpc:
8020 -> 9820 

Secondary NN ports
---------------
50091 -> 9869 (secured)
50090 -> 9868

Datanode ports
---------------
ui:
50475 -> 9865  (secured)
50075 -> 9864  (unsecured)
rpc:
50020 -> 9867
50010 -> 9866
```

# Upgrading Hadoop v2 to v3

Hadoop v2 to v3
=========================

- Stop all Application and Services other than HDFS

- Run Fsck
```
hdfs fsck / -files -blocks -locations > dfs-fsck.log
```

- Create Metadata Checkpoint
```
hdfs dfsadmin -safemode enter
hdfs dfsadmin -saveNamespace
```

- Backup Checkpoint files
```
 ${dfs.namenode.name.dir}/current
```

- Run DataNode Report
```
hdfs dfsadmin -report > dfs-report.log
```

- Capture Namespace
```
hdfs dfs -ls -R / > dfs-lsr.log
```

- Stop and perform new version upgrade.

- Start Upgrade process
```
hadoop-daemon.sh start namenode -upgrade
```

- Finalize previous images
```
hdfs dfsadmin -finalizeUpgrade
```
