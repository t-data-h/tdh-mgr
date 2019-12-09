TDH Manager ( tdh-mgr ) 
=======================

  TDH is a custom hadoop distribution based on Apache Hadoop and related 
Apache components such as Hive, HBase, and Spark. It was created to 
serve as a local development environment running natively on a linux 
host, rather than virtualized, as a pseudo-distributed cluster (1 node as 
master and worker).  It evolved into creating a cloud based multi-node 
cluster using Ansible.

  The *tdh-mgr* project provides a set of management scripts for starting and 
stopping various components and obtaining their status across multiple nodes.
The scripts are fairly simple and require no agents relying on SSH host keys 
for running remote commands.

  TDH has been adapted as a multi-node distribution that can run
on virtual instances.  A separate project, *tdh-gcp*, provides a framework
for installing and distributing TDH assets on GCP via Ansible for multi-node 
clusters.


### Configuring the Hadoop Distribution

  The ecosystem can be built using packages from the various
Apache projects, as binaries or built from source. The supporting scripts and
instructions are based on building a distribution using the following
versions:

- Hadoop 2.7.7 
- HBase  1.3.3
- Hive   1.2.1
- Spark  2.4.4
- Kafka  2.2.0

Refer to the setup document in *docs/tdh-hadoop-setup.md* for setting
up a TDH distribution from scratch.

### Management scripts

  The main entry-point to cluster mgmt. is the script *tdh-init.sh*. This 
works much like a standard init script with *start|stop|status* options.
This in turn calls various ecosystem *init* functions to perform actions 
on various components.  Which components to run can be set via the 
environment using *HADOOP_ECOSYSTEM_INITS*. Each component has its own
init script with the same options (Note, a 'restart' option is generally  
not provided).

  The *conf* directory provides a sample cluster configuration in a manner 
that allows for a given environment config to be 'overlaid' onto the cluster
directory (eg. /opt/TDH). It provides a template example of a single,
pseudo-distributed node. A separate *tdh-config* project is used to 
track and maintain configurations for multiple live environments.
