
Building Hadoop and Various Ecosystem Components
================================================

 A guide for building hadoop and other ecosystem components from source.

#### Building Hadoop (v2.7.7)

**Prerequisites:**
 * Oracle JDK 1.8
 * Maven 3.x
 * protobuf 2.5.0
 * cmake
 * openssl

Both Hadoop 2.7.x and Hadoop 3.x require protobuf 2.5.0 specifically.
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

#### Building HBase (v1.3)

**Prerequisites:**
  * snappy
  * zlib

```
mvn compile -Dsnappy
or
MAVEN_OPTS="-Xmx1g -XX:MaxPermSize=512m" mvn clean site install assembly:assembly -Dsnappy -DskipTests -Prelease
```

#### Building Spark (v1.6.x)

**Prerequisites:**
  * Spark 1.4.x requires Maven 3.0.x  
  * Spark 1.5.x requires Maven 3.3.x

 If building for Spark on YARN, or Hadoop dependencies will be available, then the **-Phadoop-provided** flag
will keep the Hadoop dependent jars from being included in the resulting distribution. For spark standalone on
hosts that do not have a hadoop distribution installed the flag should be omitted.  Note the --name parameter
to label the specific build.

```
export MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=512m"
./make-distribution.sh --name custom-spark --tgz --skip-java-test -Phadoop-2.6 \
-Dhadoop.version=2.7.1 -Pyarn -Phive -Phive-thriftserver -Phadoop-provided
```

#### Spark 2.x.x

* Spark 2.1.x to 2.4.0
```
export SPARK_DIST_NAME="custom-spark"
export MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=512m"
./dev/make-distribution.sh --name $SPARK_DIST_NAME --tgz -Phadoop-2.7 \
-Dhadoop.version=2.7.4 -Pyarn -Phive -Phive-thriftserver -Phadoop-provided
```

* Spark 2.4.2 +
```
./dev/make-distribution.sh --name $SPARK_DIST_NAME --tgz -Phadoop-2.7 \
 -Pyarn -Phive -Phive-thriftserver -Phadoop-provided
```

#### Hive 1.2.1

mvn clean package -Phadoop-2,dist
