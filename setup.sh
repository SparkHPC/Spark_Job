# Set the scripts dir if unset.
[[ -z ${SPARKJOB_SCRIPTS_DIR+X} ]] \
	&& declare -r SPARKJOB_SCRIPTS_DIR="$(cd $(dirname "$BASH_SOURCE")&&pwd)"

# Set the working dir if unset, requires JOBID
if [[ -z ${SPARKJOB_WORKING_DIR+X} ]];then
	if [[ -z ${SPARKJOB_JOBID+X} ]];then
		echo "Error: SPARKJOB_JOBID required for setup.sh"
		exit 1
	else
		declare -r SPARKJOB_WORKING_DIR="$SPARKJOB_SCRIPTS_DIR/work/$SPARKJOB_JOBID"
	fi
fi

source "$SPARKJOB_SCRIPTS_DIR/env.sh"

# Allow SPARKJOB_WORKING_ENVS to overwrite preset env.sh
SPARKJOB_WORKING_ENVS="$SPARKJOB_WORKING_DIR/envs"
[[ -s $SPARKJOB_WORKING_ENVS ]] && source "$SPARKJOB_WORKING_ENVS"
