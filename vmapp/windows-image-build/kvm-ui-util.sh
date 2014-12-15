#!/bin/bash

# don't run unless $KILLPGOK is set or this script is the process leader
[ -n "$KILLPGOK" ] ||  kill -0 -$$ || {
	echo "((Read the first part of this script to understand its error handling))" 1>&2
	exit 255
    }

export KILLPGOK=yes  # allow for all scripts called by this script to be killed on error

reportfail()
{
    # The goal is to make this function simply (i.e. always) terminate
    # not only this script but also *all* related scripts and
    # processes.  A simple "exit" can be hidden by subprocesses,
    # therefore this function sends SIGTERM to all processes in the
    # same process group as the process that caught the error.  If the
    # process calling this script wants to receive SIGTERM, it should
    # set $KILLPGOK to "yes".  If not, it should call this script with
    # setsid.  Similarly, this script can also use setsid to protect
    # processes that it starts from termination when it makes sense.
    echo "Failed...terminating process group. ($*)" 1>&2
    kill -TERM 0  # see man kill(2), should kill all processes in same process group

    echo "This line should not be reached." 1>&2 ; exit 255
}

try() { eval "$@" || reportfail "$@,$?" ; }

trap 'echo "pid=$BASHPID exiting" 1>&2 ; exit 255' TERM  # feel free to specialize this

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail


usage() {
    cat <<'EOF'
This is an interesting hack.  Read the source!

Note, environment variables KVMPID, KVMVNC, and KVMMON must be set.
If "./thisrun" is a symbolic link to a directory, then an attempt will be
made to get the values from that directory.

Intended use:

source ./kvm-ui-util.sh

if kvm-ui-check ctrl-alt-del-screen; then
    kvm-ui-simulate press-ctrl-alt-del
fi

EOF
}

check-required-env()  # also sets defaults if run in Windows build environment
{
    if [ -z "$KVMPID" ]; then
	[ -n "$trdir" ] && KVMPID="$(< "$trdir/kvm.pid")"
    fi
    [ -n "$KVMPID" ] || reportfail "KVMPID must be set to the KVM's pid"

    if [ -z "$KVMMON" ]; then
	[ -n "$trdir" ] && KVMMON="$(< "$trdir/kvm.mon")"
    fi 
    [ -n "$KVMMON" ] || reportfail "KVMMON must be set to the KVM's monitor port"

    if [ -z "$KVMVNC" ]; then
	[ -n "$trdir" ] && KVMVNC="$(< "$trdir/kvm.vnc")"
    fi 
    [ -n "$KVMVNC" ] || reportfail "KVMVNC must be set to the KVM's VNC port"
}

kvm-ui-feed-slowly-via-vnc()
{
    # This function creates a slowed-down pipe that makes it possible to send
    # captured VNC protocol directly to KVM.

    # Warning: This has failed when the stream was delivered too fast
    # *or* too slow.  The values below (send 10 bytes about every 1ms)
    # have worked well so far, but have not been tested methodically.
   
    # Note: VNC binary inputs can be captured by using netcat and tee to
    # redirect vncviewer streams to a file.

    check-required-env
    pat='*0+0 records in*' # when this pattern appears in dd stderr, quit
    echo "Begin send to VNC" 1>&2
    ( set +x # never trace this part
      touch /tmp/$$-for-kvm-ui
      exec 99> >(while read ln; do
		     if [[ "$ln" == $pat ]]; then
			 rm /tmp/$$-for-kvm-ui ; exit
		     fi
		 done )
      while [ -f /tmp/$$-for-kvm-ui ]; do
	  dd bs=10 count=1 2>&99
	  sleep 0.01
      done | nc 127.0.0.1 $KVMVNC >/dev/null
    )
    echo "End send to VNC" 1>&2
}

kvm-ui-take-screenshot()
{
    check-required-env
    dumptime="$(date +%y%m%d-%H%M%S)"  # assume not more than one dump per second
    [ -z "$trdir" ] && trdir=/tmp
    fname="$trdir/screendump-$dumptime.ppm"
    echo "screendump $fname" | nc 127.0.0.1 $KVMMON 1>/dev/null
    sleep 1
    gzip "$trdir/screendump-$dumptime.ppm"
    echo "$trdir/screendump-$dumptime.ppm".gz
}

kvm-ui-simulate()
{
    simulateName="$1"
    eval declare -f "kvm-ui-simulate-$1" >/dev/null || reportfail "$simulateName not declared"
    check-required-env
    eval "kvm-ui-simulate-$1"
}

kvm-ui-check()
{
    checkName="$1"
    eval declare -f "kvm-ui-check-$1" >/dev/null || reportfail "$checkName not declared"
    check-required-env
    eval "kvm-ui-check-$1"
}

kvm-ui-main()
{
    cmd="$1"
    shift
    case "$cmd" in
	simulate | sim*)
	    kvm-ui-simulate "$@"
	    ;;
	check | ch*)
	    kvm-ui-check "$@"
	    ;;
	source)
	    :
	    ;;
	*)
	    reportfail "First param must be simulate, check, or source (for sourcing functions into another script)"
	    ;;
    esac
}

# simple built in functions:
kvm-ui-simulate-press-ctrl-alt-del()
{
    echo sendkey ctrl-alt-delete | nc 127.0.0.1 "$KVMMON"
}

kvm-ui-simulate-press-return()
{
    echo sendkey ret | nc 127.0.0.1 "$KVMMON"
}

kvm-ui-simulate-type-date-return()
{
    # just to test VNC piping code:
    base64 -d  <<EOF | kvm-ui-feed-slowly-via-vnc
UkZCIDAwMy4wMDgKAQAAAAAACAYAAQADAAMAAwQCAAAAAAIAAAf///8R////IQAAABAAAAABAAAA
BQAAAAIAAAAAAwAAAAAAAyACWAAAAAAgGAABAP8A/wD/EAgAAAAAAwAAAAAAAyACWAMBAAAAAAMg
AlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYBQACsgABBQACsgAEBQAC
sgAHBQACsgAJAwEAAAAAAyACWAUAArIADgUAArIAEwMBAAAAAAMgAlgFAAKzABoFAAKzACMFAAK0
ACwDAQAAAAADIAJYBQACtAAxBQACtAA0AwEAAAAAAyACWAUAArYAOQUAArYAOgUAArYAPwMBAAAA
AAMgAlgFAAK1AEMFAAK1AEcDAQAAAAADIAJYBQACtQBLBQACtABQAwEAAAAAAyACWAUAArQAVAUA
ArQAVgUAArMAWAMBAAAAAAMgAlgFAAKzAFkDAQAAAAADIAJYAwEAAAAAAyACWAUAArMAWgUAArIA
WwMBAAAAAAMgAlgEAQAAAAAAZAMBAAAAAAMgAlgEAAAAAAAAZAQBAAAAAABhAwEAAAAAAyACWAMB
AAAAAAMgAlgEAQAAAAAAdAQAAAAAAABhAwEAAAAAAyACWAQBAAAAAABlAwEAAAAAAyACWAQAAAAA
AAB0BAAAAAAAAGUDAQAAAAADIAJYBAEAAAAA/w0DAQAAAAADIAJYAwEAAAAAAyACWAQAAAAAAP8N
BQACsQBcAwEAAAAAAyACWAUAArEAWwUAArIAWgMBAAAAAAMgAlgFAAKyAFkFAAKzAFgFAAKzAFcF
AAK0AFQFAAK1AFAFAAK1AEwDAQAAAAADIAJYBQACtgBIBQACtwBDAwEAAAAAAyACWAUAArkAPwUA
AroAPQMBAAAAAAMgAlgFAAK8ADoFAAK+ADcFAALDADADAQAAAAADIAJYBQACzAAlBQAC1QAaAwEA
AAAAAyACWAUAAt4AEQUAAuYACwMBAAAAAAMgAlgFAALoAAkDAQAAAAADIAJYBQAC6gAIBQAC7QAG
BQAC8QAFAwEAAAAAAyACWAUAAvQAAwUAAvcAAAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyAC
WAMBAAAAAAMgAlg=
EOF
}

kvm-ui-check-is-running()
{
    kill -0 "$KVMPID"
}

# more verbose checks and simultations in a separate file:
[ -f "$SCRIPT_DIR/kvm-ui-defaults" ] && { source "$SCRIPT_DIR/kvm-ui-defaults" || exit ; }

kvm-ui-main "$@"
