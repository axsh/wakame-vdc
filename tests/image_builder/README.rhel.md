# Machine Images

## Preparing vmimages

    $ curl -O https://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/centos-6-kvm-32.raw.gz
    $ curl -O https://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/centos-6-kvm-64.raw.gz
    $ gunzip centos-6-kvm-32.raw.gz
    $ gunzip centos-6-kvm-64.raw.gz

## Building new vmimages

    $ sudo ./build-rhel.sh

## Compressing raw files

    $ for i in ./centos-6-*.raw; do echo $i; time sudo bash -c "gzip -c $i > $i.gz"; done

## Uploading vmimages

    $ s3cmd ls s3://dlc.wakame.axsh.jp/demo/vmimage/
    $ s3cmd sync centos-6-*.raw.gz s3://dlc.wakame.axsh.jp/demo/vmimage/ --acl-public --check-md5 --dry-run
    $ s3cmd sync centos-6-*.raw.gz s3://dlc.wakame.axsh.jp/demo/vmimage/ --acl-public --check-md5
    $ s3cmd ls s3://dlc.wakame.axsh.jp/demo/vmimage/
