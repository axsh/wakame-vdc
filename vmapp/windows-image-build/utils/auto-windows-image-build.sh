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

auto-windows-usage() {
    cat <<'EOF'
#############
Usage:
  ./utils/auto-windows-image-build.sh  build/directory/path --sysprep
      # Runs ./build-dir-utils.sh multiple times and attempts to
      # automatically do any manual steps necessary.  It stops
      # calling ./build-dir-utils.sh when sysprep finishes running.

The path of the build directory must be created first with:
  ./build-dir-utils.sh build/directory/path 0-init

Certain environment variables are required to be set, perhaps
in windows-image-build.ini.

It is also possible to use --package as the second parameter to
automatically do all steps until machine images packages are built for
Wakame-vdc. Using --stop-at as the second parameter and some step name
as the third parameter is also possible. 

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

#######
####### TOP-LEVEL CODE
#######

# define a wait value for things that seem to complete relatively
# quickly and with little variation that makes testing the screen
# contents needlessly complex
[ "$defaultwait" = "" ] && defaultwait=10

simulate-manual-action()
{
    ## TODO: add more screenshots and debugging output
    build_dir="$1"
    nextstep="$2"
    case "$nextstep" in
	4-M-wait-for-ctrl-alt-delete-screen)
	    while ! kvm-ui-check  ctrl-alt-del-screen; do
		echo "Waiting for installation to finish"
		sleep 30
	    done
	    ;;
	6-M-press-ctrl-alt-delete-screen)
	    kvm-ui-simulate  press-ctrl-alt-del
	    ;;
	7-M-wait-for-password-screen)
	    sleep "$(( defaultwait * 2 ))"
	    ;;
	8-M-enter-password)
	    kvm-ui-simulate  type-a-run-sysprep-return # "a:run-sysprep" here it is the password
	    ;;
	9-M-wait-for-login-completion)
	    while ! kvm-ui-check  after-login-screen; do
		echo "Waiting for login to finish"
		sleep 5
	    done
	    ;;
	10-M-open-powershell-window)
	    kvm-ui-simulate  open-powershell-click
	    sleep "$(( defaultwait * 2 ))"
	    ## TODO: copy in code from unmerged pull request to bring window to foreground
	    ;;
	11-M-run-sysprep-script)
	    kvm-ui-simulate  type-a-run-sysprep-return # "a:run-sysprep" here it runs the script
	    ;;
	12-M-wait-zabbix-installer-screen1)
	    sleep "$(( defaultwait * 2 ))" # this one takes a little longer
	    ;;
	#### make the rest of the zabbix steps the same
	#13-M-press-return-1) : ;;
	#14-M-wait-zabbix-installer-screen2) : ;;
	#15-M-press-return-2) : ;;
	#16-M-wait-zabbix-installer-screen3) : ;;
	#17-M-press-return-3) : ;;
	#18-M-wait-zabbix-installer-screen4) : ;;
	#19-M-press-return-4) : ;;
	#20-M-wait-zabbix-installer-screen5) : ;;
	#21-M-press-return-5) : ;;
	#22-M-wait-zabbix-installer-screen6) : ;;
	#23-M-press-return-6) : ;;
	*M-wait-zabbix*)
	    sleep "$defaultwait"
	    ;;
	*M-press-return*)
	    kvm-ui-simulate press-return
	    ;;
	*)
	    reportfail "simulate-manual-action not defined for $nextstep"
	    ;;
    esac
}

source "$SCRIPT_DIR/kvm-ui-util.sh" source

build_dir="${1%/}"

case "$2" in
    --stop-at)
	target_step="$3"
	grep '##step-name##' "$SCRIPT_DIR/../build-dir-utils.sh" |
	    grep -F -e "$target_step" || reportfail "step name not found"
	;;
    --sysprep) target_step="26-make-simple-tar-of-image" ;;
    --package) target_step="1001-gen*-first-boot" ;;
    -1 | --one*) target_step="--one-step" ;;
    *) auto-windows-usage ; exit 255 ;;
esac

[ -f "$build_dir"/active ] || reportfail "second parameter must be an active test/build directory"
cd "$build_dir" || reportfail cd "$build_dir"
build_dir="$(pwd)" 
LABEL="$(cat ./LABEL)" || reportfail "Could not read ./LABEL"

while true; do
    nextstep=$(cat "$build_dir/nextstep" 2>/dev/null) || reportfail "Could not read ./nextstep"
    [ "$target_step" = "$nextstep" ] && break
    case "$nextstep" in
	*-M-*)
	    simulate-manual-action "$build_dir" "$nextstep"
	    "$SCRIPT_DIR/../build-dir-utils.sh" "$build_dir" -done
	    ;;
	*)
	    "$SCRIPT_DIR/../build-dir-utils.sh" "$build_dir" -do-next
	    ;;
    esac
    [ "$target_step" = "--one-step" ] && break
    sleep 1 # to avoid hogging CPU if something goes wrong
done
