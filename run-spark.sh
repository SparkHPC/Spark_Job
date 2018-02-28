#! /bin/bash
set -u

# This script has to be run on the actual compute node for master.
# It is designed to be called from start-spark.sh

source "$SPARKJOB_SCRIPTS_DIR/setup.sh"

if [[ ! -s $SPARK_CONF_DIR/slaves ]];then
	echo "Unable to get the slave file: $SPARK_CONF_DIR/slaves"
	exit 1
fi

ssh(){	# Intercept ssh call to pass more envs.  Requires spark using bash.
	# This is a exported function.  Any global variables used here should be exported.
	#echo "[[ Hijacked ssh: $@ from host $(hostname)]"
	#export -p | grep SPARK
	#echo "]"
	local -a os cs
	while [[ $1 == -* ]];do
		os+=("$1" "$2")
		shift 2
	done
	local -r h="$1";shift
	local -ar cs=("$@")
	#echo "Saving ssh output to $SPARKJOB_WORKING_DIR/ssh.$h.output"
	#echo "Saving ssh error to $SPARKJOB_WORKING_DIR/ssh.$h.error"
	# ControlMaster has issues with compute nodes
	/usr/bin/ssh -o ControlMaster=no \
		"${os[@]}" "$h" "bash -lc \"
		SPARKJOB_HOST='$SPARKJOB_HOST' ; 
		SPARKJOB_SCRIPTS_DIR='$SPARKJOB_SCRIPTS_DIR' ; 
		SPARKJOB_WORKING_DIR='$SPARKJOB_WORKING_DIR' ; 
		SPARKJOB_PYVERSION='$SPARKJOB_PYVERSION' ; 
		source '$SPARKJOB_SCRIPTS_DIR/setup.sh' ; 
		${cs[@]} \""
	#	>>'$SPARKJOB_WORKING_DIR/ssh.$h.output' 
	#	2>>'$SPARKJOB_WORKING_DIR/ssh.$h.error'\""
	local -ir st=$?
	#echo "[ Hijacked ssh returned with status: $st]"
	if ((st==0)) && [[ $h == $(hostname)* ]];then
	{
		declare -p | grep SPARK	# Get SPARK related envs.
		echo "declare -x SPARK_MASTER_URI=${cs[${#cs[@]}-1]}"
		echo "declare -x MASTER_HOST=$(hostname)"
	} > "$SPARKJOB_WORKING_ENVS"
	fi
	return $st
}
export -f ssh

# export SPARK_SSH_FOREGROUND=yes
$SPARK_HOME/sbin/start-all.sh

if (($#>0));then	# We have jobs to submit
	source "$SPARKJOB_SCRIPTS_DIR/setup.sh"
	if ((SPARKJOB_SCRIPTMODE>0));then
		"$@"
	elif [[ $1 == run-example ]];then
		"$SPARK_HOME/bin/spark-submit" run-example --master $SPARK_MASTER_URI "${@:2}"
	else
		export PYSPARK_DRIVER_PYTHON="$PYSPARK_PYTHON"
		export PYSPARK_DRIVER_PYTHON_OPTS=""
		"$SPARK_HOME/bin/spark-submit" --master $SPARK_MASTER_URI "$@"
	fi
fi

if ((SPARKJOB_INTERACTIVE>0));then	# Keep interactive jobs running
	while true;do sleep 15;done
fi
