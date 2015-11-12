function run_in_target()
{
    local chroot_dir=$1; shift; local args="$*"
    [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

    chroot ${chroot_dir} bash -e -c "${args}"
}

function create_user_account()
{
    local chroot_dir=$1 user_name=$2 gid=$3 uid=$4
    [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
    [[ -n "${user_name}"  ]] || { echo "[ERROR] Invalid argument: user_name:${user_name} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

    printf "[INFO] Creating user: %s\n" ${user_name}

    local user_group=${user_name}
    local user_home=/home/${user_name}

    run_in_target ${chroot_dir} "getent group  ${user_group} >/dev/null || groupadd $([[ -z ${gid} ]] || echo --gid ${gid}) ${user_group}"
    run_in_target ${chroot_dir} "getent passwd ${user_name}  >/dev/null || useradd  $([[ -z ${uid} ]] || echo --uid ${uid}) -g ${user_group} -d ${user_home} -s /bin/bash -m ${user_name}"

    egrep -q ^umask ${chroot_dir}/${user_home}/.bashrc || {
	echo umask 022 >> ${chroot_dir}/${user_home}/.bashrc
    }
}

function configure_sudo_sudoers()
{
    local chroot_dir=$1 user_name=$2 tag_specs=${3:-"NOPASSWD:"}
    [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
    [[ -n "${user_name}"  ]] || { echo "[ERROR] Invalid argument: user_name:${user_name} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
    #
    # Tag_Spec ::= ('NOPASSWD:' | 'PASSWD:' | 'NOEXEC:' | 'EXEC:' |
    #               'SETENV:' | 'NOSETENV:' | 'LOG_INPUT:' | 'NOLOG_INPUT:' |
    #               'LOG_OUTPUT:' | 'NOLOG_OUTPUT:')
    #
    # **don't forget suffix ":" to tag_specs.**
    #
    egrep ^${user_name} -w ${chroot_dir}/etc/sudoers || { echo "${user_name} ALL=(ALL) ${tag_specs} ALL" >> ${chroot_dir}/etc/sudoers; }
}

function cause_daemons_starting()
{
    local chroot_dir=$1; shift
    [[ -d "${chroot_dir}" ]] || { echo "[ERROR] directory not found: ${chroot_dir} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

    while [[ $# -ne 0 ]]; do
	run_in_target ${chroot_dir} sysv-rc-conf $1 on
	shift
    done
}

function config_sshd_config()
{
    local sshd_config_path=$1 keyword=$2 value=$3
    [[ -a "${sshd_config_path}" ]] || { echo "[ERROR] file not found: ${sshd_config_path} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
    [[ -n "${keyword}" ]] || { echo "[ERROR] Invalid argument: keyword:${keyword} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
    [[ -n "${value}"   ]] || { echo "[ERROR] Invalid argument: value:${value} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

    egrep -q -w "^${keyword}" ${sshd_config_path} && {
	# enabled
	sed -i "s,^${keyword}.*,${keyword} ${value},"  ${sshd_config_path}
    } || {
	# commented parameter is "^#keyword value".
	# therefore this case should *not* be included white spaces between # and keyword.
	egrep -q -w "^#${keyword}" ${sshd_config_path} && {
	    # disabled
	    sed -i "s,^#${keyword}.*,${keyword} ${value}," ${sshd_config_path}
	} || {
	    # no match
	    echo "${keyword} ${value}" >> ${sshd_config_path}
	}
    }
    egrep -q -w "^${keyword} ${value}" ${sshd_config_path}
}
