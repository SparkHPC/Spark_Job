#! /bin/bash
set -u

# Set the working dir (default the directory containing this script) if unset.
[[ -z ${WORKING_DIR+X} ]] && declare -r WORKING_DIR="$(cd $(dirname "$0");pwd)"
export WORKING_DIR
source "$WORKING_DIR/setup.sh"
export SPARK_SLAVES="${SPARK_CONF_DIR}/slaves.${COBALT_JOBID}"

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
		export "WORKING_DIR='$WORKING_DIR'" \; \
		source "'$WORKING_DIR/setup.sh'" \; \
		"${cs[@]}"
	local -ir st=$?
	if ((st==0)) && [[ $h == $(hostname).* ]];then
		[[ -d $WORKING_DIR/run ]] || mkdir -p "$WORKING_DIR/run"
	{
		declare -p | grep SPARK
		echo "declare -x SPARK_MASTER_URI=${cs[${#cs[@]}-1]}"
	} > "$WORKING_DIR/run/control.$COBALT_JOBID"
	fi
	return $st
}
export -f ssh

cp "$COBALT_NODEFILE" "$SPARK_SLAVES"

$SPARK_HOME/sbin/start-all.sh

if (($#>0));then	# Assuming non-interative jobs
	source "$WORKING_DIR/setup.sh" $COBALT_JOBID
	export PYSPARK_DRIVER_PYTHON="$PYSPARK_PYTHON"
	export PYSPARK_DRIVER_PYTHON_OPTS=""
	"$SPARK_HOME/bin/spark-submit" --master $SPARK_MASTER_URI "$@"
else	#keep non-interactive job running
	while true;do sleep 5;done
fi
