# Makefile for tdh-hadoop installation
#
ifndef HADOOP_ROOT
HADOOP_ROOT=/opt/TDH
endif

BINPATH="${HADOOP_ROOT}/bin"
SBINPATH="${HADOOP_ROOT}/sbin"
ETCPATH="${HADOOP_ROOT}/etc"
DOCPATH="${HADOOP_ROOT}/docs"


all: docs 

pdf: docs

.PHONY: docs 
docs:
	( cd docs; make all )

clean:
	( cd docs; make clean )

distclean: clean

install:
	( mkdir -p ${BINPATH}; mkdir -p ${SBINPATH} )
	( mkdir -p ${ETCPATH}; mkdir -p ${DOCPATH} )
	( cp etc/* ${ETCPATH}/ )
	( cp docs/* ${DOCPATH}/ )
	( cp bin/*.sh ${BINPATH}/ )
	( cp sbin/*.sh ${SBINPATH}/ )
