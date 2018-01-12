# Set the scripts dir if unset.
[[ -z ${SCRIPTS_DIR+X} ]] \
	&& declare -r SCRIPTS_DIR="$(cd $(dirname "$BASH_SOURCE");pwd)"
export SCRIPTS_DIR

[[ $SCRIPTS_DIR/soft_env.cache.sh -ot $SCRIPTS_DIR/soft_env ]] \
	&& HOME='' /soft/environment/softenv-1.6.2/bin/soft-msc "$SCRIPTS_DIR/soft_env"
source "$SCRIPTS_DIR/soft_env.cache.sh"

# Set the working dir if unset, requires JOBID
if [[ -z ${WORKING_DIR+X} ]];then
	if [[ -z ${JOBID+X} ]];then
		echo "Error: JOBID required for setup.sh"
		exit 1
	else
		export WORKING_DIR="$SCRIPTS_DIR/work/$JOBID"
	fi
fi

source "$SCRIPTS_DIR/env.sh"

# Allow WORKING_ENVS to overwrite preset env.sh
export WORKING_ENVS="$WORKING_DIR/envs"
[[ -s $WORKING_ENVS ]] && source "$WORKING_ENVS"
