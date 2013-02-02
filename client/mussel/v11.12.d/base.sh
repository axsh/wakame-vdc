# -*-Shell-script-*-
#
# 11.12
#

case "${cmd}" in
help)    cmd_help    ${namespace} "index|show" ;;
index)   cmd_index   $* ;;
show)    cmd_show    $* ;;
*)       cmd_default $* ;;
esac
