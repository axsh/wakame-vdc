# -*-Shell-script-*-
#
# 12.03
#

case "${cmd}" in
help)    cmd_help    ${namespace} "index|show|xcreate|destroy" ;;
index)   cmd_index   $* ;;
show)    cmd_show    $* ;;
destroy) cmd_destroy $* ;;
xcreate) cmd_xcreate ${namespace} ;;
*)       cmd_default $* ;;
esac
