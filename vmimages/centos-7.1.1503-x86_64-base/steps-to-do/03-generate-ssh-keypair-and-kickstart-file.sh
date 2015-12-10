#!/bin/bash

[ -d "$CODEDIR" ] && [ -n "$DATADIR" ] || {
    echo "($0)" 1>&2
    echo "This step expects calling script to set up environment" 1>&2
    exit 255
}

$starting_checks "Generate ssh key pair and kickstart file"
[ -f "$DATADIR/ks-sshpair.cfg" ]
$skip_rest_if_already_done
set -e
[ -f "$DATADIR/tmp-sshkeypair" ] || ssh-keygen -f "$DATADIR/tmp-sshkeypair" -N ""
ks_text="$(cat "$CODEDIR/anaconda-ks.cfg")"
sshkey_text="$(cat "$DATADIR/tmp-sshkeypair.pub")"
cat >"$DATADIR/ks-sshpair.cfg" <<EOF
$ks_text

%post
ls -l /root/  >/tmp.listing
mkdir /root/.ssh
chmod 700 /root/.ssh
cat >/root/.ssh/authorized_keys <<EOS
$sshkey_text
EOS
%end
EOF
cp "$CODEDIR/bin/ssh-shortcut.sh" "$DATADIR"
