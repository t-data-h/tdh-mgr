#!/bin/bash
#
#  Initialize tdh installation.
hadooproot="$1"
etchadoop="/etc/hadoop"

if [ -z "$hadooproot" ]; then
    hadooproot="/opt/TDH"
fi

if [ -e "/etc/hadoop" ]; then
    if [ -l "/etc/hadoop" ]; then
        ( sudo rm $etchadoop )
    else
        echo "Error ''$etchadoop' exists and is not a link"
        exit 1
    fi
fi

( sudo ln -s /opt/TDH/etc /etc/hadoop )

if [ -e "/opt/hadoop" ]; then
    if [ -l "/opt/hadoop" ]; then
        ( sudo rm /opt/hadoop; ln -s $hadooproot /opt/hadoop )
    else
        echo "/opt/hadoop exists and is not a link"
    fi
fi

exit 0    
