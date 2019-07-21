TDH Hadoop 
===========

  TDH is a custom hadoop distribution with an initial configuration as a
pseudo-distributed cluster with 1 worker node. The distribution is based
entirely on direct apache versions. This project provides a set of scripts
for managing the environment.


### Configuring the Hadoop Distribution

  The ecosystem can be built using binary packages from the various
Apache projects or built from source. The supporting scripts and
instructions are based on building a distribution using the following
versions:

- Hadoop 2.7.x
- HBase  1.1.x - 1.3
- Hive   1.2.x
- Spark  1.6.x - 2.4.x
- Kafka  0.10.x

Refer to the setup document in *docs/tdh-hadoop-setup.md* for building
up a TDH distribution from scratch.

### Management scripts

  The main entrypoint to cluster mgmt. is the script *tdh-init.sh*. This 
works much like a standard in it script with *start|stop|status* options.
This in turn calls various ecosystem *init* functions to perform actions 
on various components.  Which components can be set via the environment
using the variable *HADOOP_ECOSYSTEM_INITS*. Each component has its own
init script for the same options (notice a direct 'restart' option is 
not provided).

  The conf directory provides cluster configuration in a manner than 
allows for a given environment config to be 'overlaid' on the cluster
directory (eg. /opt/TDH).

  Further managment such as configuration updates or other operations 
is provided by a separate project (for now). The *tdh-gcp* project 
provides scripts and ansible playbooks for deploying a TDH cluster to 
Google Cloud Platform.

  
