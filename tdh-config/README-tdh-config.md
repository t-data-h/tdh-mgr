tdh-config
==========

A template version of TDH Configs that can be used as the root of a 
Git Repository for tracking various TDH (HADOOP) Environment configurations 
for a given TDH deployment.

The tdh-config repository then works in conjunction with the **tdh-mgr**
project for defining a Hadoop-based compute stack, and the project **tdh-gcp**
provides deployment automation via Ansible and associated scripts.

The configs are typically distributed by Ansible (tdh-gcp) which wants a
tarball package for deployment. This can be accomplished by the `tdh-push.sh`
script from *tdh-gcp* which packages and deploys to the ansible target.

### Deploying:

  For complete usage, see the '--help' output of the `tdh-push.sh` script, but
briefly the script takes the path, a name for the target archive, and the
destination host.  It also supports GCP using the --use-gcp switch.

```
tdh-push.sh [options] [path] <archive_name> <host>
```

### Example:

The tdh-gcp framework assumes that a given cluster config is packaged in a
tarball file named `tdh-conf.tar.gz`. The configuration is an overlay of
all relative ecosystem configurations that will overwrite the configs on
the target deployment. Most of our scripts work on relative path which the
following example demonstrates:
```
 $ tdh-config-repo="https://github.com/tcarland/tdh-config.git"
 $ tdh-gcp-repo="https://github.com/tcarland/tdh-gcp.git"
 $ cd ~/tdh-src/
 $ git clone $tdh-config-repo
 $ git clone $tdh-gcp-repo
 $ cd tdh-config
 $ ../tdh-gcp/bin/tdh-push.sh ./gcp-west1 tdh-conf tdh-m01
```
