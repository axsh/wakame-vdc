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

evalcheck() { eval "$@" || reportfail "$@,rc=$?" ; }

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
	[ -n "$build_dir" ] && KVMPID="$(< "$build_dir/kvm.pid")"
    fi
    [ -n "$KVMPID" ] || reportfail "KVMPID must be set to the KVM's pid"

    if [ -z "$KVMMON" ]; then
	[ -n "$build_dir" ] && KVMMON="$(< "$build_dir/kvm.mon")"
    fi 
    [ -n "$KVMMON" ] || reportfail "KVMMON must be set to the KVM's monitor port"

    if [ -z "$KVMVNC" ]; then
	[ -n "$build_dir" ] && KVMVNC="$(< "$build_dir/kvm.vnc")"
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

kvm-ui-record-raw-vnc-protocol()
{
    theip="$1"
    theport="$2"
    
    tf="$(mktemp -d /tmp/kvmutils.XXXXXX)/kvm-ui-fifo"
    mkfifo "$tf"
    exec 22> >(cat >"$tf")
    exec 44< "$tf"  # will block until cat's shell opens the fifo
    rm -fr "${tf%/*}" # so OK to delete

    lport=5955
    [ "$localport" != "" ] && lport="$localport"

    echo "Make sure standard output is redirected to a file, and" 1>&2
    echo "connect vncviewer to this machine at port $lport" 1>&2
    exec 11<&1
    <&44 nc -l "$lport" | tee >(base64 -w 75 >&11) | nc "$theip" "$theport" >&22
}

kvm-ui-take-screenshot()
{
    check-required-env
    dumptime="$(date +%y%m%d-%H%M%S)"  # assume not more than one dump per second
    [ -z "$build_dir" ] && build_dir=/tmp
    fname="$build_dir/screendump-$dumptime.ppm"
    echo "screendump $fname" | nc 127.0.0.1 $KVMMON 1>/dev/null 2>/dev/null
    sleep 1
    gzip "$build_dir/screendump-$dumptime.ppm" 2>/dev/null &&
	echo "$build_dir/screendump-$dumptime.ppm".gz
}

kvm-ui-simulate()
{
    simulateName="$1"
    eval declare -f "kvm-ui-simulate-$1" >/dev/null || reportfail "$simulateName not declared"
    check-required-env
    echo "Doing kvm-ui-simulate: $simulateName"
    eval "kvm-ui-simulate-$1"
}

kvm-ui-check()
{
    checkName="$1"
    eval declare -f "kvm-ui-check-$1" >/dev/null || reportfail "$checkName not declared"
    check-required-env
    echo "Doing kvm-ui-check: $checkName"
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
    echo sendkey ctrl-alt-delete | nc 127.0.0.1 "$KVMMON" >/dev/null
}

kvm-ui-simulate-press-return()
{
    echo sendkey ret | nc 127.0.0.1 "$KVMMON" >/dev/null
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

kvm-ui-main "$@"
