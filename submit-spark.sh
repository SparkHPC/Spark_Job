#! /bin/bash
set -u

# Set the directory containing our scripts if unset.
# SCRIPTS_DIR is passed to the job via qsub.
[[ -z ${SCRIPTS_DIR+X} ]] && declare -r SCRIPTS_DIR="$(cd $(dirname "$0");pwd)"
export SCRIPTS_DIR
 
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

# Options to pass to qsub
opt=(--env "SCRIPTS_DIR=$SCRIPTS_DIR")
opt+=(-O "$SCRIPTS_DIR/work/\$jobid")

[[ -d $SCRIPTS_DIR/work ]] || mkdir "$SCRIPTS_DIR/work"

js="$SCRIPTS_DIR/start-spark.sh"

declare -i JOBID=0
if ((interactive>0));then
	cleanup(){ ((JOBID>0)) && qdel $JOBID; } 
	trap cleanup 0
	JOBID=$(qsub -n $nodes -t $time -A $allocation -q ${queue} "${opt[@]}" "$js")
	if ((JOBID > 0));then
		echo "Submitted JOBID=$JOBID"
	else
		echo "Submitting failed."
		exit 1
	fi
	declare -r envs="$SCRIPTS_DIR/work/$JOBID/envs"
	declare -r slaves="$SCRIPTS_DIR/work/$JOBID/conf/slaves"
	declare -i mywait=10 count=0
	echo "Waiting for Spark to launch..."
	for ((count=0;count<waittime;count+=mywait));do
		[[ ! -s $envs ]] || break
		sleep $mywait
	done
	if [[ -s $envs ]];then
		source "$envs"
		echo "# Spark is now running (JOBID=$JOBID) on:"
		column "$slaves" | sed 's/^/# /'
		declare -p SPARK_MASTER_URI
		echo "# Entering host: $MASTER_HOST"
		ssh -t $MASTER_HOST \
			"bash -c \
			'export JOBID=$JOBID; \
			source \"$SCRIPTS_DIR/setup.sh\"; \
			exec $SHELL -l'"
	else
		echo "Spark failed to launch within $((waittime/60)) minutes."
	fi
else
	JOBID=$(qsub -n $nodes -t $time -A $allocation -q ${queue} "${opt[@]}" "$js" "$@")
	if ((JOBID > 0));then
		echo "Submitted JOBID=$JOBID"
	else
		echo "Submitting failed."
		exit 1
	fi
fi
