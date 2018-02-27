# Set the scripts dir if unset.
[[ -z ${SPARKJOB_SCRIPTS_DIR+X} ]] \
	&& declare SPARKJOB_SCRIPTS_DIR="$(cd $(dirname "$BASH_SOURCE")&&pwd)"

# Set the working dir if unset, requires JOBID
if [[ -z ${SPARKJOB_WORKING_DIR+X} ]];then
	if [[ -z ${SPARKJOB_JOBID+X} ]];then
		echo "Error: SPARKJOB_JOBID required for setup.sh"
		exit 1
	else
		declare SPARKJOB_WORKING_DIR="$SPARKJOB_OUTPUTDIR/$SPARKJOB_JOBID"
	fi
fi
export SPARKJOB_WORKING_DIR

source "$SPARKJOB_SCRIPTS_DIR/env.sh"

# Allow SPARKJOB_WORKING_ENVS to overwrite preset env.sh
export SPARKJOB_WORKING_ENVS="$SPARKJOB_WORKING_DIR/envs"
[[ -s $SPARKJOB_WORKING_ENVS ]] && source "$SPARKJOB_WORKING_ENVS"
