#!/bin/bash

set -e
set -x

mode=$1

args=
while [ $# -gt 0 ]; do
  arg="$1"
  case "${arg}" in
    --*=*)
      key=${arg%%=*}; key=$(echo ${key##--} | tr - _)
      value=${arg##--*=}
      eval "${key}=\"${value}\""
      ;;
    *)
      args="${args} ${arg}"
      ;;
  esac
  shift
done

abs_path=$(cd $(dirname $0) && pwd)
arch=${arch:-$(arch)}
case ${arch} in
i*86)   basearch=i386; arch=i686;;
x86_64) basearch=${arch};;
esac

vendor_dir=${vendor_dir:-${abs_path}/vendor}
vendor_dir=${vendor_dir}/${basearch}
[ -d ${vendor_dir} ] || mkdir -p ${vendor_dir}

function list_3rd_party_builder() {
  cat <<EOS | egrep -v ^#
# pkg_name                         pkg_uri                                                                        pkg_file
flog                   git://github.com/hansode/env-builder.git                                                   flog-1.8-3.${basearch}.rpm
openvswitch            git://github.com/hansode/env-builder.git                                                   kmod-openvswitch-1.6.1-1.el6.${arch}.rpm
openvswitch            git://github.com/hansode/env-builder.git                                                   openvswitch-1.6.1-1.${arch}.rpm
lxc                    git://github.com/hansode/env-builder.git                                                   lxc-0.7.5-1.${arch}.rpm
EOS
}

function list_3rd_party() {
  vdc_current_base_url=http://dlc.wakame.axsh.jp.s3.amazonaws.com/packages/rhel/6/current/${basearch}
  cat <<EOS | egrep -v ^#
# pkg_name                pkg_uri
epel-release-6-8          http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/6/i386/epel-release-6-8.noarch.rpm
elrepo-release            http://elrepo.org/elrepo-release-6-4.el6.elrepo.noarch.rpm
rabbitmq-server-2.7.1     http://www.rabbitmq.com/releases/rabbitmq-server/v2.7.1/rabbitmq-server-2.7.1-1.noarch.rpm
flog                      ${vdc_current_base_url}/flog-1.8-3.${basearch}.rpm
openvswitch               ${vdc_current_base_url}/kmod-openvswitch-1.6.1-1.el6.${arch}.rpm
openvswitch               ${vdc_current_base_url}/openvswitch-1.6.1-1.${arch}.rpm
lxc                       ${vdc_current_base_url}/lxc-0.7.5-1.${arch}.rpm
EOS
}

function prepare_3rd_party() {
  rpm -qi curl >/dev/null || yum install -y curl
  list_3rd_party_builder | while read pkg_name pkg_uri pkg_file; do
    echo downloading ${pkg_name} ...
    case ${pkg_uri} in
    git://*)
      [ -d ${vendor_dir}/$(basename ${pkg_uri%%.git}) ] && {
        (cd ${vendor_dir}/$(basename ${pkg_uri%%.git}) && git pull)
      } || {
        (cd ${vendor_dir} && git clone ${pkg_uri})
      }
      ;;
    esac
  done
}

function build_3rd_party() {
  list_3rd_party_builder | while read pkg_name pkg_uri pkg_file; do
    case ${pkg_uri} in
    git://*)
      (cd ${vendor_dir}/$(basename ${pkg_uri%%.git})/rhel/6/${pkg_name} && BUILD_ARCH=${arch} make build)
      ;;
    esac
  done
}

function deploy_3rd_party() {
  list_3rd_party_builder | while read pkg_name pkg_uri pkg_file; do
    case ${pkg_name} in
    flog)
      cp ${vendor_dir}/$(basename ${pkg_uri%%.git})/rhel/6/${pkg_name}/${pkg_file} ${vendor_dir}/.
      ;;
    openvswitch|kmod-openvswitch-vzkernel)
      cp ${HOME}/rpmbuild/RPMS/${arch}/${pkg_file} ${vendor_dir}/.
      ;;
    lxc)
      cp /root/rpmbuild/RPMS/${arch}/${pkg_file} ${vendor_dir}/.
      ;;
    esac
  done
}

function download_3rd_party() {
  rpm -qi curl >/dev/null || yum install -y curl
  [ -f ${vendor_dir}/openvz.repo ] || {
    rsync -a ${abs_path}/../../../rpmbuild/openvz.repo -o ${vendor_dir}/openvz.repo
  }

  list_3rd_party | while read pkg_name pkg_uri; do
    pkg_file=$(basename ${pkg_uri})
    echo downloading ${pkg_name} ...
    case ${pkg_uri} in
    http://*)
      [ -f ${vendor_dir}/${pkg_file} ] || {
        curl -R ${pkg_uri} -o ${vendor_dir}/${pkg_file}
      }
      ;;
    esac
  done
}

function install_3rd_party() {
  rsync -a ${vendor_dir}/openvz.repo /etc/yum.repos.d/openvz.repo

  list_3rd_party | while read pkg_name pkg_uri; do
    pkg_file=$(basename ${pkg_uri})
    rpm -qi ${pkg_name} >/dev/null || yum install -y --nogpgcheck ${vendor_dir}/${pkg_file}
  done
}


case ${mode} in
prepare)
  prepare_3rd_party
  ;;
build)
  build_3rd_party
  ;;
deploy)
  deploy_3rd_party
  ;;
download)
  # prepare_3rd_party
  # build_3rd_party
  # deploy_3rd_party
  download_3rd_party
  ;;
install)
  install_3rd_party
  ;;
esac
