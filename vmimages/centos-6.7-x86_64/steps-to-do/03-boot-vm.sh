#!/bin/bash

[ -d "$CODEDIR" ] && [ -n "$DATADIR" ] || {
    echo "($0)" 1>&2
    echo "This step expects calling script to set up environment" 1>&2
    exit 255
}

$starting_checks "Boot VM to set up for installing public extras"
[ -f "$DATADIR/flag-wakame-init-installed" ] ||
    {
	[ -f "$DATADIR/kvm.pid" ] &&
	    kill -0 $(< "$DATADIR/kvm.pid") 2>/dev/null
    }
$skip_rest_if_already_done
set -e
cd "$DATADIR/"
./runscript.sh >kvm.stdout 2>kvm.stderr &
echo "$!" >"$DATADIR/kvm.pid"
sleep 10
kill -0 $(< "$DATADIR/kvm.pid")
for (( i=1 ; i<20 ; i++ )); do
    tryssh="$("$DATADIR/ssh-shortcut.sh" echo it-worked)" || :
    [ "$tryssh" = "it-worked" ] && break
    echo "$i/20 - Waiting 10 more seconds for ssh to connect..."
    sleep 10
done
[[ "$tryssh" = "it-worked" ]]
