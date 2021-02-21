
MinIO Hadoop Settings
======================

Settings for configuring S3 / MinIO storage within Hadoop components.

## MapReduce

*core-site.xml* - MinIO MapRed optimzed settings
```
mapred.maxthreads.generate.mapoutput=2            # Num threads to write map outputs
mapred.maxthreads.partition.closer=0              # Asynchronous map flushers
mapreduce.fileoutputcommitter.algorithm.version=2 # Use the latest committer version
mapreduce.job.reduce.slowstart.completedmaps=0.99 # 99% map, then reduce
mapreduce.reduce.shuffle.input.buffer.percent=0.9 # Min % buffer in RAM
mapreduce.reduce.shuffle.merge.percent=0.9        # Minimum % merges in RAM
mapreduce.reduce.speculative=false                # Disable speculation for reducing
mapreduce.task.io.sort.factor=999                 # Threshold before writing to disk
mapreduce.task.sort.spill.percent=0.9             # Minimum % before spilling to disk
```

## S3 Access from Hadoop
*core-site.xml*  - Minio S3 settings
```
fs.s3a.access.key=minio
fs.s3a.secret.key=minio123
fs.s3a.path.style.access=true
fs.s3a.block.size=512M
fs.s3a.buffer.dir=${hadoop.tmp.dir}/s3a
fs.s3a.committer.magic.enabled=false
fs.s3a.committer.name=directory
fs.s3a.committer.staging.abort.pending.uploads=true
fs.s3a.committer.staging.conflict-mode=append
fs.s3a.committer.staging.tmp.path=/tmp/staging
fs.s3a.committer.staging.unique-filenames=true
fs.s3a.connection.establish.timeout=5000
fs.s3a.connection.ssl.enabled=false
fs.s3a.connection.timeout=200000
fs.s3a.endpoint=http://minio:9000
fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem

fs.s3a.committer.threads=2048                # Number of threads writing to MinIO
fs.s3a.connection.maximum=8192               # Maximum number of concurrent conns
fs.s3a.fast.upload.active.blocks=2048        # Number of parallel uploads
fs.s3a.fast.upload.buffer=disk               # Use disk as the buffer for uploads
fs.s3a.fast.upload=true                      # Turn on fast upload mode
fs.s3a.max.total.tasks=2048                  # Maximum number of parallel tasks
fs.s3a.multipart.size=512M                   # Size of each multipart chunk
fs.s3a.multipart.threshold=512M              # Size before using multipart uploads
fs.s3a.socket.recv.buffer=65536              # Read socket buffer hint
fs.s3a.socket.send.buffer=65536              # Write socket buffer hint
fs.s3a.threads.max=2048                      # Maximum number of threads for S3A
```

## Spark Configuration

*spark-defaults.conf*
```
spark.hadoop.fs.s3a.endpoint http://minio:9000
spark.hadoop.fs.s3a.access.key minio
spark.hadoop.fs.s3a.secret.key minio123
spark.hadoop.fs.s3a.path.style.access true
spark.hadoop.fs.s3a.block.size 512M
spark.hadoop.fs.s3a.buffer.dir ${hadoop.tmp.dir}/s3a
spark.hadoop.fs.s3a.committer.magic.enabled false
spark.hadoop.fs.s3a.committer.name directory
spark.hadoop.fs.s3a.committer.staging.abort.pending.uploads true
spark.hadoop.fs.s3a.committer.staging.conflict-mode append
spark.hadoop.fs.s3a.committer.staging.tmp.path /tmp/staging
spark.hadoop.fs.s3a.committer.staging.unique-filenames true
spark.hadoop.fs.s3a.committer.threads 2048           # number of threads writing to MinIO
spark.hadoop.fs.s3a.connection.establish.timeout 5000
spark.hadoop.fs.s3a.connection.maximum 8192          # maximum number of concurrent conns
spark.hadoop.fs.s3a.connection.ssl.enabled false
spark.hadoop.fs.s3a.connection.timeout 200000

spark.hadoop.fs.s3a.fast.upload.active.blocks 2048   # number of parallel uploads
spark.hadoop.fs.s3a.fast.upload.buffer disk          # use disk as the buffer for uploads
spark.hadoop.fs.s3a.fast.upload true                 # turn on fast upload mode
spark.hadoop.fs.s3a.impl org.apache.hadoop.spark.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.max.total.tasks 2048             # maximum number of parallel tasks
spark.hadoop.fs.s3a.multipart.size 512M              # size of each multipart chunk
spark.hadoop.fs.s3a.multipart.threshold 512M         # size before using multipart uploads
spark.hadoop.fs.s3a.socket.recv.buffer 65536         # read socket buffer hint
spark.hadoop.fs.s3a.socket.send.buffer 65536         # write socket buffer hint
spark.hadoop.fs.s3a.threads.max 2048                 # maximum number of threads for S3A
```

## Hive and MinIO

MinIO Settings for Hive
```
hive.blobstore.use.blobstore.as.scratchdir=true
hive.exec.input.listing.max.threads=50
hive.load.dynamic.partitions.thread=25
hive.metastore.fshandler.threads=50
hive.mv.files.threads=40
mapreduce.input.fileinputformat.list-status.num-threads=50
```

- Other S3 optimizations 
  - https://hadoop.apache.org/docs/current/hadoop-aws/tools/hadoop-aws/index.html
  - https://hadoop.apache.org/docs/r3.1.1/hadoop-aws/tools/hadoop-aws/committers.html



