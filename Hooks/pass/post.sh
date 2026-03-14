## This is a placeholder script with instructions for how to complete it.

## This script should follow the format of the other scripts.


# Clone password database project as ~/.password-database if it doesn't already exist.

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
LOG_FILE="$LOG_DIR/pass-hook.log"

# Git clone the repos from $TUCKR_USER_CONFIG/pass/repos
# the line is separted by a comma.  The first field is the git repo, second field is the target directory relative to $HOME

# mise should have already installed docker-credential-pass, and the ~/.docker/config.json should already be available

# If `pass show docker-credential-helpers/docker-pass-initialized-check` doesn't exist or doesn't return "pass is initialized"
# then add it.

exit 0
