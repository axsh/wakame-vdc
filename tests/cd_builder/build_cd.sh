#!/bin/bash

set -e

# Get options
FLAG_WITHOUT_GPG_SIGN=false
while true; do
  case "$1" in
    --without-gpg-sign )
      FLAG_WITHOUT_GPG_SIGN=true; shift;;
    -- ) shift; break ;;
    * ) break;;
  esac
done

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
  
  which bundle >> /dev/null
  [[ $? = 0 ]] || abort "Bundler not found.\nTry running 'gem install bundler' to install it.\nAlso make sure it is in the root user's PATH variable."
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
tmp_dir="${root_dir}/workdir"
wakame_dir="${root_dir}/../.."
cd_dir="${tmp_dir}/mnt"
apt_dir="${root_dir}/guts/apt-ftparchive"
cd_mod_dir="${root_dir}/guts/wakame"
tmp_mount_dir="${tmp_dir}/$(randdir)"
wakame_version="11.12"
wakame_deb="${wakame_dir}/../wakame-vdc_${wakame_version}_amd64.deb"
arch="amd64"
src_image=`readlink -f $1`
dst_image="${root_dir}/wakame-vdc-${wakame_version}-${arch}.iso"
images_dir="${cd_dir}/setup/images"
remote_images_path=http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage
vmimage_file="ubuntu-10.04_with-metadata_kvm_i386.raw.gz"
gpg_key_id="DCFFB6BE"
guts_archive_dir="${root_dir}/guts/archive"
package_location_axsh="http://dlc.wakame.axsh.jp.s3.amazonaws.com/vdc/11.12.1/package/ubuntu/"
package_location='axsh'

[[ $UID = 0 ]] || abort "Operation not permitted. Try using sudo."

#Check if the source image exists
if [ ! -f ${src_image} ]; then
  abort "Couldn't find source image: ${src_image}"
fi


#Check if dependencies are installed
checkreq

#Make tmp dir if it doesn't exist
if [ -f ${tmp_dir} ]; then
  abort "Failed to create ${tmp_dir}. File exists."
elif [ ! -d ${tmp_dir} ]; then
  mkdir -p ${tmp_dir}
fi

#Clean the working directory
if [ -d ${wakame_dir}/tmp ]; then rm ${wakame_dir}/tmp/*; fi
if [ -f ${dst_image} ]; then rm -f ${dst_image}; fi
if [ -f ${apt_dir}/apt-ftparchive-deb.conf ]; then rm -f ${apt_dir}/apt-ftparchive-deb.conf; fi
if [ -f ${apt_dir}/apt-ftparchive-extras.conf ]; then rm -f ${apt_dir}/apt-ftparchive-extras.conf; fi
if [ -f ${apt_dir}/apt-ftparchive-udeb.conf ]; then rm -f ${apt_dir}/apt-ftparchive-udeb.conf; fi
if [ -f ${apt_dir}/release.conf ]; then rm -f ${apt_dir}/release.conf; fi
rm -rf ${root_dir}/guts/indices/

#Create directory
[ -d "${cd_mod_dir}/tmp" ] || mkdir "${cd_mod_dir}/tmp"
[ -d "${cd_mod_dir}/setup/images" ] || mkdir "${cd_mod_dir}/setup/images"
[ -d "${cd_mod_dir}/pool" ] || mkdir "${cd_mod_dir}/pool"
[ -d "${cd_mod_dir}/pool/extras" ] || mkdir "${cd_mod_dir}/pool/extras"
[ -d "${cd_mod_dir}/pool/main" ] || mkdir "${cd_mod_dir}/pool/main"
[ -d "${cd_mod_dir}/pool/main/u" ] || mkdir "${cd_mod_dir}/pool/main/u"
[ -d "${cd_mod_dir}/pool/main/u/ubuntu-keyring" ] || mkdir "${cd_mod_dir}/pool/main/u/ubuntu-keyring"

#Add the required gems to the debian package
echo "Adding required gems to the debian package to be built"
cd $wakame_dir/dcmgr
bundle package
cd $wakame_dir/frontend/dcmgr_gui
bundle package

[ -d $wakame_dir/debian/gems/ ] || mkdir -p $wakame_dir/debian/gems/
[ -d $wakame_dir/debian/gems/dcmgr/ ] || mkdir -p $wakame_dir/debian/gems/dcmgr/
[ -d $wakame_dir/debian/gems/frontend/ ] || mkdir -p $wakame_dir/debian/gems/frontend/

cp $wakame_dir/dcmgr/vendor/cache/*.gem $wakame_dir/debian/gems/dcmgr/
cp $wakame_dir/frontend/dcmgr_gui/vendor/cache/*.gem $wakame_dir/debian/gems/frontend/

#Put a bundler gem in the wakame package so we can run bundle install after the installation
BUNDLER=`gem fetch bundler | cut -d ' ' -f2`
mv $BUNDLER.gem $wakame_dir/debian/bundler.gem

#Make the debian package
cd ${wakame_dir}

if $FLAG_WITHOUT_GPG_SIGN; then
  debuild --no-lintian -us -uc
else
  #Check if the Axsh key is on the keyring
  gpg --list-secret-keys | grep -q $gpg_key_id
  if [ "$?" -ne "0" ]; then
    abort "Couldn't find Axsh Co. LTD's private gpg key on the keyring. This script needs it to sign the CD."
  fi
  
  debuild --no-lintian
fi

if [ ! -e ${wakame_deb} ]; then abort "Couldn't find wakame-vdc package: ${wakame_deb}"; fi
mv ${wakame_deb} ${cd_mod_dir}/pool/extras

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

download_package "${cd_mod_dir}/pool/extras/" "${guts_archive_dir}/pool_extras"
download_package "${cd_mod_dir}/pool/main/u/ubuntu-keyring/" "${guts_archive_dir}/pool_main"

#Get the indices
mkdir -p ${root_dir}/guts/indices
cd ${root_dir}/guts/indices
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

#Remove samba to clear some space
rm -rf ${cd_dir}/pool/main/s/samba

#Unzip Packages
cd ${cd_dir}/dists/${base_distro}/main/binary-amd64
gunzip Packages.gz

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
  BinOverride "${root_dir}/guts/indices/override.${base_distro}.main.debian-installer";
};

BinDirectory "pool/restricted" {
  Packages "dists/${base_distro}/restricted/debian-installer/binary-amd64/Packages";
  BinOverride "${root_dir}/guts/indices/override.${base_distro}.restricted.debian-installer";
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
  BinOverride "${root_dir}/guts/indices/override.${base_distro}.main";
  ExtraOverride "${root_dir}/guts/indices/override.${base_distro}.extra.main";
};

BinDirectory "pool/restricted" {
 Packages "dists/${base_distro}/restricted/binary-amd64/Packages";
 BinOverride "${root_dir}/guts/indices/override.${base_distro}.restricted";
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

#Create extra repository and sign with gpg key
echo "Signing extra repository"
rm -f ${cd_dir}/dists/${base_distro}/Release.gpg
cd ${apt_dir}
perl extraoverride.pl < ${cd_dir}/dists/${base_distro}/main/binary-amd64/Packages >> ${root_dir}/guts/indices/override.${base_distro}.extra.main

# Skip gpg sign
if ! $FLAG_WITHOUT_GPG_SIGN ; then
  ${PWD}/build_repository.sh ${cd_dir}
fi

#Compile iso
mkisofs -r -V "Wakame-vdc ${WAKAME_VERSION}" \
            -cache-inodes \
            -J -l -b isolinux/isolinux.bin \
            -c isolinux/boot.cat -no-emul-boot \
            -boot-load-size 4 -boot-info-table \
            -o $dst_image $cd_dir

#Clean up
umount ${tmp_mount_dir}
rmdir ${tmp_mount_dir}
rm -rf ${cd_dir}

rm -rf ${root_dir}/guts/indices/

#Delete ftparchive config files
if [ -f ${apt_dir}/apt-ftparchive-deb.conf ]; then rm -f ${apt_dir}/apt-ftparchive-deb.conf; fi
if [ -f ${apt_dir}/apt-ftparchive-extras.conf ]; then rm -f ${apt_dir}/apt-ftparchive-extras.conf; fi
if [ -f ${apt_dir}/apt-ftparchive-udeb.conf ]; then rm -f ${apt_dir}/apt-ftparchive-udeb.conf; fi
if [ -f ${apt_dir}/release.conf ]; then rm -f ${apt_dir}/release.conf; fi

#Delete debuild output
cd ${wakame_dir}
dh_clean
rm ${wakame_dir}/../wakame-vdc_${wakame_version}_amd64.build
rm ${wakame_dir}/../wakame-vdc_${wakame_version}.dsc
rm ${wakame_dir}/../wakame-vdc_${wakame_version}_amd64.changes
rm ${wakame_dir}/../wakame-vdc_${wakame_version}.tar.gz

echo "Created iso image ${dst_image}"
exit 0
