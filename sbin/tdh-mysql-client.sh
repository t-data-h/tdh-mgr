#!/usr/bin/env bash
#  Run a client from within Container
#
dockname="${1:-tdh-mysql01}"

( docker exec -it $dockname mysql -uroot -p -S /var/run/mysqld/mysqld.sock )

exit $?