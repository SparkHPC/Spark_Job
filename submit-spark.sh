#! /bin/bash
set -u

# Set the working dir (default the directory containing this script) if unset.
# WORKING_DIR is passed to the job via qsub.
[[ -z ${WORKING_DIR+X} ]] && declare -r WORKING_DIR="$(cd $(dirname "$0");pwd)"
export WORKING_DIR

if (($#<5)); then
	echo 'Usage:'
	echo '	Non-interactive:'
	echo '	submit-spark.sh <allocation> <time> <num_nodes> <queue> <pyscript> [args ...]'
	echo '	Interactive:'
	echo '	submit-spark.sh <allocation> <time> <num_nodes> <queue> <waittime/min>'
	echo 'Example:'
	echo '	./submit-spark.sh datascience 60 2 pubnet-debug 10'
	echo '	./submit-spark.sh datascience 60 2 debug $SPARK_HOME/examples/src/main/python/pi.py 10000'
	exit -1
fi

allocation=$1
time=$2
nodes=$3
queue=$4
shift 4

if [[ -s $1 ]];then
	echo "Submitting a non-interactive job: $@"
	interactive=0
else
	echo "Submitting an interactive job and wait for at most $1 min."
	interactive=1
	((waittime=$1*60))
fi

[[ -d $WORKING_DIR/run ]] || mkdir -p "$WORKING_DIR/run"

opt=(--env "WORKING_DIR=$WORKING_DIR")
opt+=(-O "$WORKING_DIR/run/\$jobid")

js="$WORKING_DIR/start-spark.sh"

declare -i JOBID=0
if ((interactive>0));then
	declare -i QDEL=1
	cleanup(){ ((QDEL>0 && JOBID>0)) && qdel $JOBID; } 
	trap cleanup 0
	JOBID=$(qsub -n $nodes -t $time -A $allocation -q ${queue} "${opt[@]}" "$js")
	declare -i mywait=10 count=0
	echo "Waiting for Spark to launch..."
	for ((count=0;count<waittime;count+=mywait));do
		if [[ -s $WORKING_DIR/run/control.$JOBID ]];then
			QDEL=0
			break
		fi
		sleep $mywait
	done
	if [[ -s $WORKING_DIR/run/control.$JOBID ]];then
		source "$WORKING_DIR/run/control.$JOBID"
		echo "# Spark is now running (JOBID=$JOBID) on:"
		sed 's/^/# /' "$SPARK_SLAVES"
		declare -p SPARK_MASTER_URI
	else
		echo "Spark failed to launch within $((waittime/60)) minutes."
	fi
else
	JOBID=$(qsub -n $nodes -t $time -A $allocation -q ${queue} "${opt[@]}" "$js" "$@")
	echo "Submitted jobid: $JOBID"
fi
