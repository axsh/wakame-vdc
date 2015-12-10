#!/bin/bash

[ -d "$CODEDIR" ] && [ -n "$DATADIR" ] || {
    echo "($0)" 1>&2
    echo "This step expects calling script to set up environment" 1>&2
    exit 255
}

$starting_checks "Create output directory"
[ -d "$DATADIR" ]
$skip_rest_if_already_done
set -e
mkdir "$DATADIR"
