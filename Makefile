# Makefile for tdh-hadoop installation
#

ifndef HADOOP_ROOT
HADOOP_ROOT=/opt/TDH
endif

BINPATH="${HADOOP_ROOT}/bin"
SBINPATH="${HADOOP_ROOT}/sbin"
ETCPATH="${HADOOP_ROOT}/etc"

install:
	( cp etc/* ${ETCPATH} )
	( cp bin/*.sh ${BINPATH} )
	( cp sbin/*.sh ${SBINPATH} )
