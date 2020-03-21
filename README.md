TDH Manager ( tdh-mgr )
=======================

## Overview

  TDH is a custom Hadoop distribution based on Apache Hadoop and related
Apache components such as Hive, HBase, Kafka, and Spark. It was created to
serve as a local development environment running native on a linux host
as a pseudo-distributed cluster (a single node acting as both master and
worker).  It evolved into creating a multi-node cluster with a set of bash
scripts for management, Ansible for deployment and updates, and a git repo
for managing cluster configs.

  The *tdh-mgr* project provides the set of management scripts for various
components and obtaining their status across multiple nodes. The scripts
rely on SSH host keys for running remote commands.

  *TDH* has been adapted as a multi-node distribution that can run on
RHEL/CentOS instances.  A separate project, **tdh-gcp**, provides a framework
for installing and distributing TDH via Ansible for multi-node clusters.
There is some specific support for running on GCP, but the playbooks can be
used with any infrastructure. The project **tdh-docker** provides a set
of container specifications for supported monitoring services.

## Installation

  The ecosystem is built using packages from the various Apache projects,
either as binaries or built from source. The supporting scripts and
instructions are based on building a distribution using the following
versions:

- Hadoop 2.8.5
- HBase  1.3.3
- Hive   2.3.6
- Spark  2.4.4
- Kafka  2.2.0

Refer to the setup document in *docs/tdh-hadoop-setup.md* for creating a
TDH distribution from scratch. The end result is a root path containing
each ecosystem component.  Links are used to make minor upgrades easier, so
for hadoop-2.8.5 there would also be a 'hadoop' link, and likewise for other
components which would result in something like this:
```
$ ls -l /opt/TDH
lrwxrwxrwx  1 tca tca   12 Feb 13 15:38 hadoop -> hadoop-2.8.5
drwxr-xr-x 10 tca tca 4096 Feb 13 15:44 hadoop-2.8.5
lrwxrwxrwx  1 tca tca   11 Jun 29  2019 hbase -> hbase-1.3.3
drwxrwxr-x  8 tca tca 4096 Jun 29  2019 hbase-1.3.3
lrwxrwxrwx  1 tca tca   10 Feb  9 15:21 hive -> hive-2.3.6
drwxr-xr-x 10 tca tca 4096 Feb  9 15:22 hive-2.3.6
lrwxrwxrwx  1 tca tca   16 May 11  2019 kafka -> kafka_2.12-2.2.0
drwxr-xr-x  6 tca tca 4096 Feb  8 18:07 kafka_2.12-2.2.0
lrwxrwxrwx  1 tca tca   11 Sep 28 10:43 spark -> spark-2.4.4
drwxr-xr-x 11 tca tca 4096 Feb  9 13:48 spark-1.6.3
drwxr-xr-x 12 tca tca 4096 Jun 30  2017 spark-2.2.0
drwxr-xr-x 12 tca tca 4096 Sep 26 20:05 spark-2.4.4
lrwxrwxrwx  1 tca tca   15 Dec 19 14:16 zookeeper -> zookeeper-5.5.6
drwxr-xr-x  7 tca tca 4096 Dec 19 14:45 zookeeper-5.5.6
```

 This is essentially the contents of the TDH binary distribution though there
could be additional components such as solr, elasticsearch, hue, zeppelin, etc.
in a fully deployed cluster. The TDH tarball may be added to this repository
via `git lfs` in the future, but for now this must be manually created or
acquired externally.

  As previously mentioned, the github project `tdh-gcp` provides Ansible
playbooks for deploying TDH on infrastructure and requires the TDH tarball
along with this repository and a third 'config' tarball. There are a few
GCP specific scripts for creating instances in GCP, but the Ansible is
independent from this and can be used with any infrastructure.


## Configuring the Hadoop Distribution
  The *tdh-config* directory provides sample cluster configurations in a manner
that allows for a given environment config to be 'overlaid' onto the cluster
directory (eg. /opt/TDH). The directory here provides a pair of examples for
a distributed cluster and of a single, pseudo-distributed node. This is intended
to be used as the template for a separately tracked git repo for managing
configurations.
```
cd ..
mkdir myconfigdir
rsync -av ./tdh-mgr/tdh-config/ ./myconfigdir/
cd ./myconfigdir
mv distributed-example myclusterenv
git init
```

  The configuration can be fed to `tdh-gcp` Ansible for distributing to a
running cluster.

## Running the Distribution
   The main entry point to running the cluster is the script `tdh-init.sh`.
This works much like a standard init script with *start|stop|status* parameters.
This in turn calls various ecosystem *init* functions to perform actions
on various components.  

  The specific stack of components to run can be set via the environment
variable `TDH_ECOSYSTEM_INITS`. Each component has its own script with the
same options (Note, a 'restart' option is intentionally not provided).

  This can be run from any host with TDH installed, but 
relies on ssh host keys for password-less ssh access to all nodes in the cluster.
