#! /bin/bash
set -u

# Set the directory containing our scripts if unset.
# SCRIPTS_DIR is passed to the job via qsub.
[[ -z ${SCRIPTS_DIR+X} ]] && declare -r SCRIPTS_DIR="$(cd $(dirname "$0")&&pwd)"

declare -r version='SPARK JOB  v1.0.0'
declare -r usage="$version"'

Usage:
	submit-spark.sh [options] [<pyscript> [<pyscript options>]]

Required options:
	-A PROJECT		Allocation name
	-t WALLTIME		Max run time
	-n NODES			Job node count
	-q QUEUE		Queue name

Optional options:
	-w WAITTIME		Time to wait for prompt in minutes (default 30)
	-I				Start an interactive ssh session
	-p <2|3>			Python version (default 3)

Example:
	./submit-spark.sh -A datascience -t 60 -n 2 -q pubnet-debug -w 10
	./submit-spark.sh -A datascience -t 60 -n 2 -q debug $SPARK_HOME/examples/src/main/python/pi.py 10000
'

while getopts IA:t:n:q:w:p: OPT; do
	case $OPT in
	I)	declare -ir	interactive=1;;
	A)	declare -r	allocation="$OPTARG";;
	t)	declare -r	time="$OPTARG";;
	n)	declare -r	nodes="$OPTARG";;
	q)	declare -r	queue="$OPTARG";;
	w)	declare -ir	waittime=$((OPTARG*60));;
	p)	declare -ir	pyversion=$OPTARG;;
	?)	echo "$usage"; exit 1;;
	esac
done

[[ -z ${waittime+X} ]] && declare -ir waittime=$((30*60))
[[ -z ${pyversion+X} ]] && declare -ir pyversion=3

if [[ -z ${allocation+X} || -z ${time+X} || -z ${nodes+X} || -z ${queue+X} ]];then
	echo "$usage"
	exit 1
fi

if ((pyversion != 2 && pyversion != 3));then
	echo "Preconfigured Python version can only be 2 or 3,"
	echo "but got $pyversion."
	echo "Using your custom python version."
	echo "Make sure to set it up for compute nodes."
fi

shift $((OPTIND-1))

declare -a scripts=()

if (($#>0));then
	if [[ -s $1 ]];then
		[[ -z ${interactive+X} ]] && declare -ir interactive=0
		scripts=( "$@" )
		echo "# Submitting job: ${scripts[@]}"
	else
		echo "File does not exist: $1"
		exit 1
	fi
else
	[[ -z ${interactive+X} ]] && declare -ir interactive=1
	echo "Submitting an interactive job and wait for at most $waittime sec."
fi

[[ -d $SCRIPTS_DIR/work ]] || mkdir "$SCRIPTS_DIR/work"

declare -i JOBID=0
mysubmit() {
	# Options to pass to qsub
	local -ar opt=(
		-n $nodes -t $time -A $allocation -q $queue
		--env "SPARKJOB_SCRIPTS_DIR=$SCRIPTS_DIR"
		--env "SPARKJOB_PYVERSION=$pyversion"
		--env "SPARKJOB_INTERACTIVE=$interactive"
		-O "$SCRIPTS_DIR/work/\$jobid"
		"$SCRIPTS_DIR/start-spark.sh"
		"${scripts[@]}"
	)
	JOBID=$(qsub "${opt[@]}")
	if ((JOBID > 0));then
		echo "# Submitted"
		echo "JOBID=$JOBID"
	else
		echo "# Submitting failed."
		exit 1
	fi
}

if ((interactive>0));then
	cleanup(){ ((JOBID>0)) && qdel $JOBID; } 
	trap cleanup 0
	mysubmit
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
		echo "# Spawning bash on host: $MASTER_HOST"
		ssh -t $MASTER_HOST \
			"bash -lic \" \
			export SPARKJOB_JOBID=$JOBID; \
			exec bash --rcfile <(echo ' \
				source ~/.bashrc; \
				source \"$SCRIPTS_DIR/setup.sh\" \
			')\" \
			"
	else
		echo "Spark failed to launch within $((waittime/60)) minutes."
	fi
else
	mysubmit
fi
