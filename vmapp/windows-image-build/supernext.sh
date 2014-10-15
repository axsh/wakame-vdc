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
set -x

usage() {
    cat <<'EOF'
    # NOTE: the following is out-of-date:

    # This is a big proof-of-concept hack for automating seed image
    # building.  Currently, this script requires the user to (1)
    # *carefully* make sure that the previous step finishes before
    # issuing the "-next" command.  Also, sometimes the user must
    # manually (2) do some actions in Windows user interface before
    # issuing "-next".  This new "supernext.sh" scripts attempts to do
    # these two things.  If it works, then some automatic script can
    # simpily do a supernext.sh command (instead of
    # "-next")periodically (maybe every 30 seconds) and a seed image
    # can be created automatically.

    # A high-level summary is:
    # IF whatever is being waited for has not happend, then exit immediately.
    # ELSE:
    #    1-Simulate user interaction if necessary alone with
    #      enough waiting between steps.
    #    2-Take a screenshot for debugging, confirmation
    #    3-Continue below with a normal "-next" command.

    # The step that checks the wait condition will usually take a
    # new screenshot.  What is being waiting for is determined from
    # the file $trdir/nextstep.

To run, just do:

./supernext.sh -next

EOF
    exit
}

#######
####### UI CHECKS
#######

file-size-in-range()
{
    fname="$1"
    fsize="$(stat -c %s "$fname" 2>/dev/null)" && \
	[ "$fsize" -ge "$2" -a "$fsize" -le "$3" ]
}

kvm-ui-check-ctrl-alt-del-screen()
{
    fname="$(kvm-ui-take-screenshot)"
    case "$LABEL" in
	2008) file-size-in-range "$fname" 270000 280000 # 275343
	      ;;
	2012) file-size-in-range "$fname" 11000 13100 # 12883, 11360
	      ;;
    esac
}

kvm-ui-check-after-login-screen()
{
    fname="$(kvm-ui-take-screenshot)"
    case "$LABEL" in
	2008) file-size-in-range "$fname" 48500 50000 # 49486
	      # if initially opened window is not in foreground
	      # file size has been seen as small as 48723
	      ;;
	2012) file-size-in-range "$fname" 45000 46000 # 45364
	      ;;
    esac
}

#######
####### UI SIMULATIONS
#######

kvm-ui-simulate-type-a-run-sysprep-return()
{
    # just to test VNC piping code:
    base64 -d  <<EOF | kvm-ui-feed-slowly-via-vnc
UkZCIDAwMy4wMDgKAQAAAAAACAYAAQADAAMAAwQCAAAAAAIAAAf///8R////IQAAABAAAAABAAAA
BQAAAAIAAAAAAwAAAAAAAyACWAAAAAAgGAABAP8A/wD/EAgAAAAAAgAAB////xH///8hAAAABQAA
AAEAAAAQAAAAAgAAAAADAAAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYBAEA
AAAAAGEDAQAAAAADIAJYBAAAAAAAAGEDAQAAAAADIAJYBAEAAAAAADoDAQAAAAADIAJYBAAAAAAA
ADoEAQAAAAAAcgMBAAAAAAMgAlgEAAAAAAAAcgQBAAAAAAB1AwEAAAAAAyACWAQAAAAAAAB1BAEA
AAAAAG4DAQAAAAADIAJYBAAAAAAAAG4DAQAAAAADIAJYAwEAAAAAAyACWAQBAAAAAAAtAwEAAAAA
AyACWAQAAAAAAAAtBAEAAAAAAHMDAQAAAAADIAJYBAAAAAAAAHMEAQAAAAAAeQMBAAAAAAMgAlgE
AAAAAAAAeQQBAAAAAABzAwEAAAAAAyACWAQAAAAAAABzBAEAAAAAAHADAQAAAAADIAJYBAAAAAAA
AHAEAQAAAAAAcgMBAAAAAAMgAlgEAQAAAAAAZQMBAAAAAAMgAlgEAAAAAAAAcgQAAAAAAABlBAEA
AAAAAHADAQAAAAADIAJYBAAAAAAAAHAEAQAAAAD/DQQAAAAAAP8NAwEAAAAAAyACWAMBAAAAAAMg
AlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAA
AAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMB
AAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyAC
WAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAA
AyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEA
AAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJY
AwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAAD
IAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAA
AAADIAJYBAEAAAAA/+kDAQAAAAADIAJYBAAAAAAA/+kDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAA
AAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMB
AAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyAC
WA==
EOF
}

kvm-ui-simulate-open-powershell-click()
{
    case "$LABEL" in
	2008) kvm-ui-simulate-open-powershell-click-2008
	      ;;
	2012) kvm-ui-simulate-open-powershell-click-2012
	      ;;
    esac
}

kvm-ui-simulate-open-powershell-click-2008()
{
# just to test VNC piping code:
    base64 -d  <<EOF | kvm-ui-feed-slowly-via-vnc
UkZCIDAwMy4wMDgKAQAAAAAACAYAAQADAAMAAwQCAAAAAAIAAAf///8R////IQAAABAAAAABAAAA
BQAAAAIAAAAAAwAAAAAAAyACWAAAAAAgGAABAP8A/wD/EAgAAAAAAgAAB////xH///8hAAAABQAA
AAEAAAAQAAAAAgAAAAADAAAAAAADIAJYAwEAAAAAAyACWAUAAI8CVwUAAI8CVgUAAI8CVAMBAAAA
AAMgAlgFAACPAlMFAACOAlMDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlgFAACOAlIFAACO
AlEDAQAAAAADIAJYBQAAjgJQAwEAAAAAAyACWAUAAI4CTwUAAI4CTgMBAAAAAAMgAlgDAQAAAAAD
IAJYBQAAjgJNBQAAjgJMAwEAAAAAAyACWAUBAI4CTAUAAI4CTAMBAAAAAAMgAlgDAQAAAAADIAJY
AwEAAAAAAyACWAMBAAAAAAMgAlgFAACPAk4FAACPAk8FAACPAlEDAQAAAAADIAJYBQAAkAJTBQAA
kAJUBQAAkAJVAwEAAAAAAyACWAMBAAAAAAMgAlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMg
AlgDAQAAAAADIAJYAwEAAAAAAyACWAMBAAAAAAMgAlg=
EOF
}

kvm-ui-simulate-open-powershell-click-2012()
{
    # just to test VNC piping code:
    base64 -d  <<EOF | kvm-ui-feed-slowly-via-vnc
UkZCIDAwMy4wMDgKAQAAAAAACAYAAQADAAMAAwQCAAAAAAIAAAf///8R////IQAAABAAAAABAAAA
BQAAAAIAAAAAAwAAAAAABAADAAAAAAAgGAABAP8A/wD/EAgAAAAAAgAAB////xH///8hAAAABQAA
AAEAAAAQAAAAAgAAAAADAAAAAAAEAAMAAwEAAAAABAADAAUAAIsC6wUAAIwC6QUAAIwC6AMBAAAA
AAQAAwAFAACMAuYFAACMAuUDAQAAAAAEAAMABQAAjALkBQAAjALjBQAAjALiAwEAAAAABAADAAMB
AAAAAAQAAwAFAACNAuIDAQAAAAAEAAMABQAAjALiAwEAAAAABAADAAUBAIwC4gUAAIwC4gMBAAAA
AAQAAwADAQAAAAAEAAMAAwEAAAAABAADAAMBAAAAAAQAAwADAQAAAAAEAAMAAwEAAAAABAADAAMB
AAAAAAQAAwADAQAAAAAEAAMAAwEAAAAABAADAAMBAAAAAAQAAwAEAQAAAAD/6QMBAAAAAAQAAwAE
AAAAAAD/6QMBAAAAAAQAAwADAQAAAAAEAAMAAwEAAAAABAADAA==
EOF
}

#######
####### TOP-LEVEL CODE
#######

wait-for-login-completion()
{
    while ! kvm-ui-check  after-login-screen; do
	echo "Waiting for login to finish"
	sleep 5
    done
}

supernext-step-completed()
{
    cmd="$(< $trdir/nextstep)"
    case "$cmd" in
	1-install)
	    true # nothing to check; always OK to proceed
	    ;;
	1b-record-logs-at-ctr-alt-delete-prompt-gen0)
	    kvm-ui-check  ctrl-alt-del-screen
	    ;;
	2-confirm-sysprep-gen0)
	    true # still at ctr-alt-del screen from last step
	    ;;
	*)
	    reportfail "Supernext does not know how to check the status when nextstep=$cmd"
	    ;;
    esac
}

supernext-simulate-user-actions-before()
{
    cmd="$(< $trdir/nextstep)"
    case "$cmd" in
	1-install)
	    : # no user actions need to be done
	    ;;
	1b-record-logs-at-ctr-alt-delete-prompt-gen0)
	    : # no user actions need to be done
	    ;;
	2-confirm-sysprep-gen0)
	    : # no user actions need to be done
	    ;;
	*)
	    reportfail "Supernext does not know what to do when nextstep=$cmd"
	    ;;
    esac
}

supernext-simulate-user-actions-after()
{
    SLEEPFOR=30 # 10 seconds sometimes works. Do 3 times this.
    case "$cmd" in  # uses $cmd from previous functions, because $trdir/nextstep may have changed
	1b-record-logs-at-ctr-alt-delete-prompt-gen0)
	    touch $trdir/press-ctrl-alt-del
	    kvm-ui-simulate  press-ctrl-alt-del

	    sleep 15
	    kvm-ui-take-screenshot # for debugging
	    touch $trdir/type-a-run-sysprep-return-1
	    kvm-ui-simulate  type-a-run-sysprep-return # "a:run-sysprep" here it is the password
	    wait-for-login-completion

	    sleep 2
	    kvm-ui-take-screenshot # for debugging
	    touch $trdir/open-powershell-click
	    kvm-ui-simulate  open-powershell-click

	    sleep "$SLEEPFOR"
	    kvm-ui-take-screenshot # for debugging
	    touch $trdir/type-a-run-sysprep-return-2
	    kvm-ui-simulate  type-a-run-sysprep-return # "a:run-sysprep" here it runs the script

	    sleep "$SLEEPFOR"
	    # The zabbix installer should be showing.  Just press return 5 times with a
	    # sleep in between:
	    kvm-ui-take-screenshot # for debugging
	    for i in $(seq 1 6); do
		sleep "$SLEEPFOR"
		kvm-ui-take-screenshot # for debugging
		touch $trdir/press-return-$i
		kvm-ui-simulate press-return
	    done
	    # sysprep should start automatically, and the next step
	    # will wait for the KVM process to disappear
	    # Take a few more screenshots for debugging
	    for i in $(seq 1 6); do
		sleep 10
		kvm-ui-take-screenshot # for debugging
	    done
	    ;;
	*)
	    : # most steps do not require UI actions at the start
	    ;;
    esac
}

supernext-main()
{
    try LABEL="$(cat $trdir/LABEL)"

    if supernext-step-completed; then
	# The current step finished!
	# Do user actions necessary before next step...
	supernext-simulate-user-actions-before || exit 255

	"$SCRIPT_DIR/build-w-answerfile-floppy.sh" "$trdir" -next

	supernext-simulate-user-actions-after || exit 255
	return 0
    else
	# The current step is still executing
	return 100
    fi
}

source "$SCRIPT_DIR/kvm-ui-util.sh" source

case "$1" in
    -next) # normal case
	trdir="${2%/}"
	[ -f "$trdir"/active ] || reportfail "second parameter must be an active test/build directory"
	trdir="$(cd "$trdir" ; pwd)"
	supernext-main
	;;
    *) usage
       ;;
esac
