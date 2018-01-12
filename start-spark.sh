#! /bin/bash
set -u

export JOBID=$COBALT_JOBID    # Change it for other job system

# Set the directory containing our scripts if unset.
# SCRIPTS_DIR is passed to the job via qsub.
[[ -z ${SCRIPTS_DIR+X} ]] && declare -r SCRIPTS_DIR="$(cd $(dirname "$0");pwd)"
export SCRIPTS_DIR

source "$SCRIPTS_DIR/setup.sh"

[[ -d $SPARK_WORKER_DIR ]] || mkdir -p "$SPARK_WORKER_DIR"
[[ -d $SPARK_CONF_DIR ]] || mkdir -p "$SPARK_CONF_DIR"
[[ -d $SPARK_LOG_DIR ]] || mkdir -p "$SPARK_LOG_DIR"

ssh(){	# Intercept ssh call to pass more envs.  Requires spark using bash.
	local -ar as=("$@"); local -i i
	echo "EXE@$(hostname -f): ssh";for ((i=0;i<$#;++i));do echo "	$i: '${as[i]}'";done
	local -a os cs
	while [[ $1 == -* ]];do
		os+=("$1" "$2")
		shift 2
	done
	local -r h="$1";shift
	local -ar cs=("$@")
	/usr/bin/ssh "${os[@]}" "$h" \
		export "SCRIPTS_DIR='$SCRIPTS_DIR'" \; \
		export "WORKING_DIR='$WORKING_DIR'" \; \
		source "'$SCRIPTS_DIR/setup.sh'" \; \
		"${cs[@]}"
	local -ir st=$?
	if ((st==0)) && [[ $h == $(hostname).* ]];then
	{
		declare -p | grep SPARK
		echo "declare -x SPARK_MASTER_URI=${cs[${#cs[@]}-1]}"
		echo "declare -x MASTER_HOST=$(hostname)"
	} > "$WORKING_ENVS"
	fi
	return $st
}
export -f ssh

cp "$COBALT_NODEFILE" "$SPARK_CONF_DIR/slaves"

$SPARK_HOME/sbin/start-all.sh

if (($#>0));then	# Assuming non-interative jobs
	source "$SCRIPTS_DIR/setup.sh"
	export PYSPARK_DRIVER_PYTHON="$PYSPARK_PYTHON"
	export PYSPARK_DRIVER_PYTHON_OPTS=""
	"$SPARK_HOME/bin/spark-submit" --master $SPARK_MASTER_URI "$@"
else	#keep non-interactive job running
	while true;do sleep 5;done
fi
