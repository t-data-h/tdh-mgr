TDH Manager ( tdh-mgr )
=======================

## Overview

  TDH is a custom Hadoop distribution based on Apache Hadoop and related
Apache components such as Hive, HBase, Kafka, and Spark. It was created to
serve as a local development environment running natively on a linux
host as a pseudo-distributed cluster (a single node acting as both master
and worker).  It evolved into creating a multi-node cluster with a set of
bash scripts for management, Ansible for deployment and updates, and
a git repo for managing cluster configs.

  The *tdh-mgr* project provides the set of management scripts for various
components and obtaining their status across multiple nodes. The scripts
rely on SSH host keys for running remote commands.

  *TDH* has been adapted as a multi-node distribution that can run on
RHEL/CentOS instances.  A separate project, **tdh-gcp**, provides a framework
for installing and distributing TDH via Ansible for multi-node clusters.
There is some specific support for running on GCP, but the playbooks can be
used with any infrastructure. The project **tdh-docker** provides a set
of container specifications for supported monitoring services.


## Configuring the Hadoop Distribution

  The ecosystem is built using packages from the various Apache projects,
either as binaries or built from source. The supporting scripts and
instructions are based on building a distribution using the following
versions:

- Hadoop 2.7.7
- HBase  1.3.3
- Hive   1.2.1
- Spark  2.4.4
- Kafka  2.2.0

Refer to the setup document in *docs/tdh-hadoop-setup.md* for creating a
TDH distribution from scratch.


## Running the Distribution

  The main entry point to running the cluster is the script `tdh-init.sh`.
This works much like a standard init script with *start|stop|status* parameters.
This in turn calls various ecosystem *init* functions to perform actions
on various components.  The specific stack of components to run can be set
via the environment using `TDH_ECOSYSTEM_INITS`. Each component has its own
script with the same options (Note, a 'restart' option is generally not
provided intentionally).

  The *tdh-config* directory provides sample cluster configurations in a manner
that allows for a given environment config to be 'overlaid' onto the cluster
directory (eg. /opt/TDH). It provides a pair of examples for a distributed
cluster and of a single, pseudo-distributed node. This can be used as the
template for a separately tracked git repo for managing configurations.
```
cd ..
mkdir myconfigdir
rsync -av ./tdh-mgr/tdh-config/ ./myconfigdir/
cd ./myconfigdir
mv distributed-example myclusterenv
git init
```
