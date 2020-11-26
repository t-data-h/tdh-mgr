Installing and Configuring MySQL as the Hive Metastore
=======================================================

Installing MySQL Server 5.7.  For consistency, we use the MySQL Community Edition directly rather than relying on distribution packages that often pull in unwanted dependencies (OpenJDK for one), or for some distributions, may install MariaDB instead.


#### Ubuntu:

 1) Acquire .deb file for the mysql apt repo and download the JDBC Connector.

```
wget https://dev.mysql.com/get/mysql-apt-config_0.8.9-1_all.deb
```

 2) Install the repository:
```
sudo dpkg -i mysql-apt-config_0.8.9-1_all.deb
sudo apt-get update
```

 3) Install mysql
```
sudo apt-get install mysql-server
```

#### CentOS/RHEL 7.x:

1) Acquire the yum repo file
```
wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
```


2) Install the repo file
```
yum localinstall -y mysql57-community-release-el7-11.noarch.rpm
```

For reference, a .repo file for specifically mysql 5.7 should look similar to the following:
```
[mysql-connectors-community]
name=MySQL Connectors Community
baseurl=http://repo.mysql.com/yum/mysql-connectors-community/el/7/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

[mysql-tools-community]
name=MySQL Tools Community
baseurl=http://repo.mysql.com/yum/mysql-tools-community/el/7/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

[mysql57-community]
name=MySQL 5.7 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.7-community/el/7/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
```

3) Install mysql
```
yum install mysql-server
mysqld --initialize
service mysqld start
mysql -p -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'pw';"
```

#### Configuring MySQL

This outlines the process for configuring MySQL for use as a Hive Metastore including replication. Even if the mysql server will not be replicated, it is best to ensure bin-logging and any options necessary for replication be applied to simplify a later requirement.

For Cloudera clusters, there have been known compatability issues in using bin-logging with certain ecosystem components like Oozie. This may no longer be the case, however current best practice is to use the 'mixed' bin-log format. Note that server-id must be unique per instance.

```
server-id=1
log-bin=mysql-bin
binlog-format=mixed
```

Replication generally works fine for an entire mysql instance dedicated to a cluster, however it is worth mentioning that the Hive Metastore can be solely replicated via the following configuration option:

```
replicate-do-db=metastore
```

A full MySQL sample configuration is provided at the end of this document.

Note that the use of '>' denotes a mysql command and the '$' prefix is a shell command.


#### Enabling MySQL Replication

First create the replication user with grants on the master. This user will be created on the slave automatically in a later step.

```
> GRANT REPLICATION SLAVE ON *.* TO `repluser`@`%` IDENTIFIED BY 'repluser_pw';
```

Ensure both master and slave databases are running and have unique server ids. We then dump the master database with a full lock that we keep in place until replication is running.  

On the master we dump the database as follows:
```
$ mysql -u root -p

> FLUSH TABLES WITH READ LOCK;
> SHOW MASTER STATUS;
```

Leave this sql session running and in another shell run the dump.
```
mysqldump -p --all-databases --lock-all-tables --master-data > mydump.sql
```

Next, we reset the replication process on the Slave database to align the binlogging. We take the two values for the log file and log position from the master status details from above.

```
$ mysql -u root -p

> STOP SLAVE;
> RESET SLAVE;
> CHANGE MASTER TO
  MASTER_HOST='master_hostname',
  MASTER_USER='repluser',
  MASTER_PASSWORD='replpw',
  MASTER_LOG_FILE='mysql-bin.0000003',
  MASTER_LOG_POS=438;
```

 Leave this mysql session open and in another shell pull in the database file.

```
$ mysql -p < mydump.sql
```

 Now the slave can be started and the two open sessions, slave and master can be closed.
```
 > START SLAVE;
 > quit;
```

Replication is now enabled. You can view the current slave status by running the command
```
mysql -p -e "SHOW SLAVE STATUS\G"
```

Replication timing is rarely an issue with the Hive metastore, since it does not grow too large, but in very large clusters,  one might wish to have the CDH processes for Cloudera Manager (host monitor, events) write to a separate database since it produces a larger volume of writes. The slave status provides the number of *seconds_behind_master* as an indication of the replication load.


#### Sample MySQL Configuration:


```
[mysql]
socket=/var/lib/mysql/mysql.sock


[mysqld]
key_buffer_size         = 32M
max_allowed_packet      = 16M
thread_stack            = 256K
thread_cache_size       = 64
query_cache_limit       = 8M
query_cache_size        = 64M
query_cache_type        = 1
max_connections         = 150
read_buffer_size        = 2M
read_rnd_buffer_size    = 16M
sort_buffer_size        = 8M
join_buffer_size        = 8M

transaction-isolation=READ-COMMITTED
binlog-format=mixed

innodb_file_per_table           = 1
innodb_file_format              = Barracuda
innodb_file_per_table           = 1
innodb_flush_log_at_trx_commit  = 1
innodb_log_buffer_size          = 64M
innodb_buffer_pool_size         = 2G
innodb_thread_concurrency       = 8
innodb_flush_method             = O_DIRECT
innodb_log_file_size            = 512M
innodb_large_prefix
log_bin_trust_function_creators = 1

datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql

symbolic-links=0

log-bin=mysql-bin
max_binlog_size=600M
expire_logs_days=3
server-id=1

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
```

#### Mysql JDBC Connector
Use the 5.1 Version for Mysql 5.7 and CDH. Note all nodes need the connector.

```
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz
tar -zxf mysql-connector-java-5.1.46.tar.gz
mkdir -p /usr/share/java
chmod 755 /usr/share/java
cp mysql-connector-java-5.1.46/mysql-connector-java-5.1.46-bin.jar /usr/share/java
ln -s /usr/share/java/mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar
```

#### Grant statements for a Cloudera Environment

The following provides a list of necessary databases and suggested names,
followed by the grant statements to configure.

Role, Database Name, User,	Password
```
Activity Monitor,        	amon,     	amon,	 amon_password
Reports Manager,	         rman,	     rman,	 rman_password
Hive Metastore Server,    metastore,	hive,	 hive_password
Cloudera Audit Server,   	nav,	      nav,	  nav_password
Cloudera Metadata Server,	navms,    	navms,	navms_password

Hue,    hue,    hue,    hue_password
Oozie,  oozie,  oozie,  oozie_password
Sentry,	sentry,	sentry,	sentry_password

#----------

CREATE DATABASE cmf DEFAULT CHARACTER SET utf8;
CREATE DATABASE amon DEFAULT CHARACTER SET utf8;
CREATE DATABASE rman DEFAULT CHARACTER SET utf8;
CREATE DATABASE metastore DEFAULT CHARACTER SET utf8;
CREATE DATABASE nav DEFAULT CHARACTER SET utf8;
CREATE DATABASE navms DEFAULT CHARACTER SET utf8;
CREATE DATABASE hue DEFAULT CHARACTER SET utf8;
CREATE DATABASE oozie DEFAULT CHARACTER SET utf8;
CREATE DATABASE sentry DEFAULT CHARACTER SET utf8;

GRANT ALL ON cmf.* to 'cmf'@'%' IDENTIFIED BY 't3cmf';
GRANT ALL ON amon.* TO 'amon'@'%' IDENTIFIED BY 't3amon';
GRANT ALL ON rman.* TO 'rman'@'%' IDENTIFIED BY 't3rman';
GRANT ALL ON metastore.* TO 'hive'@'%' IDENTIFIED BY 't3hive';
GRANT ALL ON nav.* TO 'nav'@'%' IDENTIFIED BY 't3nav';
GRANT ALL ON navms.* TO 'navms'@'%' IDENTIFIED BY 't3navms';
GRANT ALL ON hue.* TO 'hue'@'%' IDENTIFIED BY 't3hue';
GRANT ALL ON oozie.* TO 'oozie'@'%' IDENTIFIED BY 't3oozie';
GRANT ALL ON sentry.* TO 'sentry'@'%' IDENTIFIED BY 't3sentry';
```
