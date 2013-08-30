# -*-Shell-script-*-
#
# requires:
#   bash
#

function hash_value() {
  local key=$1 line

  #
  # NF=2) ":id: i-xxx"
  # NF=3) "- :vif_id: vif-qqjr0ial"
  #
  egrep -w ":${key}:" </dev/stdin | awk '{ if (NF == 2) {print $2} else if (NF == 3) {print $3} }'
}

function document_pair?() {
  local namespace=$1 uuid=$2 key=$3 val=$4
  # make sure to get value of first level key.
  #
  # [OK] ':state: running'
  # [NG] '  :state: attached'
  #
  [[ "$(run_cmd ${namespace} show ${uuid} | egrep -w "^:${key}:" | awk '{print $2}')" == "${val}" ]]
}

function yaml_find_first() {
  local key="$1"
  awk '$0 ~ key_pattern { print $(NF); exit; }' key_pattern=":$key:"
}

function yaml_find_last() {
  local key="$1"
  awk '$0 ~ key_pattern { last_item=$(NF) } END { print $last_item }' key_pattern=":$key:"
}

# Convert YAML text to "/" delimitered format for retrieving from shell script.
#cat <<EOF | ydump
#---
#:xxxx:
#  :yyyy: 2
#  :zzzz: 3
#:oooo:
#- a
#- b
#EOF
#
#:xxxx:/:yyyy:=2
#:xxxx:/:zzzz:=3
#:oooo:/0=a
#:oooo:/1=b
#
function ydump() {
  # nm: namespace array
  # lv:  namespace level
  # cidt: current indent depth
  # lidt: last indent depth
  # ac: array counter
  awk -v lv=1 -v ac=0 -v cidt=1 -v lidt=1 'BEGIN{ }
function path_join(ary, _i,_r,_s) { _r = ary[1]; for(_i = 2; _i <= length(ary); _i++){ _r = _r "/" ary[_i];}; return _r; }
{ match($0, /[^ ]+/); cidt=RSTART; }
$1 == "-" { cidt = cidt + 2; }
cidt < lidt { delete nm[lv]; lv--; }
cidt > lidt { lv++; ac=0; }
$1 ~ /^:?[[:alnum:]_]+:/ && NF == 1 { nm[lv]=$1; }
$1 ~ /^:?[[:alnum:]_]+:/ && NF == 2 { print path_join(nm) "/" $1 "=" $2; }
# 
$1 == "-" { nm[lv]=ac++; }
$1 == "-" && NF == 2 { print path_join(nm) "=" $2; }
$1 == "-" && $2 ~ /^:?[[:alnum:]_]+:/ && NF == 3 { print path_join(nm) "/" $2 "=" $3; }
{ lidt=cidt; }'
}

# Return value part from ydump() format.
# ydump | yfind '/0/:uuid:'
function yfind() {
  awk -v key="$1" -F= '$1 == key { print $2; exit; }'
}
