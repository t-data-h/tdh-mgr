
Building Hadoop and Various Ecosystem Components
================================================

A guide for building Hadoop and various ecosystem components from source.

## Building Hadoop (v2.7.x-v2.8.x)

**Prerequisites:**
 * OpenJDK 1.8
 * Maven 3.x
 * protobuf=2.5.0
 * cmake
 * openssl

Both Hadoop 2.7.x and Hadoop 3.x require protobuf version 2.5.0 specifically.
Being an older version, this may need to be acquired and built this separately
by first acquiring the repository:
```
git clone https://github.com/protocolbuffers/protobuf.git
git checkout v1.5.0
```
and then building accordingly
```
$ ./configure --prefix=/usr/local
$ make
$ make install
```

Hadoop 2.7.7:
```
export MAVEN_OPTS="-Xms256m -Xmx512m"
mvn clean package -Pdist,native,docs -DskipTests -Dtar
```

## Building HBase (v1.3)

**Prerequisites:**
  * snappy
  * zlib

```
export MAVEN_OPTS="-Xmx1g -XX:MaxPermSize=512m"
mvn clean site install assembly:assembly -Dsnappy -DskipTests -Prelease
```

## Building Spark

 If building for Spark on YARN, and/or Hadoop dependencies will be available,
then the `-Phadoop-provided` flag will keep the Hadoop dependent jars from
being included in the resulting distribution. For spark standalone on hosts
that do not have a hadoop distribution installed the flag should not be used.  
Note the `--name` parameter used to label the specific build.

### Spark v1.6.x
Note that Spark 1.6 uses -Phadoop2.6 and has no profile for 2.7. Additionally,
1.6 uses Scala 2.11 only.
```
export MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=512m"
./make-distribution.sh --name custom-spark --tgz --skip-java-test -Phadoop-2.6 \
 -Dhadoop.version=2.7.1 -Pyarn -Phive -Phive-thriftserver -Phadoop-provided
```

### Spark 2.x.x

* Spark 2.1.x to 2.4.0. Note that Spark2 still uses Scala2.12 but adds a profile
for supporting Scala 2.12.
```
export SPARK_DIST_NAME="custom-spark"
export MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=512m"
./dev/make-distribution.sh --name $SPARK_DIST_NAME --tgz -Phadoop-2.7 \
 -Dhadoop.version=2.7.4 -Pyarn -Phive -Phive-thriftserver -Phadoop-provided
```

* Spark 2.4.2 +
```
./dev/make-distribution.sh --name $SPARK_DIST_NAME --tgz -Phadoop-2.7 \
 -Pyarn -Phive -Phive-thriftserver -Phadoop-provided -Pscala-2.12
```

* By default, Spark2 still builds with Scala 2.11, use the mvn profile
  or optionally update the `scala.version` property in the parent POM.
* Optionally add `-DskipTests`
* Kubernetes support with `-Pkubernetes`


## Hive 1.2.x

```
mvn clean package -Phadoop-2,dist
```
