#
# Wakame-vdc variable init sccript
#
#

#
# generic network configuration
#

# Some linux distribution (e.g. Gentoo) does not have /sbin/ip defaults.
# In wakame.sh install, it will be introduced.
if [ -f /sbin/ip ]; then
  ipaddr=${ipaddr:-$(/sbin/ip route get 8.8.8.8 | head -1 | awk '{print $7}')}
  ipv4_gw="${ipv4_gw:-$(/sbin/ip route get 8.8.8.8 | head -1 | awk '{print $3}')}"
  prefix_len="${prefix_len:-$(/sbin/ip route show | awk '$9 == ip { sub(/.*\//, "", $1); print $1; }' ip=$ipaddr)}"
fi

dns_server=${dns_server:-${ipaddr}}
dhcp_server=${dhcp_server:-${ipaddr}}
metadata_server=${metadata_server:-${ipaddr}}
sta_server=${sta_server:-${ipaddr}}

proxy_port=8080
proxy_bind=127.0.0.1

account_id=a-shpoolxx
#account_id=a-00000000

auth_port=3000
auth_bind=127.0.0.1

webui_port=9000
webui_bind=0.0.0.0

api_port=9001
api_bind=127.0.0.1

metadata_port=9002
metadata_bind=${ipaddr}

ports="${auth_port} ${webui_port} ${api_port} ${metadata_port}"

# virtual machine
vmdir_path=${tmp_path}/instances

# VM image path (for demo)
vmimage_uuid=lucid0
vmimage_file=${vmimage_uuid}.qcow2
vmimage_s3="http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/${vmimage_file}.gz"
vmimage_arch=32

# mysql
dcmgr_dbname=wakame_dcmgr
dcmgr_dbuser=root
webui_dbname=wakame_dcmgr_gui
webui_dbpass=passwd

# Hypervisor 
hypervisor=${hypervisor:-kvm}

# openflow
with_openflow=no

# screen mode: screen, tmux, bg
screen_mode=${screen_mode:-'screen'}
# 
without_screen=${without_screen}

# how many agents?
hva_num=1
sta_num=1
