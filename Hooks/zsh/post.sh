#!/bin/bash
pushd "$HOME" &>/dev/null || exit 1
# This can't work until after credentials exist
# TODO: figure out another way
# doppler secrets download --no-file --format env > .env
popd &>/dev/null
