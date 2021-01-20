# Makefile for tdh-hadoop installation
#
ifndef HADOOP_ROOT
HADOOP_ROOT=/opt/TDH
endif

CP=cp --preserve
MKDIR=mkdir -p

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
	( $(MKDIR) $(BINPATH); $(MKDIR) $(SBINPATH) )
	( $(MKDIR) $(ETCPATH); $(MKDIR) $(DOCPATH) )
	( $(CP) etc/* $(ETCPATH)/ )
	( $(CP) docs/* $(DOCPATH)/ )
	( $(CP) bin/*.sh $(BINPATH)/ )
	( $(CP) sbin/*.sh $(SBINPATH)/ )