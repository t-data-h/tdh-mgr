
ifndef HADOOP_ROOT
HADOOP_ROOT=/opt/hadoop
endif

BINPATH="${HADOOP_ROOT}/bin"
ETCPATH="${HADOOP_ROOT}/etc"

install:
	( sudo cp hadoop-env-user.sh ${ETCPATH} )
	( sudo cp hadoop-init.sh ${BINPATH} )
	( sudo cp hbase-init.sh ${BINPATH} )
	( sudo cp hive-init.sh ${BINPATH} )
	( sudo cp hue-init.sh ${BINPATH} )
	( sudo cp kafka-init.sh ${BINPATH} )
	( sudo cp spark-server-init.sh ${BINPATH} )
	( sudo cp spark-history-init.sh ${BINPATH} )
	( sudo cp logzap_hadoop.sh ${BINPATH} )
	( sudo cp hadeco-init.sh ${BINPATH} )
	( sudo cp zeppelin-init.sh ${BINPATH} )
	

