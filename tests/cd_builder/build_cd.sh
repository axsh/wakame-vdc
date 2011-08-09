#!/bin/bash

#Function to generate the mount directory later on
function randdir {
  dir=`</dev/urandom tr -dc A-Za-z0-9 | head -c8`
  while [ -d ${dir} ] || [ -f ${dir} ]; do
    dir=`</dev/urandom tr -dc A-Za-z0-9 | head -c8`
  done
  echo ${dir}
}

function abort() {
  echo "Error: "$* >&2
  exit 1
}

root_dir="$( cd "$( dirname "$0" )" && pwd )"
wakame_dir="${root_dir}/../.."
cd_dir="${root_dir}/guts/$(randdir)"
apt_dir="${root_dir}/guts/apt-ftparchive"
cd_mod_dir="${root_dir}/guts/wakame"
tmp_mount_dir="${root_dir}/"$(randdir)
wakame_version="11.06"
arch="amd64"
src_image="${root_dir}/../../../ubuntu-10.04.2-server-amd64.iso"
dst_image="${root_dir}/wakame-vdc-${wakame_version}-${arch}.iso"
guts_local="${root_dir}/cd_creation_bulk.tar.gz"
guts_remote="http://dlc.wakame.axsh.jp.s3.amazonaws.com/vdc/11.06/cd/cd_creation_bulk.tar.gz"
base_distro="lucid"

#TODO: download ubuntu iso if it's not present
#if [ ! -f ${src_image} ]; then
  #wget http://ftp.yz.yamagata-u.ac.jp/pub/linux/ubuntu/releases/${base_distro}/ubuntu-10.04.2-server-amd64.iso
#fi

[[ $UID = 0 ]] || abort "Operation not permitted. Try using sudo."

#Check if the source image exists
if [ ! -f ${src_image} ]; then
  abort "Couldn't find source image: ${src_image}"
fi

#Check if perl is installed
which perl >> /dev/null
[[ $? = 0 ]] || abort "This script needs perl to be installed and added to the PATH variable."

#Download guts
#if [ ! -f ${guts_local} ]; then
  #wget -P ${root_dir} ${guts_remote}
  #[[ $? = 0 ]] || abort "Failed to download the files needed to make the cd."
#fi
#tar xzf ${guts_local}

#Get the indices
mkdir -p ${root_dir}/guts/indices
cd ${root_dir}/guts/indices
for SUFFIX in extra.main main main.debian-installer restricted restricted.debian-installer; do
  wget http://archive.ubuntu.com/ubuntu/indices/override.$base_distro.$SUFFIX
done

#Make the debian package
cd ${wakame_dir}
debuild --no-lintian
mv ../wakame-vdc_${wakame_version}_all.deb ${cd_mod_dir}/pool/extras

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


#Create extra repository and sign with gpg key
echo "Signing extra repository"
rm -f ${cd_dir}/dists/${base_distro}/Release.gpg
cd ${apt_dir}
perl extraoverride.pl < ${cd_dir}/dists/${base_distro}/main/binary-amd64/Packages >> ${root_dir}/guts/indices/override.${base_distro}.extra.main
echo "${PWD}/build_repository.sh ${cd_dir}"
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

#Quick and dirty indices clean
rm -f ${root_dir}/guts/indices/*

#Delete debuild output
cd ${wakame_dir}
dh_clean
rm ${wakame_dir}/../wakame-vdc_${wakame_version}_amd64.build
rm ${wakame_dir}/../wakame-vdc_${wakame_version}.dsc
rm ${wakame_dir}/../wakame-vdc_${wakame_version}_amd64.changes
rm ${wakame_dir}/../wakame-vdc_${wakame_version}.tar.gz
