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
    # the file $build_dir/nextstep.

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
	echo "Doing file-size-in-range, is $fsize between $2 and $3 inclusive?" &&
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
	2008) file-size-in-range "$fname" 48500 56000 # 49486
	      # if initially opened window is not in foreground
	      # file size has been seen as small as 48723
	      # Also has been seen as big as 55341.
	      ;;
	2012) file-size-in-range "$fname" 45000 46000 # 45364
	      ;;
    esac
}

#######
####### UI SIMULATIONS
#######

## Note: All of these VNC binary inputs were captured by using netcat
## and tee to redirect vncviewer streams to a file, which was then
## converted to base64.

kvm-ui-simulate-type-a-run-sysprep-return()
{
    # types out the string "a:run-sysprep" and then presses the return key
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
    # Moves the mouse to where the powershell button should be for
    # Windows Server 2008 and clicks the mouse
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
    # Moves the mouse to where the powershell button should be for
    # Windows Server 2012 and clicks the mouse
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

kvm-ui-simulate-click-in-middle()
{
    # clicks once in the upper left part of the screen
    # but close enough to the middle to raise an already
    # showing powershell window
    base64 -d  <<EOF | kvm-ui-feed-slowly-via-vnc
UkZCIDAwMy4wMDgKAQAAAAAACAYAAQADAAMAAwQCAAAAAAIAAAf///8R////IQAAABAAAAABAAA
ABQAAAAIAAAAAAwAAAAAABAADAAMBAAAAAAQAAwAFAAByAAAFAAB0AAMFAAB1AAYFAAB3AAkFAA
B4AAwFAAB6ABEFAAB8ABUFAAB9ABkFAAB/AB0FAACBACEFAACCACUFAACEACgFAACFACwFAACHA
DAFAACIADUFAACLADoFAACNAD4FAACPAEEFAACQAEUFAACSAEkFAACUAE0FAACWAFAFAACZAFUF
AACbAFgFAACdAF0FAAChAGQFAAClAGsFAACrAHUFAACwAH8FAAC1AIYFAAC7AI0FAAC/AJQFAAD
DAJsFAADHAKMFAADLAKoFAADPALEFAADTALgFAADZAMEFAADeAMkFAADkANAFAADoANYFAADsAN
wFAADwAOEFAADyAOUFAAD0AOoFAAD2AO8FAAD4APMFAAD6APcFAAD8APoFAAD+AP8FAAEAAQIFA
AECAQYFAAEDAQoFAAEEAQsFAAEGAQ4FAAEFAQ0FAAEGAQ4FAAEGAQ0FAAEFAQ0FAQEFAQ0FAAEF
AQ0=
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
    cmd="$(< $build_dir/nextstep)"
    echo "Doing supernext-step-completed for nextstep=$cmd"
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
	3-tar-the-image | 4-package-tgz-image | 5-package-qcow-image)
	    true # Nothing to wait for before doing these steps.
	    ;;
	*)
	    reportfail "Supernext does not know how to check the status when nextstep=$cmd"
	    ;;
    esac
}

supernext-simulate-user-actions-before()
{
    cmd="$(< $build_dir/nextstep)"
    echo "Doing supernext-simulate-user-actions-before for nextstep=$cmd"
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
	3-tar-the-image | 4-package-tgz-image | 5-package-qcow-image)
	    : # no user actions need to be done
	    ;;
	*)
	    reportfail "Supernext does not know what to do when nextstep=$cmd"
	    ;;
    esac
}

supernext-simulate-user-actions-after()
{
    # (The code here was SLEEPFOR=30 seconds for a while, which seemed
    # way too conservative and slow.  So it has been changed to 15
    # seconds.  This should be enough for zabbix installer to move to
    # the next state)
    SLEEPFOR=15
    echo "Doing supernext-simulate-user-actions-after for $cmd"
    case "$cmd" in  # uses $cmd from previous functions, because $build_dir/nextstep may have changed
	1b-record-logs-at-ctr-alt-delete-prompt-gen0)
	    touch $build_dir/press-ctrl-alt-del
	    kvm-ui-simulate  press-ctrl-alt-del

	    sleep 15
	    kvm-ui-take-screenshot # for debugging
	    touch $build_dir/type-a-run-sysprep-return-1
	    kvm-ui-simulate  type-a-run-sysprep-return # "a:run-sysprep" here it is the password
	    wait-for-login-completion

	    sleep 2
	    kvm-ui-take-screenshot # for debugging
	    touch $build_dir/open-powershell-click
	    kvm-ui-simulate  open-powershell-click

	    sleep "$SLEEPFOR"
	    # Sometimes (only seen in 2012) the PowerShell window opens but does
	    # not become the frontmost window and does not accept keyboard input.
	    # An extra click will bring it frontmost, or have no effect otherwise.
	    kvm-ui-take-screenshot # for debugging
	    touch $build_dir/type-click-in-middle
	    kvm-ui-simulate  click-in-middle

	    sleep "$SLEEPFOR"
	    kvm-ui-take-screenshot # for debugging
	    touch $build_dir/type-a-run-sysprep-return-2
	    kvm-ui-simulate  type-a-run-sysprep-return # "a:run-sysprep" here it runs the script

	    sleep "$SLEEPFOR"
	    # The zabbix installer should be showing.  Just press return 5 times with a
	    # long-enough sleep in between:
	    kvm-ui-take-screenshot # for debugging
	    for i in $(seq 1 6); do
		sleep "$SLEEPFOR"
		kvm-ui-take-screenshot # for debugging
		touch $build_dir/press-return-$i
		kvm-ui-simulate press-return
	    done
	    # sysprep should start automatically, and then shutdown
	    # should happen automatically. The next step will wait for
	    # the KVM process to disappear and take a few more
	    # screenshots for debugging.
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
    evalcheck 'LABEL="$(cat $build_dir/LABEL)"'

    if supernext-step-completed; then
	# The current step finished!
	# Do user actions necessary before next step...
	supernext-simulate-user-actions-before || exit 255

	"$SCRIPT_DIR/build-w-answerfile-floppy.sh" "$build_dir" -next

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
	build_dir="${2%/}"
	[ -f "$build_dir"/active ] || reportfail "second parameter must be an active test/build directory"
	build_dir="$(cd "$build_dir" ; pwd)"
	supernext-main
	;;
    *) usage
       ;;
esac
