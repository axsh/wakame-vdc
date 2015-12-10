#!/bin/bash

[ -d "$CODEDIR" ] && [ -n "$DATADIR" ] || {
    echo "($0)" 1>&2
    echo "This step expects calling script to set up environment" 1>&2
    exit 255
}

$starting_checks "Extract minimal image to start public image build"
[ -f "$DATADIR/minimal-image.raw" ]
$skip_rest_if_already_done
set -e
cd "$DATADIR"
cp "$CODEDIR/base-image-dir/runscript.sh" .
cp "$CODEDIR/base-image-dir/tmp-sshkeypair" .
cp "$CODEDIR/base-image-dir/ssh-shortcut.sh" .
tar xzvf "$CODEDIR/base-image-dir/minimal-image.raw.tar.gz"
sed -i 's/tmp.raw/minimal-image.raw/' "./runscript.sh"
