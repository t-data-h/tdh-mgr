#!/bin/bash
#
PNAME=${0##*\/}

hostname="$1"
rt=1

if [ -z "$hostname" ]; then
    echo "Usage: $PNAME <fqdn>"
    exit $rt
fi

shortname=${hostname%%\.*}

if [ -z "$shortname" ]; then
    echo "Error! Provided hostname does not seem to be a fully qualified domain name"
    exit $rt
fi

( ./easyrsa gen-req $hostname nopass )

rt=$?

exit $rt
