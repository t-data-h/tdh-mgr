TDH Manager ( tdh-mgr )
=======================

## Overview

  TDH is a custom Hadoop distribution based on Apache Hadoop and related
Apache Hadoop components such as Hive, HBase, Kafka, and Spark. It was
created to serve as a local development environment running native on a 
linux host as a pseudo-distributed cluster (a single node acting as both 
master and worker).  It evolved into creating a multi-node cluster with a 
set of bash scripts for management, Ansible for deployment and updates, 
and a git repo for managing cluster configs.

  The *tdh-mgr* project provides the set of management scripts for various
components and obtaining their status across multiple nodes. The scripts
rely on SSH host keys for running remote commands.

  *TDH* has been adapted as a multi-node distribution that can run on
RHEL/CentOS instances.  A separate project, **tdh-gcp**, provides a 
framework for installing and deploying TDH via Ansible for multi-node 
clusters. There is some specific support for running on GCP, but the 
playbooks can be used with any environment. The project **tdh-docker** 
provides a set of container specifications for supported monitoring 
services such as Prometheus and Grafana.

## Installation

  The ecosystem is built using packages from the various Apache projects,
either as binaries or built from source. The TDH package is distributed
separately as a tarball, given it's size.  The supporting scripts and
instructions are based on building a distribution using the following
versions:

- Hadoop 3.3.x
- HBase  1.3.x
- Hive   3.1.x
- Spark 2 or 3
- Kafka  2.6.x

Refer to the setup document [tdh-hadoop-setup.md](docs/tdh-hadoop-setup.md) 
for creating a TDH distribution from scratch. The end result is a root path 
containing each ecosystem component.  Links are used to make minor upgrades 
easier, so for hadoop-2.8.5 there would also be a 'hadoop' link, and likewise 
for other components which would result in something like this:
```
total 48
drwxrwxr-x  2 tca tca 4096 Feb 25  2020 bin
drwxr-xr-x  2 tca tca 4096 Dec 14 11:11 docs
drwxr-xr-x  2 tca tca 4096 Dec 15 09:35 etc
lrwxrwxrwx  1 tca tca   12 Dec 14 11:26 hadoop -> hadoop-3.3.0
drwxrwxr-x 10 tca tca 4096 Dec 15 13:01 hadoop-3.3.0
lrwxrwxrwx  1 tca tca   11 Jun 29  2019 hbase -> hbase-1.3.3
drwxr-xr-x  8 tca tca 4096 Aug 27  2019 hbase-1.3.3
lrwxrwxrwx  1 tca tca   10 Dec 14 13:51 hive -> hive-3.1.2
drwxrwxr-x 10 tca tca 4096 Dec 14 15:39 hive-3.1.2
lrwxrwxrwx  1 tca tca   11 Dec 14 13:24 kafka -> kafka-2.6.1
drwxr-xr-x  6 tca tca 4096 Jul 27  2019 kafka-2.6.1
-rw-rw-r--  1 tca tca 1021 Dec 21  2019 README.md
drwxr-xr-x  2 tca tca 4096 Dec 14 13:57 sbin
lrwxrwxrwx  1 tca tca   11 Dec 14 13:52 spark -> spark-3.0.1
drwxrwxr-x 13 tca tca 4096 Dec 15 07:07 spark-3.0.1
drwxr-xr-x 20 tca tca 4096 Mar  4  2018 sqoop-1.99.6
lrwxrwxrwx  1 tca tca   15 Dec 20  2019 zookeeper -> zookeeper-5.5.6
drwxrwxr-x  7 tca tca 4096 Nov 15 15:30 zookeeper-5.5.6
```

 This is essentially the contents of a TDH binary distribution, though 
there could be additional components such as Solr, Elasticsearch, Hue, 
Zeppelin, etc., in a fully deployed cluster. The TDH tarball may be added 
to this repository via `git lfs` in the future, but for now this must be 
manually created or acquired externally.

  As previously mentioned, the github project `tdh-gcp` provides Ansible
playbooks for deploying TDH on infrastructure and requires the TDH tarball
along with this repository and a third 'config' tarball.


## Configuring the Hadoop Distribution

  The *tdh-config* directory provides sample cluster configurations in a 
manner that allows for a given environment config to be 'overlaid' onto the 
cluster directory (eg. /opt/TDH). The directory here provides a pair of examples 
for a distributed cluster and of a single, pseudo-distributed node. This is 
intended to be used as the template for a separately tracked git repo for 
managing configurations.
```
cd ..
mkdir myconfigdir
rsync -av ./tdh-mgr/tdh-config/ ./myconfigdir/
cd ./myconfigdir
mv distributed-example myclusterenv
git init
```

  The configuration is then provided to `tdh-gcp` Ansible for distributing 
to a running cluster.


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
