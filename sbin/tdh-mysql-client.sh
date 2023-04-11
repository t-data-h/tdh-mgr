#!/usr/bin/env bash
#  Run a client from within Container
#
name="${1:-tdh-mysql01}"

( docker exec -it $name mysql -uroot -p -S /var/run/mysqld/mysqld.sock )

exit $?