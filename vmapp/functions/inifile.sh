# -*-Shell-script-*-
#
# description:
#  ini file
#
# requires:
#  bash, pwd
#  sed, cat, egrep
#
# imports:
#

##
[[ -z "${__FUNCTIONS_INIFILE_INCLUDED__}" ]] || return 0

##
function normalize_ini() {
  # based on http://www.debian-administration.org/articles/55

  sed \
   -e 's/[[:space:]]*\=[[:space:]]*/=/g' \
   -e 's/;.*$//' \
   -e 's/[[:space:]]*$//' \
   -e 's/^[[:space:]]*//' \
   -e "s/^\(.*\)=\([^\"']*\)$/\1=\"\2\"/" \
   < <(cat $* | egrep -v '^#')
}

function ini_section() {
  local section=$1
  [[ -n "${section}" ]] || { echo "[ERROR] Invalid argument: section:${section} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  sed -n -e "/^\[${section}\]/,/^\s*\[/{/^[^;].*\=.*/p;}" <(normalize_ini <(cat))
}

function inikey2sh() {
  # '-' -> '_'

  while read line; do
    key=${line%%=*}; key=${key//-/_}
    value=${line##*=}
    echo "${key}=${value}"
  done < <(cat $*)
}

function parse_ini() {
  local section=$1; shift
  [[ -n "${section}" ]] || { echo "[ERROR] Invalid argument: section:${section} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  ini_section ${section} < <(cat $*) | inikey2sh
}

function eval_ini() {
  local inifile_path=$1 section=$2 prefix=$3
  [[ -a "${inifile_path}" ]] || { echo "[ERROR] file not found: ${inifile_path} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }
  [[ -n "${section}"      ]] || { echo "[ERROR] Invalid argument: section:${section} (${BASH_SOURCE[0]##*/}:${LINENO})" >&2; return 1; }

  [[ -z "${prefix}" ]] || prefix="${prefix}_"
  eval "$(parse_ini ${section} ${inifile_path} | sed "s,^,${prefix},")"
}

function csv2lsv() {
  #
  # CSV(comma-separeted values) => LSV(line-separeted values)
  # "a, b, c" => "a\nb\nc\n"
  #
  local saved_ifs=${IFS} subcmd=cat
  [[ $# == 0 ]] || subcmd='echo "$*"'

  local line=
  IFS=,
  while read line; do echo ${line}; done < <(eval "${subcmd} | sed \"s, ,\n,g\"")
  IFS=${saved_ifs}
}

##
__FUNCTIONS_INIFILE_INCLUDED__=1
