
ifndef HADOOP_ROOT
HADOOP_ROOT=/opt/hadoop
endif

BINPATH="${HADOOP_ROOT}/bin"
ETCPATH="${HADOOP_ROOT}/etc"

install:
	( cp etc/hadoop-env-user.sh ${ETCPATH} )
	( cp bin/*.sh ${BINPATH} )
