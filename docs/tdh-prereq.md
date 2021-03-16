Hadoop Node Prerequisites
=========================

## Configuring root ssh
There are various methods of automation for applying these nodes requisites,
including distributing CDH agents, but it is still very useful to have an
administration tool that allows interaction with all nodes with proper
feedback and diff capabilities. Clustershell works brilliantly for this
and is a must for managing clusters without opening too many
windows.  If not just for clustershell, configuring root ssh is also useful
for the CDH install (and can be easily disabled by config after).

- Generate a root account ssh key for the first master and copy to all
other nodes.
```
# ssh-keygen
# ssh-copy-id -i ~/.ssh/id_rsa.pub user@host
```

- Install Clustershell (from the epel repository)
```
$ wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# yum localinstall -y epel-release-latest-7.noarch.rpm
# yum install -y clustershell
```

- Alternatively directly acquire packages if repo access is an issue
```
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/p/python2-clustershell-1.8-1.el7.noarch.rpm
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/c/clustershell-1.8-1.el7.noarch.rpm
yum localinstall -y python2-clustershell-1.8-1.el7.noarch.rpm clustershell-1.8-1.el7.noarch.rpm
```

- Configure clustershell by adding tagged entries to */etc/clustershell/groups*.
```
all: dhx1-r01-m[01-02],dhx1-r02-m[03-04],dhx1-r[01-02]-d[01-d10]
mn: dhx1-r01-m[01-02],dhx1-r02-m[03-04]
dn: dhx1-r[01-02]-d[01-10]
gn: dhx1-r03-g01
```

## Node Prerequisites

- DNS forward and reverse entries for all nodes. (A and PTR records MUST match!).
NSCD (Name-Service Caching Daemon) is also a good idea for a cluster.

- NTP setup - ntpd and consistent timezone settings across all nodes. Chrony
(commonly seen on RHEL) is also supported.

- selinux disabled (/etc/selinux/config).
Set the config to disabled and run the following to set immediately.
```
setenforce 0
```

- iptables disabled
on rhel/centos7:
```
systemctl stop firewalld
systemctl disable firewalld
```
For older versions:
```
service iptables stop
chkconfig iptables off
```

- Disable cupsd and postfix
```
service cups stop
chkconfig cups off
```

- Transparent HugePages disabled
via grub:
```
  kernel /boot/vmlinuz-2.6.32-358.el6.x86_64 ro root=UUID=a216d1e5-884f-4e5c-859a-6e2e2530d486 rhgb quiet transparent_hugepage=never
```
or via rc.local:
```bash
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
```
Don't forget to set the executable bit for rc.local which is by default disabled.
```
chmod u+x /etc/rc.d/rc.local
```

- Configure open file limits
```
/etc/security/limits.conf:
    *  soft  nofile  786432
    *  hard  nofile  786432
    *  soft  nproc    65536
    *  hard  nproc    65536
```
Alternatively set both for just hdfs, hbase, and mapred users

* Configure sysctl.conf options:
```
fs.file-max = 100000
kernel.core_uses_pid = 1
kernel.msgmax = 65536
kernel.msgmnb = 65536
kernel.pid_max =
kernel.shmall = 4294967296
kernel.shmmax = 68719476736
kernel.sysrq = 0
net.bridge.bridge-nf-call-arptables = 0
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.core.netdev_max_backlog = 30000
net.core.rmem_default = 87380
net.core.rmem_max = 67108864
net.core.somaxconn = 4096
net.core.wmem_default = 65536
net.core.wmem_max = 67108864
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.ip_forward = 1
net.ipv4.route.flush = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_mem = 67108864 67108864 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_rmem = 4096 87380 3355442
net.ipv4.tcp_sack = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamp = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_wmem = 4096 65536 3355442
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
vm.swappiness = 1
```

- Notes on swappiness:

  There are conflicting views on the configuration of vm.swappiness. The value
of 0 disables the use of swap entirely by the system and is most commonly
recommended for hadoop nodes. A value of 1 to 10, the least amount of
swappiness, is recommended by a few vendors. In general, this guide suggests
10 is a good choice for most systems, but 1 or 0 is best for Hadoop with the
latter being the preferred for older kernels and 1 for newer.

- Notes on IPv6:

  Note that the Hadoop stack tends to be rather ipv4 specific. There are many
references that suggest disabling ipv6 altogether. This may be due to an issue
specifically with Ubuntu and ipv6 that required it to be disabled. Cloudera
insists on having it disabled as well.
- For RHEL/CentOS add the following to /etc/sysconfig/network:
```
NETWORKING_IPV6=no
IPV6INIT=no
```
- Force sysctl to reread the configuration
```
# sysctl --system
```

###  Java/JDK 1.8

  An Oracle JDK is recommend or even required when using strong encryption and kerberos.
More recent versions of OpenJDK 1.8.0 should now support strong encryption but ymmv.

- Latest JDK 1.8.0_xxx Tarball
```
wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u201-linux-x64.tar.gz
```

- Latest JDK 1.8.0_xxx RPM
```
```

- It is recommended to only install one version of Java. Java can be installed by
tarball or rpm, the latter of which is good for RHEL/CentOS systems, though care
should be taken to ensure java stays consistent across all nodes. Either method is
fine and both are documented here.

Tarball:
```
mkdir -p /usr/java
chmod 755 !$
tar -zxf jdk-8u201-linux-x64.tar.gz -C /usr/java
chown -R root:root /usr/java/jdk1.8.0_201
ln -s !$ /usr/java/default
```

RPM:
```
yum localinstall -y jdk8u201...rpm
```

- Java JCE Policy for Strong Encryption. The JCE Policy jars are already included
with an Oracle JDK distribution and can be enabled by modifying
*${JAVA_HOME}/jre/lib/security/java.security* and setting `crypto.policy=unlimited`.
Note this is usually commented by default.  Alternatively, the JCE Policy can be
acquired directly.
```
wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
unzip jce_policy-8.zip
cp UnlimitedJCEPolicyJDK8/*.jar /usr/java/default/jre/lib/security/
```

- Cleanup:
```
rm -rf UnlimitedJCEPolicyJDK8
rm jce_policy-8.zip
rm jdk-8u181-linux-x64.tar.gz
```

- Configure JAVA_HOME for interactive shells; add the following to */etc/profile.d/*

 * jdk.sh
```
export JDK_HOME=/usr/java/default
export JRE_HOME=/usr/java/default/jre
export JAVA_HOME=$JDK_HOME
export DERBY_HOME=$JDK_HOME/db
export PATH=$PATH:$JDK_HOME/bin:$JRE_HOME/bin:$DERBY_HOME/bin
```

 * jdk.csh
 ```
setenv JDK_HOME /usr/java/default
setenv JRE_HOME /usr/java/default/jre
setenv JAVA_HOME $JDK_HOME
setenv DERBY_HOME $JDK_HOME/db
setenv PATH=$PATH $JDK_HOME/bin:$JRE_HOME/bin:$DERBY_HOME/bin
```


### Additional Packages:

A list of packages that are useful for the cluster:
 > unzip, screen, tmux, clustershell, sysstat

Needed for Security setup:
 > krb5-workstation, krb5-libs, openldap-clients

mysql-connector-java:
```
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz
tar -zxf mysql-connector-java-5.1.46.tar.gz
mkdir -p /usr/share/java
chmod 755 /usr/share/java
cp mysql-connector-java-5.1.46/mysql-connector-java-5.1.46-bin.jar /usr/share/java
ln -s /usr/share/java/mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar
```
