#!/bin/sh
CURRENT_DIR="$( cd "$( dirname "$0" )" && pwd )"
WAKAME_VERSION="11.06"
ARCH="amd64"

IMAGE=${CURRENT_DIR}/../wakame-vdc-${WAKAME_VERSION}-${ARCH}.iso
BUILD=${CURRENT_DIR}/cd-image/

mkisofs -r -V "Wakame-vdc ${WAKAME_VERSION}" \
            -cache-inodes \
            -J -l -b isolinux/isolinux.bin \
            -c isolinux/boot.cat -no-emul-boot \
            -boot-load-size 4 -boot-info-table \
            -o $IMAGE $BUILD
