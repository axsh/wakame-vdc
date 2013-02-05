# -*-Shell-script-*-
#
# description:
#  builder
#
# requires:
#  bash, pwd
#
# utils:   checkroot
# inifile: eval_ini, csv2lsv
#

##
[[ -z "${__FUNCTIONS_BUILDER_INCLUDED__}" ]] || return 0

##
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/utils.sh
. $(cd ${BASH_SOURCE[0]%/*} && pwd)/inifile.sh

##
function preflight_builder_check() {
  [[ -d "${suite_path}"               ]] || { echo "[ERROR] directory not found: ${suite_path} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -f "${suite_path}/execscript.sh" ]] || { echo "[ERROR] file not found: execscript.sh (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -f "${suite_path}/image.ini"     ]] || { echo "[ERROR] file not found: image.ini (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
}

function vmbuilder_dir() {
  echo ${BASH_SOURCE[0]%/*}/../tmp/vmbuilder
}

function setup_vmbuilder() {
  local vmbuilder_dir=$(vmbuilder_dir)
  [[ -d "${vmbuilder_dir}" ]] || git clone https://github.com/axsh/vmbuilder.git ${vmbuilder_dir}
  (
    cd ${vmbuilder_dir}
    git reset --hard ${vmbuilder_git_hash:-HEAD}
  )
}

function vmbuilder_path() {
  echo $(vmbuilder_dir)/kvm/rhel/6/vmbuilder.sh
}

function vmbootstrap() {
  cat <<EOS
ROOTPATH="${ROOTPATH}" \
VDC_METADATA_TYPE=${vdc_metadata_type} \
VDC_DISTRO_NAME=${vm_distro_name} \
 $(vmbuilder_path) \
   --hypervisor    ${vm_hypervisor} \
   --distro-name   ${vm_distro_name} \
   --distro-ver    ${vm_distro_ver} \
   --distro-arch   ${vm_arch} \
   --distro-dir    /var/tmp/vmbuilder/${vm_distro_name}-${vm_distro_ver}_${vm_arch} \
   --rootsize      ${vm_rootsize} \
   --swapsize      ${vm_swapsize} \
   --keepcache     ${vm_keepcache:-0} \
   --fstab-type    ${vm_fstab_type} \
   --sshd-passauth ${vm_sshd_passauth} \
   --execscript    $(pwd)/execscript.sh \
   $([[ -f "$(pwd)/copy.txt" ]] && echo \
   --copy          $(pwd)/copy.txt
   ) \
   --rootfs_dir    ${vm_rootfs} \
   --raw           ${vm_rootfs}.raw
EOS
}

function load_image_ini() {
  local inifile_path=${1:-image.ini}
  [[ -f "${inifile_path}" ]] || { echo "[ERROR] file not found: ${inifile_path} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  eval_ini ${inifile_path} vmbuilder  vm
  eval_ini ${inifile_path} wakame-vdc vdc

  cat <<-EOS
	${inifile_path}
	---------
	vm_hypervisor     "${vm_hypervisor}"
	vm_distro_name    "${vm_distro_name}"
	vm_distro_ver     "${vm_distro_ver}"
	vm_rootsize       "${vm_rootsize}"
	vm_swapsize       "${vm_swapsize}"
	vm_arch           "${vm_arch}"
	vm_sshd_passauth  "${vm_sshd_passauth}"
	vm_fstab_type     "${vm_fstab_type}"
	vdc_metadata_type "${vdc_metadata_type}"
	---------
	EOS
}

function build_vm() {
  local suite_path=$1
  [[ -d "${suite_path}" ]] || { echo "[ERROR] directory not found: ${suite_path} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  checkroot || return 1
  preflight_builder_check || return 1
  setup_vmbuilder

  cd ${suite_path}
  load_image_ini image.ini

  local vm_hypervisors=$(csv2lsv ${vm_hypervisor})
  local vm_archs=$(csv2lsv ${vm_arch})
  local vdc_metadata_types=$(csv2lsv ${vdc_metadata_type})
  local vm_hypervisor vm_arch vdc_metadata_type
  local storage_types storage_type

  for vm_hypervisor in ${vm_hypervisors}; do
    case "${vm_hypervisor}" in
    kvm)
      storage_types="disk"
      ;;
    lxc|openvz)
      storage_types="disk diskless"
      ;;
    esac

    for vm_arch in ${vm_archs}; do
      for vdc_metadata_type in ${vdc_metadata_types}; do
        for storage_type in ${storage_types}; do
          vm_rootfs=${vm_name}.${vm_arch}.${vm_hypervisor}.${vdc_metadata_type}

          case "${storage_type}" in
          disk)
            eval $(vmbootstrap)
            echo "[INFO] Compressing ${vm_rootfs}.raw"
            tar zScvpf ${vm_rootfs}.raw.tar.gz ${vm_rootfs}.raw
            echo "[INFO] Compressed => ${vm_rootfs}.raw.tar.gz"
            ;;
          diskless)
            [[ -d "${vm_rootfs}" ]] && rm -rf ${vm_rootfs} || :
            eval $(vmbootstrap) --diskless
            echo "[INFO] Packing ${vm_rootfs}"
            tar zcpf ${vm_rootfs}.tar.gz ${vm_rootfs}
            echo "[INFO] Packed => ${vm_rootfs}.tar.gz"
            rm -rf ${vm_rootfs}
            ;;
          esac
        done
      done
    done
  done

  cd - >/dev/null
}

##
__FUNCTIONS_BUILDER_INCLUDED__=1
