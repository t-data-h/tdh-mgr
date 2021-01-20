tdh-config
==========

A version of TDH Configs that serve as an example configuration that
can be used as the root of a *Git* repository for tracking various TDH 
configurations for a given deployment.

The *tdh-config* repository then works in conjunction with the **tdh-mgr**
project for defining a Hadoop-based compute stack, and the project **tdh-gcp**
provides deployment automation via Ansible and associated scripts.

The configs are typically distributed by Ansible (tdh-gcp) which 
expects a *tarball* package for deployment. This can be accomplished 
by using the `tdh-push.sh` script from *tdh-gcp* which packages and 
deploys to a given target host (ansible).


### Deploying:

  For complete usage, see the '--help' output of the `tdh-push.sh` script, 
but briefly, the script takes the path, a name for the output archive, 
and the destination hostname. It also supports GCP via the --use-gcp switch.
```
tdh-push.sh [options] [path] <archive_name> <host>
```

### Example Config deployment:

The tdh-gcp framework assumes that a given cluster config is packaged in a
file named `tdh-cluster-config.tar.gz`. The tarball is an overlay of all relative-path 
ecosystem configurations that will overwrite the configs on the target 
deployment. Most of the scripts work on relative path which the following 
example demonstrates:
```
 $ tdh-config-repo="https://path.to.my.tdh-config"
 $ tdh-gcp-repo="https://github.com/tcarland/tdh-gcp.git"
 $ cd ~/tdh-src/
 $ git clone $tdh-config-repo
 $ git clone $tdh-gcp-repo
 $ cd tdh-config
 $ ../tdh-gcp/bin/tdh-push.sh ./gcp-west1 tdh-cluster-config tdh-m01
```

The last command will create an archive of the *gcp-west1* config directory
named as `tdh-cluster-config.tar.gz` which is copied to the host *tdh-m01:/tmp/dist*.