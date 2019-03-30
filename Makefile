
ifndef HADOOP_ROOT
HADOOP_ROOT=/opt/TDH
endif

BINPATH="${HADOOP_ROOT}/bin"
ETCPATH="${HADOOP_ROOT}/etc"

install:
	( cp etc/hadoop-env-user.sh ${ETCPATH} )
	( cp bin/*.sh ${BINPATH} )
