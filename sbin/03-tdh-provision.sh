#!/bin/bash
#
#  Initialize tdh installation by configuring environment config
#  to /etc/hadoop
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

hadooproot="$1"
etchadoop="/etc/hadoop"


if [ -z "$hadooproot" ]; then
    if [ -n "$HADOOP_ROOT" ]; then
        hadooproot="$HADOOP_ROOT"
    else
        hadooproot="/opt/TDH"
    fi
fi

if ! [ -d "$hadooproot" ]; then
    echo "Error locating TDH root directory"
    echo ""
    echo "Usage: $PNAME <TDH_ROOT>"
    exit 1
fi

if [ -e "$etchadoop" ]; then
    if [ -L "$etchadoop" ]; then
        ( sudo rm $etchadoop )
    else
        echo "Error ''$etchadoop' exists and is not a link"
        exit 1
    fi
fi

echo "   ( ln -s ${hadooproot}/etc $etchadoop )"
( sudo ln -s ${hadooproot}/etc $etchadoop )

if [ "$hadooproot" == "/opt/hadoop" ]; then
    echo "HADOOP_ROOT set to $hadooproot"
else
    if [ -e "/opt/hadoop" ]; then
        if [ -L "/opt/hadoop" ]; then
            ( sudo rm /opt/hadoop; sudo ln -s $hadooproot /opt/hadoop )
            echo "HADOOP_ROOT of '$hadooproot' linked to /opt/hadoop"
        else
            echo "Warning! /opt/hadoop exists and is not a link."
        fi
    fi
fi

exit 0
