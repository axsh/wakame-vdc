#!/bin/bash
#
# requires:
#   qemu-img
#   stat
#

declare localpath=$1

[[ -f "${localpath}" ]] || {
    echo "file not found: ${localpath}" >&2
    return 1
}

size=$(
    qemu-img info "${localpath}" \
	| egrep "^virtual size:" \
	| awk -F: '{print $2}' \
	| sed 's,[()], ,g' \
	| awk '{print $2}'
)
allocation_size=$(stat -c '%s' "${localpath}")
checksum=$(md5sum "${localpath}" | cut -d ' ' -f1)

cat <<EOF
--size=${size} --allocation-size=${allocation_size} --checksum=${checksum}
EOF
