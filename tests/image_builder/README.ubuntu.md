# Machine Images

## Preparing vmimages

    $ curl -O https://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/ubuntu-lucid-32.raw.gz
    $ curl -O https://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/ubuntu-lucid-64.raw.gz
    $ gunzip ubuntu-lucid-32.raw.gz
    $ gunzip ubuntu-lucid-64.raw.gz

## Building new vmimages

    $ sudo ./build.sh

## Compressing raw files

    $ for i in ./ubuntu-lucid-*.raw; do echo $i; time sudo bash -c "gzip -c $i > $i.gz"; done

## Uploading vmimages

    $ s3cmd ls s3://dlc.wakame.axsh.jp/demo/vmimage/
    $ s3cmd sync ubuntu-lucid-*.raw.gz s3://dlc.wakame.axsh.jp/demo/vmimage/ --acl-public --check-md5 --dry-run
    $ s3cmd sync ubuntu-lucid-*.raw.gz s3://dlc.wakame.axsh.jp/demo/vmimage/ --acl-public --check-md5
    $ s3cmd ls s3://dlc.wakame.axsh.jp/demo/vmimage/


# Building vmimages

Basically no need to build new vmimages in order to keep UUID.

## Updating test image-lucidX.meta files

    $ sudo kpartx -va ./ubuntu-lucid-kvm-32.raw
    add map loop0p1 (252:0): 0 974547 linear /dev/loop0 63
    add map loop0p2 (252:1): 0 249856 linear /dev/loop0 974848

    $ new_uuid=$(sudo /sbin/blkid -c /dev/null -sUUID -ovalue /dev/mapper/loop0p1)
    $ sed -i "s,^root_device=uuid:.*,root_device=uuid:${new_uuid},"  ../vdc.sh.d/image-lucid*.meta

    $ sudo kpartx -vd ./ubuntu-lucid-kvm-32.raw
    del devmap : loop0p2
    del devmap : loop0p1
    loop deleted : /dev/loop0

## Git Operation

    $ git diff ../vdc.sh.d/
    $ git commit -m 'tests/vdc.sh.d: update root-device uuid.' ../vdc.sh.d/
    $ git pull --rebase
    $ git push
