# Machine Images

## Building new vmimages

    $ sudo ./build.sh

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

## Compressing raw files

    $ for i in ./ubuntu-lucid-*.raw; do echo $i; time sudo bash -c "gzip -c $i > $i.gz"; done

## Uploading vmimages

    $ s3cmd ls s3://dlc.wakame.axsh.jp/demo/vmimage/
    $ s3cmd sync ubuntu-lucid-*.raw.gz s3://dlc.wakame.axsh.jp/demo/vmimage/ --dry-run
    $ s3cmd sync ubuntu-lucid-*.raw.gz s3://dlc.wakame.axsh.jp/demo/vmimage/
    $ s3cmd ls s3://dlc.wakame.axsh.jp/demo/vmimage/

## Git Operation

    $ git diff ../vdc.sh.d/
    $ git commit -m 'tests/vdc.sh.d: update root-device uuid.' ../vdc.sh.d/
    $ git pull --rebase
    $ git push
