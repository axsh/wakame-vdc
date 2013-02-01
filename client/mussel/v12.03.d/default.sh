# -*-Shell-script-*-
#
# 12.03
#

case "${cmd}" in
help)    cmd_help    ${namespace} "index|show|xcreate" ;;
index)   cmd_index   $* ;;
show)    cmd_show    $* ;;
xcreate) cmd_xcreate ${1} ;;
*)       cmd_default $* ;;
esac
