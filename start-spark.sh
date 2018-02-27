#! /bin/bash
set -u

export SPARKJOB_JOBID=$COBALT_JOBID    # Change it for other job system

# Set the directory containing our scripts if unset.
# SPARKJOB_SCRIPTS_DIR is passed to the job via qsub.
[[ -z ${SPARKJOB_SCRIPTS_DIR+X} ]] &&
	declare SPARKJOB_SCRIPTS_DIR="$(cd $(dirname "$0")&&pwd)"
export SPARKJOB_SCRIPTS_DIR
[[ -z ${SPARKJOB_PYVERSION+X} ]] && declare -i SPARKJOB_PYVERSION=3
export SPARKJOB_PYVERSION

# Envs that passed to us only for this script
[[ -z ${SPARKJOB_INTERACTIVE+X} ]] && declare -i SPARKJOB_INTERACTIVE=0
[[ -z ${SPARKJOB_SCRIPTMODE+X} ]] && declare -i SPARKJOB_SCRIPTMODE=0

source "$SPARKJOB_SCRIPTS_DIR/setup.sh"

[[ -d $SPARK_WORKER_DIR ]] || mkdir -p "$SPARK_WORKER_DIR"
[[ -d $SPARK_CONF_DIR ]] || mkdir -p "$SPARK_CONF_DIR"
[[ -d $SPARK_LOG_DIR ]] || mkdir -p "$SPARK_LOG_DIR"

ssh(){	# Intercept ssh call to pass more envs.  Requires spark using bash.
	# This is a exported function.  Any global variables used here should be exported.
	local -a os cs
	while [[ $1 == -* ]];do
		os+=("$1" "$2")
		shift 2
	done
	local -r h="$1";shift
	local -ar cs=("$@")
	/usr/bin/ssh "${os[@]}" "$h" \
		"SPARKJOB_SCRIPTS_DIR='$SPARKJOB_SCRIPTS_DIR'" \; \
		"SPARKJOB_WORKING_DIR='$SPARKJOB_WORKING_DIR'" \; \
		"SPARKJOB_PYVERSION='$SPARKJOB_PYVERSION'" \; \
		source "'$SPARKJOB_SCRIPTS_DIR/setup.sh'" \; \
		"${cs[@]}"
	local -ir st=$?
	if ((st==0)) && [[ $h == $(hostname).* ]];then
	{
		declare -p | grep SPARK	# Get SPARK related envs.
		echo "declare -x SPARK_MASTER_URI=${cs[${#cs[@]}-1]}"
		echo "declare -x MASTER_HOST=$(hostname)"
	} > "$SPARKJOB_WORKING_ENVS"
	fi
	return $st
}
export -f ssh

cp "$COBALT_NODEFILE" "$SPARK_CONF_DIR/slaves"

$SPARK_HOME/sbin/start-all.sh

if (($#>0));then	# We have jobs to submit
	source "$SPARKJOB_SCRIPTS_DIR/setup.sh"
	if ((SPARKJOB_SCRIPTMODE==0));then
		if [[ $1 =~ \.py$ ]];then
			export PYSPARK_DRIVER_PYTHON="$PYSPARK_PYTHON"
			export PYSPARK_DRIVER_PYTHON_OPTS=""
			"$SPARK_HOME/bin/spark-submit" --master $SPARK_MASTER_URI "$@"
		elif [[ $1 =~ \.jar$ ]];then
			"$SPARK_HOME/bin/spark-submit" --master $SPARK_MASTER_URI "$@"
		else
			"$@"
		fi
	else
		"$@"
	fi
fi

if ((SPARKJOB_INTERACTIVE>0));then	# Keep interactive jobs running
	while true;do sleep 15;done
fi
