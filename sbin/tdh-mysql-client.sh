#!/bin/bash
#  Run a client from within Container
#
dockname="tdh-mysql1"

if [ -n "$1" ]; then
    dockname="$1"
fi

( docker exec -it $dockname mysql -uroot -p )
