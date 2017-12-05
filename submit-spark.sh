#! /bin/bash



if [ $# -lt 5 ]; then
    echo "Usage: submit-spark.sh <allocation> <time> <num_nodes> <queue> <waittime>"
    echo "Example: submit-spark.sh SDAV 08:00:00 12 pubnet-nox11 10"
    exit -1
fi

allocation=$1
time=$2
nodes=$3
queue=$4

x=60; y=10

waittime=$(($5*$((x/y))))

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
        echo "**Removing Cobalt job..."
	qdel $JOBID
	break
}


# submit
JOBID=`qsub -n $nodes -t $time -A $allocation -q ${queue} start-spark.sh`
count=0
while [ ! -e $HOME/spark-hostname.$JOBID ]; do 
  echo "Waiting for Spark to launch..."; sleep $y
  count=$((count+1))
  if [ $count -gt $waittime ]
  then
    echo "Spark failed to launch within $waittime minutes."
    break
  fi
done


