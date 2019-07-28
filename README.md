TDH Manager ( tdh-mgr ) 
=======================

  TDH is a custom hadoop distribution based on Apache Hadoop and related 
Apache components, Hive, HBase, and Spark mainly. This was created initially
for development work using these components natively, rather than virtualized,
as a pseudo-distributed cluster (1 node master and worker).

  The *tdh-mgr* project provides a set of management scripts for starting and 
stopping various components and obtaining their status across multiple nodes.
The scripts are fairly simple and require no agents and rely on SSH host keys 
for running remote status commands.

  TDH has been adapted as a simple multi-node distribution that can run
on virtual instances.  A separate project, *tdh-gcp*, provides a framework
for installing and distributing TDH assets on GCP via Ansible.


### Configuring the Hadoop Distribution

  The ecosystem can be built using packages from the various
Apache projects, as binaries or built from source. The supporting scripts and
instructions are based on building a distribution using the following
versions:

- Hadoop 2.7.x
- HBase  1.3.x
- Hive   1.2.x
- Spark  2.4.x
- Kafka  2.2.x

Refer to the setup document in *docs/tdh-hadoop-setup.md* for setting
up a TDH distribution from scratch.

### Management scripts

  The main entrypoint to cluster mgmt. is the script *tdh-init.sh*. This 
works much like a standard init script with *start|stop|status* options.
This in turn calls various ecosystem *init* functions to perform actions 
on various components.  Which components can be set via the environment
using the variable *HADOOP_ECOSYSTEM_INITS*. Each component has its own
init script for the same options (Of note, a direct 'restart' option is 
not provided).

  A conf directory provides cluster configuration in a manner than 
allows for a given environment config to be 'overlaid' on the cluster
directory (eg. /opt/TDH). It provides a template example of a single,
pseudo-distributed node. A separate *tdh-config* project is used to 
track and maintain configurations for multiple test environments.


  
