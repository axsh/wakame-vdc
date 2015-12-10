#!/bin/bash

[ -d "$CODEDIR" ] && [ -n "$DATADIR" ] || {
    echo "($0)" 1>&2
    echo "This step expects calling script to set up environment" 1>&2
    exit 255
}

######################################################################
## Functions
######################################################################

# This function is piped and run through ssh below
patch-wakame-init()
{
    org="$(cat /etc/wakame-init)"
    beforeNICequals="${org%nic=*}"
    afterNICequals="${org##*nic=}"
    # Now rewrite the line by inserting new code and commenting out the old code
    {
	echo -n "$beforeNICequals"
	# the grep will output something like this: /sys/class/net/nestbr0/address:b6:21:21:a2:8f:bf
	echo -n 'IFS=/ read xempty xsys xclass xnet nic therest <<<"$(grep "$mac" /sys/class/net/*/address)" ## '
	echo  "$afterNICequals"
    } >/etc/wakame-init
}


$starting_checks "Install wakame-init to public image"
[ -f "$DATADIR/flag-wakame-init-installed" ]
$skip_rest_if_already_done
set -e
repoURL=https://raw.githubusercontent.com/axsh/wakame-vdc/develop/rpmbuild/yum_repositories/wakame-vdc-stable.repo
"$DATADIR/ssh-shortcut.sh" curl "$repoURL" -o /etc/yum.repos.d/wakame-vdc-stable.repo --fail
"$DATADIR/ssh-shortcut.sh" yum install -y net-tools
"$DATADIR/ssh-shortcut.sh" yum install -y wakame-init
"$DATADIR/ssh-shortcut.sh" <<<"$(declare -f patch-wakame-init; echo patch-wakame-init)"
touch "$DATADIR/flag-wakame-init-installed"
