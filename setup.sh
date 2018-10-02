# It should be alright to source me multiple times.

# Set the scripts dir if unset.
[[ -z ${SPARKJOB_SCRIPTS_DIR+X} ]] \
	&& declare SPARKJOB_SCRIPTS_DIR="$(cd $(dirname "$BASH_SOURCE")&&pwd)"

# Set the working dir if unset, requires JOBID
if [[ -z ${SPARKJOB_WORKING_DIR+X} ]];then
	if [[ -z ${SPARKJOB_JOBID+X} ]];then
		echo "Error: SPARKJOB_JOBID required for setup.sh"
		exit 1
	elif [[ -z ${SPARKJOB_OUTPUT_DIR+X} ]];then
		echo "Error: SPARKJOB_OUTPUT_DIR required for setup.sh"
		exit 1
	else
		declare SPARKJOB_WORKING_DIR="$SPARKJOB_OUTPUT_DIR/$SPARKJOB_JOBID"
	fi
fi
export SPARKJOB_WORKING_DIR

if [[ -z ${SPARKJOB_HOST+X} ]];then
	echo "Error: SPARKJOB_HOST required for setup.sh"
	exit 1
else
	source "$SPARKJOB_SCRIPTS_DIR/env_$SPARKJOB_HOST.sh"
fi
[[ -s $SPARKJOB_OUTPUT_DIR/env_local.sh ]] &&
	source "$SPARKJOB_OUTPUT_DIR/env_local.sh"

# Allow SPARKJOB_WORKING_ENVS to overwrite preset env.sh
export SPARKJOB_WORKING_ENVS="$SPARKJOB_WORKING_DIR/envs"
[[ -s $SPARKJOB_WORKING_ENVS ]] && source "$SPARKJOB_WORKING_ENVS"
