#!/bin/bash

set -e

mode=$1

args=
while [ $# -gt 0 ]; do
  arg="$1"
  case "${arg}" in
    --*=*)
      key=${arg%%=*}; key=${key##--}
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
vendor_dir=${vendor_dir:-${abs_path}/vendor}
[ -d ${vendor_dir} ] || mkdir -p ${vendor_dir}
arch=$(arch)

function list_3rd_party() {
  cat <<EOS | egrep -v ^#
# pkg_name                         pkg_uri                                                                        pkg_file
epel-release-6-5       http://ftp.riken.go.jp/pub/Linux/fedora/epel/6/i386/epel-release-6-5.noarch.rpm            epel-release-6-5.noarch.rpm
rabbitmq-server-2.6.1  http://www.rabbitmq.com/releases/rabbitmq-server/v2.6.1/rabbitmq-server-2.6.1-1.noarch.rpm rabbitmq-server-2.6.1-1.noarch.rpm
flog                   git://github.com/hansode/env-builder.git                                                   flog-1.8-3.${arch}.rpm
openvswitch            git://github.com/hansode/env-builder.git                                                   kmod-openvswitch-1.4.1-1.el6.${arch}.rpm
openvswitch            git://github.com/hansode/env-builder.git                                                   openvswitch-1.4.1-1.${arch}.rpm
lxc                    git://github.com/hansode/env-builder.git                                                   lxc-0.7.5-1.${arch}.rpm
EOS
}

function prepare_3rd_party() {
  rpm -qi curl >/dev/null || yum install -y curl
  list_3rd_party | while read pkg_name pkg_uri pkg_file; do
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
  list_3rd_party | while read pkg_name pkg_uri pkg_file; do
    case ${pkg_uri} in
    git://*)
      (cd ${vendor_dir}/$(basename ${pkg_uri%%.git})/rhel/6/${pkg_name} && make build)
      ;;
    esac
  done
}

function deploy_3rd_party() {
  list_3rd_party | while read pkg_name pkg_uri pkg_file; do
    case ${pkg_name} in
    flog)
      mv ${vendor_dir}/$(basename ${pkg_uri%%.git})/rhel/6/${pkg_name}/${pkg_file} ${vendor_dir}/.
      ;;
    openvswitch)
      cp ${HOME}/rpmbuild/RPMS/${arch}/${pkg_file} ${vendor_dir}/.
      ;;
    lxc)
      sudo cp /root/rpmbuild/RPMS/${arch}/${pkg_file} ${vendor_dir}/.
      ;;
    esac
  done
}

function download_3rd_party() {
  rpm -qi curl >/dev/null || yum install -y curl
  [ -f ${vendor_dir}/openvz.repo ] || {
    curl http://download.openvz.org/openvz.repo > ${vendor_dir}/openvz.repo
  }

  list_3rd_party | while read pkg_name pkg_uri pkg_file; do
    echo downloading ${pkg_name} ...
    case ${pkg_uri} in
    http://*)
      [ -f ${vendor_dir}/${pkg_file} ] || {
        curl ${pkg_uri} > ${vendor_dir}/${pkg_file}
      }
      ;;
    esac
  done
}

function install_3rd_party() {
  rsync -a ${vendor_dir}/openvz.repo /etc/yum.repos.d/openvz.repo

  list_3rd_party | while read pkg_name pkg_uri pkg_file; do
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
  prepare_3rd_party
  build_3rd_party
  deploy_3rd_party
  download_3rd_party
  ;;
install)
  install_3rd_party
  ;;
esac
