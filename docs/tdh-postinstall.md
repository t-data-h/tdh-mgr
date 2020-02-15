tdh-postinstall
===============

Some basic validation steps.

## HDFS and YARN 

Validate simple filesystem operations.
```
hdfs dfs -ls
touch foo
date > foo
hdfs dfs -put foo
hdfs dfs -ls
hdfs dfs -rm foo
hdfs dfs -ls /
```
You can also browse to the NameNode UI at http://host:50070/ which provides
additional metrics regarding health of the filesystem and datanodes.

Yarn can be verified by running a MapReduce example:
```
yarn jar /opt/TDH/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.7.jar \
pi 100 10000

<snip>
Job Finished in 1.398 seconds
Estimated value of Pi is 3.14160000000000000000
```

Additional YARN information can be viewed on the YARN ResourceManager UI at
http://host:8088/


## HBase Testing

Run an HBase shell.
```
$ hbase shell
hbase(main):001:0>
```

Create and populate a test table
```
 create 't1', 'f1'
 put 't1', 'key1', 'f1:', "val1"
 put 't1', 'key2', 'f1:', "val2"
 put 't1', 'key3', 'f1:', "val3"

 scan 't1'

ROW                    COLUMN+CELL                                                  
 key1                  column=f1:, timestamp=1579305863970, value=val1              
 key2                  column=f1:, timestamp=1579308035525, value=val2              
 key3                  column=f1:, timestamp=1579308035580, value=val3              
3 row(s) in 0.0740 seconds
```

and you will have data in hbase `hdfs dfs -ls /hbase/default/t1`

Browse to the HBase Master UI for additional HBase metrics at http://host:16010/


## Hive

Hive is barely seeded, but can be tested minmially at least by ensuring the
default db exists

```
$ hive

> show databases;
> describe database default;

default	Default Hive database	hdfs://callisto/hive/warehouse	public	ROLE
```

## Spark

 Testing spark properly involves ensuring it can communicate with Hive and Yarn
including that spark can launch executors.

 The `spark.catalog` API communicates with the Hive Metastore:
```
spark.catalog.listDatabases.show
spark.catalog.listTables("default").show

val createstr = spark.sql("SHOW CREATE TABLE default.table").first.get(0).toString
println(createstr)

spark.catalog.listTables("db").collect.foreach { table => println(table.name) }
```

The above is more useful with actual tables existing.

SparkPi Example:
```
cd /opt/TDH/spark
./bin/run-example SparkPi
```

Even more examples at https://spark.apache.org/examples.html
