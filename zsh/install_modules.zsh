# Install zim modules
# Must be run with zsh

process="$(readlink "/proc/$$/exe")"
if [[ ! "$process" =~ "zsh" ]]; then
    printf "This script is intended to be run only with zsh\n"
    printf "Usage: zsh $0"
    exit 1
fi

if [[ "${ZIM_HOME}x" != "x" ]]; then
    zimfw upgrade
    zimfw install
else
    printf "No ZIM_HOME environment variable is defined, is zim installed?\n"
    exit 1
fi
