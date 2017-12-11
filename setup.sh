# Set the working dir (default the directory containing this script) if unset.
[[ -z ${WORKING_DIR+X} ]] \
	&& declare -r WORKING_DIR="$(cd $(dirname "$BASH_SOURCE");pwd)"
export WORKING_DIR

[[ $WORKING_DIR/soft_env.cache.sh -ot $WORKING_DIR/soft_env ]] \
	&& /soft/environment/softenv-1.6.2/bin/soft-msc "$WORKING_DIR/soft_env"
source "$WORKING_DIR/soft_env.cache.sh"
source "$WORKING_DIR/env.sh"

(($#>0)) && [[ -s $WORKING_DIR/run/control.$1 ]] \
	&& source "$WORKING_DIR/run/control.$1"
