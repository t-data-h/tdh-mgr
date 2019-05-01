#!/bin/bash
#
#  Initialize tdh installation.
hadooproot="$1"
etchadoop="/etc/hadoop"

if [ -z "$hadooproot" ]; then
    hadooproot="/opt/TDH"
fi

if [ -e "$etchadoop" ]; then
    if [ -l "$etchadoop" ]; then
        ( sudo rm $etchadoop )
    else
        echo "Error ''$etchadoop' exists and is not a link"
        exit 1
    fi
fi

( sudo ln -s ${hadooproot}/etc $etchadoop )

if [ "$hadooproot" == "/opt/hadoop" ]; then
    echo "HADOOP_ROOT set to $hadooproot"
else
    if [ -e "/opt/hadoop" ]; then
        if [ -l "/opt/hadoop" ]; then
            ( sudo rm /opt/hadoop; ln -s $hadooproot /opt/hadoop )
            echo "HADOOP_ROOT of ''$hadooproot' linked to /opt/hadoop"
        else
            echo "/opt/hadoop exists and is not a link"
        fi
    fi
fi

exit 0
