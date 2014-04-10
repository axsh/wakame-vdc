# -*-Shell-script-*-
#
# requires:
#   bash
#

function extract_uuid() {
  local key=$1
  awk '{if(match($0,/'${key}'\-[0-9a-zA-Z]+/)){print substr($0, RSTART, RLENGTH);}}'
}

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
  awk -v lv=1 -v ac=0 -v cidt=1 -v lidt=1 'BEGIN{ nm[1]=""; }
function path_join(ary, _i,_r,_s) { _r=""; for(_i = 1; _i <= lv; _i++){ _r = _r "/" ary[_i];}; sub("/$", "", _r); sub("^/+", "", _r); return _r; }
# get the current indent depth.
{ match($0, /[^ ]+/); cidt=RSTART;}
$1 == "-" { cidt = cidt + 2; }
# indent level calculation for level down case.
cidt < lidt {
  for(_i=1; _i <= ((lidt - cidt) / 2); _i++){
    lv--;
    if ( nm[lv] ~ /^[[:digit:]]+$/ ){ lv--; ac=nm[lv]; }
  }
}
# indent level calculation for level up case.
cidt > lidt { lv++; }
cidt > lidt && $1 == "-" { ac=0; nm[lv]=ac; lv++; }
cidt == lidt && $1 == "-" { ac++; nm[lv-1]=ac; }
$1 ~ /^:?[[:alnum:]_]+:/ { nm[lv]=$1; }
$1 ~ /^:?[[:alnum:]_]+:/ && NF == 1 { print path_join(nm) "="; }
$1 ~ /^:?[[:alnum:]_]+:/ && NF == 2 { print path_join(nm) "=" $2; }
# 
$1 == "-" && $2 ~ /^:?[[:alnum:]_]+:/ { nm[lv]=$2; }
$1 == "-" && $2 !~ /^:?[[:alnum:]_]+:/ && NF == 2 { print path_join(nm) "=" $2; }
$1 == "-" && $2 ~ /^:?[[:alnum:]_]+:/ && NF == 3 { print path_join(nm) "=" $3; }
{ lidt=cidt; }'
}

# Return value part from ydump() format.
# ydump | yfind '/0/:uuid:'
function yfind() {
  awk -v key="$1" -F= '$1 == key { print $2; exit; }'
}
