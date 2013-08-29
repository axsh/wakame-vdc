#!/bin/bash
# virtual appliance build script
rootsize=5000
swapsize=1000

set -e

base_distro="lucid"
base_distro_number="10.04"

root_dir="$( cd "$( dirname "$0" )" && pwd )"
wakame_dir="${root_dir}/../.."
tmp_dir="${wakame_dir}/tmp/vmapp_builder"
wakame_version="13.08"
arch="amd64"
wakame_debs="wakame-vdc_${wakame_version}_${arch}.deb wakame-vdc-dcmgr-vmapp-config_${wakame_version}_${arch}.deb"

. "${root_dir}/build_functions.sh"

[[ $UID -ne 0 ]] && {
  echo "ERROR: Run as root" >/dev/stderr
  exit 1
}

[[ -d "$tmp_dir" ]] || mkdir -p "$tmp_dir"

# make temp apt repository.
[[ -d "$tmp_dir/apt/dists/${base_distro}" ]] || mkdir -p "$tmp_dir/apt/dists/${base_distro}"
[[ -d "$tmp_dir/apt/archives" ]] || mkdir -p "$tmp_dir/apt/archives"
for i in $wakame_debs; do
  cp "$wakame_dir/../$i" "$tmp_dir/apt/archives"
done
(
  cd "$tmp_dir/apt/"
  apt-ftparchive sources  ./ > Sources
  apt-ftparchive packages ./ > Packages
  apt-ftparchive contents ./ > "Contents-${arch}"
  apt-ftparchive release  ./ > Release
  rm -f *.gz
  gzip -c Sources > Sources.gz
  gzip -c Packages > Packages.gz
  gzip -c "Contents-${arch}" > "Contents-${arch}".gz
)

cat <<EOF > $tmp_dir/execscript.sh
#!/bin/bash

echo "doing execscript.sh: \$1"
rsync -a $tmp_dir/apt \$1/tmp/
echo "deb file:///tmp/apt ./" > \$1/etc/apt/sources.list.d/tmp.list
chroot \$1 apt-get update
chroot \$1 apt-get install wakame-vdc-dcmgr-vmapp-config
chroot \$1 rm -f /etc/apt/sources.list.d/tmp.list
chroot \$1 apt-get update
EOF
chmod 755 $tmp_dir/execscript.sh

# generate image
run_vmbuilder "wakame-vdc-dcmgr-vmapp.raw" "amd64" \
  --debug \
  --execscript="$tmp_dir/execscript.sh"
