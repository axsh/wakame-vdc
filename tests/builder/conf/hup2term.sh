#!/bin/sh

# This script converts HUP signal from parent shell to TERM signal.
# Terminate the running process which can not be halted with HUP (closing at a GNU screen window).
# Usage:
# hup2term.sh /usr/sbin/nginx -g \'daemon off\;\'

trap 'kill -TERM $wpid;' 1

echo "$*"
bash -c "$*" &
wpid=$!
wait $wpid
