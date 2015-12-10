#!/bin/bash

[ -d "$CODEDIR" ] && [ -n "$DATADIR" ] || {
    echo "($0)" 1>&2
    echo "This step expects calling script to set up environment" 1>&2
    exit 255
}

source="$1"
target="$2"
targetDIR="${2%/*}"
targetNAME="${2##*/}"
qcowtarget="${target%.raw.tar.gz}.qcow2.gz"
qcowNAME="${qcowtarget##*/}"

$starting_dependents "Packaging ${target##*/}"
(
    $starting_checks "Tar *.tar.gz file"
    [ -f "$target" ]
    $skip_rest_if_already_done
    set -e
    cd "$DATADIR/"
    cp -al "$source" "${target%.tar.gz}"
    cd "$targetDIR"
    tar czSvf "$target" "${targetNAME%.tar.gz}"
    md5sum "${targetNAME}" >"${targetNAME}".md5
    md5sum "${targetNAME%.tar.gz}" >"${targetNAME%.tar.gz}".md5
) ; prev_cmd_failed "Error while packaging raw.tar.gz file"

(
    $starting_checks "Create install script for *.raw.tar.gz file"
    [ -f "$target".install.sh ]
    $skip_rest_if_already_done
    set -e
    cd "$targetDIR"
    "$CODEDIR/bin/output-image-install-script.sh" "$targetNAME"
) ; prev_cmd_failed "Error while creating install script for raw image: $targetNAME"

(
    $starting_checks "Convert image to qcow2 format"
    [ -f "${qcowtarget%.gz}" ] || [ -f "$qcowtarget" ]
    $skip_rest_if_already_done
    set -e
    cd "$targetDIR"
    [ -f "${target%.tar.gz}" ]

    # remember the size of the raw file, since it is hard to get that
    # information from the qcow2.gz file without expanding it
    lsout="$(ls -l "${target%.tar.gz}")" && read t1 t2 t3 t4 fsize rest <<<"$lsout"
    echo "$fsize" >"${target%.raw.tar.gz}".qcow2.rawsize

    # The compat option is not in older versions of qemu-img.  Assume that
    # if the option is not there, it defaults to use options that work
    # with the KVM in Wakame-vdc.
    qemu-img convert -f raw -O qcow2 -o compat=0.10 "${target%.tar.gz}" "${qcowtarget%.gz}" || \
	qemu-img convert -f raw -O qcow2 "${target%.tar.gz}" "${qcowtarget%.gz}"
    md5sum "${qcowtarget%.gz}" >"${qcowtarget%.gz}".md5
    ls -l "${qcowtarget%.gz}" >"${qcowtarget%.gz}".lsl
) ; prev_cmd_failed "Error converting image to qcow2 format: $targetNAME"

(
    $starting_checks "Gzip qcow2 image"
    [ -f "$qcowtarget" ]
    $skip_rest_if_already_done
    set -e
    cd "$targetDIR"
    gzip "${qcowtarget%.gz}"
    md5sum "$qcowtarget" >"$qcowtarget".md5
) ; prev_cmd_failed "Error while running gzip on the qcow2 image: $qcowtarget"

(
    $starting_checks "Create install script for *.qcow.gz file"
    [ -f "$qcowtarget".install.sh ]
    $skip_rest_if_already_done
    set -e
    cd "$targetDIR"
    "$CODEDIR/bin/output-qcow-image-install-script.sh" "$qcowNAME"
) ; prev_cmd_failed "Error while creating install script for qcow image: $qcowtarget"

$starting_checks
true # this step just groups the above steps
$skip_rest_if_already_done
