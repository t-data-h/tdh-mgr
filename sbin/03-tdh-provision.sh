#!/bin/bash
#
#  Initialize tdh installation by linking environment config
#  to /etc/hadoop. This is useful for setting up HADOOP_CONF_DIR
#  in /etc/hadoop/conf as a link to specific cluster context.
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

hadooproot="$1"
etchadoop="/etc/hadoop"

# -------------------------------------

# Set the TDH root
if [ -z "$hadooproot" ]; then
    if [ -n "$HADOOP_ROOT" ]; then
        hadooproot="$HADOOP_ROOT"
    else
        hadooproot="/opt/TDH"  # default location
    fi
fi

if ! [ -d "$hadooproot" ]; then
    echo "Error locating TDH root directory"
    echo ""
    echo "Usage: $PNAME <TDH_ROOT>"
    exit 1
fi

# -------------------------------------

# Ensure we can safely redirect /etc/hadoop
if [ -e "$etchadoop" ]; then
    if [ -L "$etchadoop" ]; then
        ( sudo rm $etchadoop )
    else
        echo "Error ''$etchadoop' exists and is not a link"
        exit 1
    fi
fi

echo " -> ( ln -s ${hadooproot}/etc $etchadoop )"
( sudo ln -s ${hadooproot}/etc $etchadoop )

# -------------------------------------

# Set a legacy /opt/hadoop link to our TDH root
if [ "$hadooproot" == "/opt/hadoop" ]; then
    echo "HADOOP_ROOT is already set to $hadooproot"
else
    if [ -e "/opt/hadoop" ]; then
        if [ -L "/opt/hadoop" ]; then
            ( sudo rm /opt/hadoop )
            echo "HADOOP_ROOT of '$hadooproot' linked to /opt/hadoop"
        else
            echo "Warning! /opt/hadoop exists and is not a link."
            exit 0  # this isn't critical failure
        fi
    fi
    ( sudo ln -s $hadooproot /opt/hadoop )
fi

echo "$PNAME finished."
exit 0
