#! /bin/bash

#Set the working dir 
export WORKING_DIR=path_to_repo/Cooley_Spark/


#####################
export SPARK_HOME=/projects/datascience/apache_spark/
export SPARK_CONF_DIR=$WORKING_DIR/conf/
export SPARK_LOG_DIR=$WORKING_DIR/logs/
export SPARK_SLAVES=${SPARK_CONF_DIR}/slaves.${COBALT_JOBID}
cp $COBALT_NODEFILE  $SPARK_SLAVES

pushd $SPARK_HOME
echo "Spark Slaves File ${SPARK_SLAVES}" > $HOME/spark-hostname.${COBALT_JOBID}

./sbin/start-all.sh

NODES=`wc -l ${SPARK_SLAVES} | cut -d" " -f1`
popd

MASTER=`hostname`


h=`hostname`
num_workers=`wc -l ${SPARK_SLAVES}`
echo "Port $SPARK_MASTER_PORT $SPARK_MASTER_WEBUI_PORT" >> $HOME/spark-hostname.${COBALT_JOBID}
echo "Spark is now running with $num_workers workers:" >> $HOME/spark-hostname.${COBALT_JOBID}
echo "  STATUS: http://$h.cooley.pub.alcf.anl.gov:8080" >> $HOME/spark-hostname.${COBALT_JOBID}
echo "  MASTER: spark://$h:7077" >> $HOME/spark-hostname.${COBALT_JOBID}

export SPARK_STATUS_URL=http://$h.cooley.pub.alcf.anl.gov:8080
export SPARK_MASTER_URI=spark://$h:7077

#keep non-interactive job running
while true
do
  sleep 5
done
