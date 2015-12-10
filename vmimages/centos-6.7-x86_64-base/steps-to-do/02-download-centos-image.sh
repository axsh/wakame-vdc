#!/bin/bash

[ -d "$CODEDIR" ] && [ -n "$DATADIR" ] || {
    echo "($0)" 1>&2
    echo "This step expects calling script to set up environment" 1>&2
    exit 255
}

source "$CODEDIR/build.conf"

$starting_checks "Download CentOS ISO install image"
[ -f "$DATADIR/$CENTOSISO" ] &&
    [[ "$(< "$DATADIR/$CENTOSISO.md5")" = *$ISOMD5* ]]
$skip_rest_if_already_done
set -e
if [ -f "$CODEDIR/$CENTOSISO" ]; then
    # to avoid the download while debugging
    cp -al "$CODEDIR/$CENTOSISO" "$DATADIR/$CENTOSISO"
else
    curl --fail "$CENTOSMIRROR/$CENTOSISO" -o "$DATADIR/$CENTOSISO"
fi
md5sum "$DATADIR/$CENTOSISO" >"$DATADIR/$CENTOSISO.md5"
