#!/bin/bash

#Function to generate the mount directory later on
function randdir {
  dir=`</dev/urandom tr -dc A-Za-z0-9 | head -c8`
  while [ -d ${dir} ] || [ -f ${dir} ]; do
    dir=`</dev/urandom tr -dc A-Za-z0-9 | head -c8`
  done
  echo ${dir}
}

function checkreq {
  exec=$1
  pkg=$2
  which $exec >> /dev/null
  [[ $? = 0 ]] || abort "This script needs $pkg to be installed\nTry running 'apt-get install $pkg'."
}

function abort() {
  echo -e "Error: "$* >&2
  exit 1
}

#Check if argument was given at all
if [ -z "$1" ]; then
  abort "No source image given.\nUsage: $0 /path/to/ubuntu-${base_distro}-image"
fi

root_dir="$( cd "$( dirname "$0" )" && pwd )"
tmp_dir="/var/tmp"
wakame_dir="${root_dir}/../.."
cd_dir="${root_dir}/guts/$(randdir)"
apt_dir="${root_dir}/guts/apt-ftparchive"
cd_mod_dir="${root_dir}/guts/wakame"
tmp_mount_dir="${root_dir}/"$(randdir)
wakame_version="11.06"
wakame_deb="${wakame_dir}/../wakame-vdc_${wakame_version}_all.deb"
arch="amd64"
src_image=`readlink -f $1`
dst_image="${root_dir}/wakame-vdc-${wakame_version}-${arch}.iso"
guts_local="${tmp_dir}/cd_creation_bulk.tar.gz"
guts_remote="http://dlc.wakame.axsh.jp.s3.amazonaws.com/vdc/11.06/cd/cd_creation_bulk.tar.gz"
base_distro="lucid"
base_distro_number="10.04"

#TODO: download ubuntu iso if it's not present
#if [ ! -f ${src_image} ]; then
  #wget http://ftp.yz.yamagata-u.ac.jp/pub/linux/ubuntu/releases/${base_distro}/ubuntu-10.04.2-server-amd64.iso
#fi

[[ $UID = 0 ]] || abort "Operation not permitted. Try using sudo."

#Check if the source image exists
if [ ! -f ${src_image} ]; then
  abort "Couldn't find source image: ${src_image}"
fi

#Check if dependencies are installed
checkreq "perl" "perl"
checkreq "debuild" "devscripts"
checkreq "dh_clean" "debhelper"
checkreq "mkisofs" "genisoimage"

#Make tmp dir if it doesn't exist
if [ -f ${tmp_dir} ]; then
  abort "Failed to create ${tmp_dir}. File exists."
elif [ ! -d ${tmp_dir} ]; then
  mkdir -p ${tmp_dir}
fi

#Check if guts exist
if [ ! -f ${guts_local} ]; then
  wget -P ${tmp_dir} ${guts_remote}
  [[ $? = 0 ]] || abort "Failed to download the files needed to make the cd.\n${guts_remote} was not found."
fi

#Clean the working directory
if [ -f ${dst_image} ]; then rm -f ${dst_image}; fi
if [ -f ${apt_dir}/apt-ftparchive-deb.conf ]; then rm -f ${apt_dir}/apt-ftparchive-deb.conf; fi
if [ -f ${apt_dir}/apt-ftparchive-extras.conf ]; then rm -f ${apt_dir}/apt-ftparchive-extras.conf; fi
if [ -f ${apt_dir}/apt-ftparchive-udeb.conf ]; then rm -f ${apt_dir}/apt-ftparchive-udeb.conf; fi
if [ -f ${apt_dir}/release.conf ]; then rm -f ${apt_dir}/release.conf; fi
rm -rf ${root_dir}/guts/indices/
rm -rf ${root_dir}/guts/wakame

#Make the debian package
cd ${wakame_dir}
debuild --no-lintian

if [ ! -f ${wakame_deb} ]; then abort "Couldn't find wakame-vdc package: ${wakame_deb}"; fi

#Extract guts
tar xzf ${guts_local} -C ${root_dir}
mv ${wakame_deb} ${cd_mod_dir}/pool/extras

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

#Unzip Packages
cd ${cd_dir}/dists/${base_distro}/main/binary-amd64
gunzip Packages.gz

#Wakamize it
echo "Adding wakame-vdc to it"
cp -r ${cd_mod_dir}/* ${cd_dir}

#Generate .conf files for signing the repositories
cd ${apt_dir}
echo "Dir {
  ArchiveDir \"${cd_dir}\";
};

TreeDefault {
  Directory \"pool/\";
};

BinDirectory \"pool/main\" {
  Packages \"dists/${base_distro}/main/debian-installer/binary-amd64/Packages\";
  BinOverride \"${root_dir}/guts/indices/override.${base_distro}.main.debian-installer\";
};

BinDirectory \"pool/restricted\" {
  Packages \"dists/${base_distro}/restricted/debian-installer/binary-amd64/Packages\";
  BinOverride \"${root_dir}/guts/indices/override.${base_distro}.restricted.debian-installer\";
};

Default {
  Packages {
    Extensions \".udeb\";
    Compress \". gzip\";
  };
};

Contents {
  Compress \"gzip\";
};" > apt-ftparchive-udeb.conf

echo "Dir {
  ArchiveDir \"${cd_dir}\";
};

TreeDefault {
  Directory \"pool/\";
};

BinDirectory \"pool/extras\" {
  Packages \"dists/${base_distro}/extras/binary-amd64/Packages\";
};

Default {
  Packages {
    Extensions \".deb\";
    Compress \". gzip\";
  };
};

Contents {
  Compress \"gzip\";
};" > apt-ftparchive-extras.conf

echo "Dir {
  ArchiveDir \"${cd_dir}\";
};

TreeDefault {
  Directory \"pool/\";
};

BinDirectory \"pool/main\" {
  Packages \"dists/${base_distro}/main/binary-amd64/Packages\";
  BinOverride \"${root_dir}/guts/indices/override.${base_distro}.main\";
  ExtraOverride \"${root_dir}/guts/indices/override.${base_distro}.extra.main\";
};

BinDirectory \"pool/restricted\" {
 Packages \"dists/${base_distro}/restricted/binary-amd64/Packages\";
 BinOverride \"${root_dir}/guts/indices/override.${base_distro}.restricted\";
};

Default {
  Packages {
    Extensions \".deb\";
    Compress \". gzip\";
  };
};

Contents {
  Compress \"gzip\";
};" > apt-ftparchive-deb.conf

echo "APT::FTPArchive::Release::Origin \"Ubuntu\";
APT::FTPArchive::Release::Label \"Ubuntu\";
APT::FTPArchive::Release::Suite \"${base_distro}\";
APT::FTPArchive::Release::Version \"${base_distro_number}\";
APT::FTPArchive::Release::Codename \"${base_distro}\";
APT::FTPArchive::Release::Architectures \"${arch}\";
APT::FTPArchive::Release::Components \"main restricted extras\";
APT::FTPArchive::Release::Description \"Ubuntu ${base_distro_number} LTS\";" > release.conf


#Create extra repository and sign with gpg key
echo "Signing extra repository"
rm -f ${cd_dir}/dists/${base_distro}/Release.gpg
cd ${apt_dir}
perl extraoverride.pl < ${cd_dir}/dists/${base_distro}/main/binary-amd64/Packages >> ${root_dir}/guts/indices/override.${base_distro}.extra.main
${PWD}/build_repository.sh ${cd_dir}

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
rm -rf ${root_dir}/guts/wakame

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
