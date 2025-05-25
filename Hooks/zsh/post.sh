#!/bin/bash
pushd "$HOME" &>/dev/null || exit 1
# doppler secrets download --no-file --format env > .env
popd &>/dev/null
