#!/bin/bash

reportfailed()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

file-size()
{
    lsout="$(ls -l "$1")" && read t1 t2 t3 t4 fsize rest <<<"$lsout"
    echo "$fsize"
}

output-image-install-script()
{
    seedtar="$1"
    [ -f "$seedtar" ] || reportfailed "File '$seedtar' not found"
    [[ "$seedtar" == *.raw.tar.gz ]] || reportfailed "Expecting *.raw.tar.gz file"

    # gather info about seed image
    size=$(
	# e.g.: -rw-r--r-- root/root 4294967296 2015-04-06 15:35 centos-6.6.i686.kvm.md.raw
	tar tzvf "$seedtar" |
	    while read perms owner thesize therest1; do
		if [[ "$therest1" == *${seedtar%.tar.gz}* ]]; then
		    echo "$thesize"
		    break
		fi
	    done
	)
    [ "${size//[0-9]/}" = "" ] && [ "$size" != "" ] || reportfailed "Error extracting size from tar file"
    allocation_size=$(stat -c '%s' "${seedtar}")
    read checksum therest2 <<<"$(md5sum "${seedtar}")"

    if [ "$ARCH" == "" ]; then
	ARCH="x86_64"
    fi

    if [ "$UUID" == "" ]; then  # do not prefix with bo- or wmi-
	UUID="${seedtar%%[-._]*}"
    fi
    
    if [ "$ACCOUNTID" == "" ]; then
	ACCOUNTID="a-shpoolxx"
    fi

    if [ "$STORAGEID" == "" ]; then
	STORAGEID="bkst-local"
    fi

    if [ "$DISPLAYNAME" == "" ]; then
	DISPLAYNAME="$seedtar $size"
    fi

    if [ "$DESCRIPTION" == "" ]; then
	DESCRIPTION="$seedtar local"
    fi

    cat >"$seedtar.install.sh" <<EOF
backupobject-add()
{
  ( set -x
  /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage backupobject add \\
    --uuid="bo-$UUID" \\
    --account-id=$ACCOUNTID \\
    --storage-id=$STORAGEID \\
    --display-name="$DISPLAYNAME" \\
    --object-key=$seedtar \\
    --container-format=tgz \\
    --size=$size \\
    --allocation-size=$allocation_size \\
    --checksum=$checksum
  )
}

backupobject-update()
{
  ( set -x
  /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage backupobject modify bo-$UUID \\
    --size=$size \\
    --allocation-size=$allocation_size \\
    --checksum=$checksum
  )
}

image-add()
{
  ( set -x
  /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage image add local bo-$UUID \\
    --uuid=wmi-$UUID \\
    --account-id=$ACCOUNTID \\
    --arch=$ARCH \\
    --description="$DISPLAYNAME" \\
    --file-format=raw \\
    --root-device=label:root \\
    --service-type=std \\
    --display-name="$DISPLAYNAME" \\
    --is-public \\
    --is-cacheable
  /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage image features wmi-$UUID --virtio
  )
}

get-backupobject-status() {
  echo
  echo "List of registered backup objects:"
  /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage backupobject show | (
    rc=1
    while read uuid therest; do
       echo "\$uuid \$therest"
       if [[ "\$uuid" == bo-$UUID ]]; then
         /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage backupobject show bo-$UUID
         rc=0
       fi
    done
    exit "\$rc" # exit subshell
  )
}

## This is almost a copy/paste of get-backupobject-status, but
## it is probably not worth refactoring
get-image-status() {
  echo
  echo "List of registered images:"
  /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage image show | (
    rc=1
    while read uuid therest; do
       echo "\$uuid \$therest"
       if [[ "\$uuid" == wmi-$UUID ]]; then
         /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage image show wmi-$UUID
         rc=0
       fi
    done
    exit "\$rc" # exit subshell
  )
}

do-auto()
{
   if get-backupobject-status 1>/dev/null; then
       echo "Image already registered in database, doing update:"
       backupobject-update
   else
       backupobject-add
   fi
   if get-image-status 1>/dev/null; then
       echo "Image already registered in database."
   else
       image-add
   fi
}

if [ "\$#" == "0" ]; then
  echo "Options: show, backupobject, image, or auto"
  exit
fi

set -e
for i in "\$@"; do
  case "\$i" in
    bo | backupobject) backupobject-add;;
    img | image) image-add ;;
    auto) do-auto ;;
    show)
       set +e
       get-backupobject-status
       get-image-status
       ;;
    *) echo "unexpected parameter: \$i (expecting show, backupobject, image, or auto)" ;;
  esac
done
EOF
}

output-image-install-script "$@"
