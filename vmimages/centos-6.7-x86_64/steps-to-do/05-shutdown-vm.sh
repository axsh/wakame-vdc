#!/bin/bash

[ -d "$CODEDIR" ] && [ -n "$DATADIR" ] || {
    echo "($0)" 1>&2
    echo "This step expects calling script to set up environment" 1>&2
    exit 255
}

$starting_checks "Shutdown VM for public image installation"
[ -f "$DATADIR/flag-shutdown" ]
$skip_rest_if_already_done
set -e
kill -0 $(< "$DATADIR/kvm.pid") 2>/dev/null || \
    reportfailed "Expecting KVM process to be running now"
# the next ssh always returns error, so mask it from set -e
"$DATADIR/ssh-shortcut.sh" shutdown -P now || true
for (( i=1 ; i<20 ; i++ )); do
    kill -0 $(< "$DATADIR/kvm.pid") 2>/dev/null || break
    echo "$i/20 - Waiting 2 more seconds for KVM to exit..."
    sleep 2
done
kill -0 $(< "$DATADIR/kvm.pid") 2>/dev/null && exit 1
touch "$DATADIR/flag-shutdown"
