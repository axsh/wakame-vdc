#!/bin/bash

set -e

# Get options
while true; do
  case "$1" in
    --without-gpg-sign )
      FLAG_WITHOUT_GPG_SIGN=true; shift;;
    -- ) shift; break ;;
    * ) break;;
  esac
done
export FLAG_WITHOUT_GPG_SIGN

#Function to generate the mount directory later on
function randdir {
  dir=`</dev/urandom tr -dc A-Za-z0-9 | head -c8`
  while [ -d ${dir} ] || [ -f ${dir} ]; do
    dir=`</dev/urandom tr -dc A-Za-z0-9 | head -c8`
  done
  echo ${dir}
}

function checkreq {
  for exec in "${!requirements[@]}"; do
    which $exec >> /dev/null
    [[ $? = 0 ]] || abort "Missing dependency ${requirements[$exec]}.\nTry running 'apt-get install ${requirements[@]}' to install all dependencies."
  done
}

function abort() {
  echo -e "Error: "$* >&2
  exit 1
}

base_distro="lucid"
base_distro_number="10.04"

#Check if argument was given at all
if [ -z "$1" ]; then
  abort "No source image given.\nUsage: $0 /path/to/ubuntu-${base_distro}-image"
fi

#Define dependencies
declare -A requirements=( ["perl"]="perl" ["debuild"]="devscripts" ["dh_clean"]="debhelper" ["mkisofs"]="genisoimage" ["rsync"]="rsync" )

root_dir="$( cd "$( dirname "$0" )" && pwd )"
wakame_dir="${root_dir}/../.."
tmp_dir="${wakame_dir}/tmp/cd_builder"
cd_dir="${tmp_dir}/mnt"
apt_dir="${tmp_dir}/guts/apt-ftparchive"
cd_mod_dir="${tmp_dir}/guts/wakame"
tmp_mount_dir="${tmp_dir}/$(randdir)"
wakame_version="11.12"
arch="amd64"
wakame_debs="wakame-vdc_${wakame_version}_${arch}.deb wakame-vdc-dvd-config_${wakame_version}_${arch}.deb"
src_image=`readlink -f $1`
dst_image="${tmp_dir}/wakame-vdc-${wakame_version}-${arch}.iso"
images_dir="${cd_dir}/setup/images"
remote_images_path=http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage
vmimage_file="ubuntu-10.04_with-metadata_kvm_i386.raw.gz"
gpg_key_id="DCFFB6BE"
guts_archive_dir="${tmp_dir}/guts/archive"
package_location_axsh="http://dlc.wakame.axsh.jp.s3.amazonaws.com/vdc/11.12.1/package/ubuntu/"
package_location='axsh'

## Check prerequisties

[[ $UID = 0 ]] || abort "Operation not permitted. Try using sudo."

#Check if the source image exists
if [ ! -f ${src_image} ]; then
  abort "Couldn't find source image: ${src_image}"
fi

#Check if dependencies are installed
checkreq

## Clean artifacts and temporary stuff.

#Clean the working directory
#[[ -d ${wakam_dir}/tmp ]] && rm ${wakame_dir}/tmp/*
[[ -f ${dst_image} ]] && rm -f ${dst_image}
#Delete ftparchive config files
[[ -f ${apt_dir}/apt-ftparchive-deb.conf ]] && rm -f ${apt_dir}/apt-ftparchive-deb.conf
[[ -f ${apt_dir}/apt-ftparchive-extras.conf ]] && rm -f ${apt_dir}/apt-ftparchive-extras.conf
[[ -f ${apt_dir}/apt-ftparchive-udeb.conf ]] && rm -f ${apt_dir}/apt-ftparchive-udeb.conf
[[ -f ${apt_dir}/release.conf ]] && rm -f ${apt_dir}/release.conf
rm -rf ${tmp_dir}/guts/indices/
rm -rf ${cd_dir}

#Make tmp dir if it doesn't exist
mkdir -p ${tmp_dir} || :

#Make the debian package
(
  cd ${wakame_dir}

  # skip building package if all debs exist already.
  for i in ${wakame_debs}; do
    [[ -f "../${i}" ]]
  done && exit 0

  if [[ -n "$FLAG_WITHOUT_GPG_SIGN" ]]; then
    debuild --no-lintian -us -uc
  else
  #Check if the Axsh key is on the keyring
    gpg --list-secret-keys | grep -q $gpg_key_id
    if [ "$?" -ne "0" ]; then
      abort "Couldn't find Axsh Co. LTD's private gpg key on the keyring. This script needs it to sign the CD."
    fi

    debuild --no-lintian
  fi

  for i in ${wakame_debs}; do
    [[ -e "../${i}" ]] || abort "Couldn't find deb package: ${i}"
    cp -p "../${i}" "${cd_mod_dir}/pool/extras"
  done
)

#Extract guts
function download_package() {
  local download_path=$1
  local download_file=$2
  local seed=`cat "${download_file}"`

  cd ${download_path}
  for package in ${seed[@]}; do

    local package_name=`basename "${package}"`
    case ${package_location} in
      axsh)
        local path=${package_name}
        local url=${package_location_axsh}
      ;;
    esac

    if [ ! -e ${download_path}${package_name} ]; then
      # url escape
      url=`echo ${url}${path} | sed -e s/+/%2B/g`
      wget ${url}
    fi
  done
}

echo "Copying guts contents"
rsync -a ${root_dir}/guts ${tmp_dir}
(
  cd "${cd_mod_dir}"
  cat <<EOF | while read -r i; do [[ -d "${i}" ]] || mkdir -p "${i}"; done
tmp
setup/images
pool/extras
pool/main
pool/main/u
pool/main/u/ubuntu-keyring
EOF
)

download_package "${cd_mod_dir}/pool/extras/" "${guts_archive_dir}/pool_extras"
download_package "${cd_mod_dir}/pool/main/u/ubuntu-keyring/" "${guts_archive_dir}/pool_main"

#Get the indices
mkdir -p ${tmp_dir}/guts/indices
cd ${tmp_dir}/guts/indices
for SUFFIX in extra.main main main.debian-installer restricted restricted.debian-installer; do
  wget http://archive.ubuntu.com/ubuntu/indices/override.$base_distro.$SUFFIX
done

#Mount the source image
echo "Mounting the source image"
mkdir -p ${tmp_mount_dir}
mount -o loop ${src_image} ${tmp_mount_dir}

#Copy it to a temporary directory
echo "Copying CD contents"
rsync -a ${tmp_mount_dir}/ ${cd_dir}

umount ${tmp_mount_dir}
rmdir ${tmp_mount_dir}

#Wakamize it
echo "Adding wakame-vdc to it"
cp -r ${cd_mod_dir}/* ${cd_dir}

#Add  image to the CD
echo "Adding image to the CD"
if [ ! -f ${tmp_dir}/${vmimage_file} ]; then
  cd ${tmp_dir}
  wget ${remote_images_path}/${vmimage_file}
fi

if [ -f ${tmp_dir}/${vmimage_file} ]; then
  echo "Add ${vmimage_file}"
  cp ${tmp_dir}/${vmimage_file} ${images_dir}/
else
  abort "Couldn't find ${vmimage_file}"
fi

#Generate .conf files for signing the repositories
cd ${apt_dir}
cat <<EOF > apt-ftparchive-udeb.conf
Dir {
  ArchiveDir "${cd_dir}";
};

TreeDefault {
  Directory "pool/";
};

BinDirectory "pool/main" {
  Packages "dists/${base_distro}/main/debian-installer/binary-amd64/Packages";
  BinOverride "${tmp_dir}/guts/indices/override.${base_distro}.main.debian-installer";
};

BinDirectory "pool/restricted" {
  Packages "dists/${base_distro}/restricted/debian-installer/binary-amd64/Packages";
  BinOverride "${tmp_dir}/guts/indices/override.${base_distro}.restricted.debian-installer";
};

Default {
  Packages {
    Extensions ".udeb";
    Compress ". gzip";
  };
};

Contents {
  Compress "gzip";
};
EOF

cat <<EOF > apt-ftparchive-extras.conf
Dir {
  ArchiveDir "${cd_dir}";
};

TreeDefault {
  Directory "pool/";
};

BinDirectory "pool/extras" {
  Packages "dists/${base_distro}/extras/binary-amd64/Packages";
};

Default {
  Packages {
    Extensions ".deb";
    Compress ". gzip";
  };
};

Contents {
  Compress "gzip";
};
EOF

cat <<EOF > apt-ftparchive-deb.conf
Dir {
  ArchiveDir "${cd_dir}";
};

TreeDefault {
  Directory "pool/";
};

BinDirectory "pool/main" {
  Packages "dists/${base_distro}/main/binary-amd64/Packages";
  BinOverride "${tmp_dir}/guts/indices/override.${base_distro}.main";
  ExtraOverride "${tmp_dir}/guts/indices/override.${base_distro}.extra.main";
};

BinDirectory "pool/restricted" {
 Packages "dists/${base_distro}/restricted/binary-amd64/Packages";
 BinOverride "${tmp_dir}/guts/indices/override.${base_distro}.restricted";
};

Default {
  Packages {
    Extensions ".deb";
    Compress ". gzip";
  };
};

Contents {
  Compress "gzip";
};
EOF

cat <<EOF > release.conf
APT::FTPArchive::Release::Origin "Ubuntu";
APT::FTPArchive::Release::Label "Ubuntu";
APT::FTPArchive::Release::Suite "${base_distro}";
APT::FTPArchive::Release::Version "${base_distro_number}";
APT::FTPArchive::Release::Codename "${base_distro}";
APT::FTPArchive::Release::Architectures "${arch}";
APT::FTPArchive::Release::Components "main restricted extras";
APT::FTPArchive::Release::Description "Ubuntu ${base_distro_number} LTS";
EOF

#Remove unused packages in pool/main to clear some spaces.
(
  cd ${cd_dir}
  cat <<EOF | while read -r i; do [[ -d "pool/main/${i}" ]] && rm -rf "pool/main/${i}"; done
s/samba
o/openjdk-6
e/eucalyptus
e/eucalyptus-commons-ext
g/gcc-4.4
g/gwt
r/ruby1.8
r/ruby-defaults
h/hsqldb
s/squid
s/squid-langpack
libg/libgnuinet-java
libg/libgnumail-java
libg/libgnujaf-java
libg/libgoogle-collections-java
libe/libezmorph-java
libb/libbsf-java
libo/liboro-java
libw/libwoodstox-java
libj/libjaxen-java
libj/libjibx-java
libj/libjdom1-java
libj/libjson-java
libj/libjaxp1.3-java
libc/libcommons-lang-java
libc/libcommons-fileupload-java
libc/libcommons-jxpath-java
libc/libcommons-dbcp-java
libc/libcommons-logging-java
libc/libcommons-collections-java
libc/libcommons-collections3-java
libc/libcommons-cli-java
libc/libcommons-discovery-java
libc/libcommons-codec-java
liba/libaxiom-java
libr/libregexp-java
libh/libhamcrest-java
libx/libxalan2-java
libx/libxstream-java
libx/libxpp2-java
libx/libxml-security-java
libx/libxpp3-java
libx/libxerces2-java
c/ca-certificates-java
libs/libslf4j-java
libm/libmx4j-java
libp/libproxool-java
EOF
)

# generate dists Packages/Release files for pool/main and pool/extra.
# sign phase is skipped if $FLAG_WITHOUT_GPG_SIGN is set.
${PWD}/build_repository.sh ${cd_dir}

# the generated files have strange permission -------x so fix them.
find ${cd_dir}/dists/ -type f \( -name "Packages" -or -name "Packages.gz" \) -exec chmod 444 {} \;

#Create extra repository and sign with gpg key
echo "Signing extra repository"
rm -f ${cd_dir}/dists/${base_distro}/Release.gpg
cd ${apt_dir}
perl extraoverride.pl < ${cd_dir}/dists/${base_distro}/main/binary-amd64/Packages >> ${tmp_dir}/guts/indices/override.${base_distro}.extra.main

#Compile iso
mkisofs -r -V "Wakame-vdc ${WAKAME_VERSION}" \
            -cache-inodes \
            -J -l -b isolinux/isolinux.bin \
            -c isolinux/boot.cat -no-emul-boot \
            -boot-load-size 4 -boot-info-table \
            -o $dst_image $cd_dir

echo "Created iso image ${dst_image}"
exit 0
