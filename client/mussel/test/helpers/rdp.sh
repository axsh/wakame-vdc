# -*-Shell-script-*-
#
# requires:
#   bash
#   rm, ln, xfreerdp
#

function xfreerdp() {
  type -P xfreerdp >/dev/null || return 1

  ignore_freerdp_local_database
  "$(type -P xfreerdp)" --ignore-certificate "${@}"
}

function ignore_freerdp_local_database() {
  rm   -rf ${HOME}/.freerdp
  ln -fs /dev/null ${HOME}/.freerdp
}

function rdp_auth() {
  xfreerdp --authonly "${@}" >/dev/null 2>&1
}

function rdp_connect() {
  xfreerdp "${@}"
}
