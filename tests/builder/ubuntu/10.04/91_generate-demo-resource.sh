#!/bin/sh

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
export PATH=/bin:/usr/bin:/sbin:/usr/sbin

unset GEM_HOME
unset GEM_PATH
unset RUBYOPT


switch=$(/sbin/ip route list | awk '/^default / { print $5 }')
ipaddr=$(/sbin/ip addr show ${switch} | grep -w inet | awk '{print $2}')
ipv4_gw=$(/sbin/ip route list | awk '/^default / { print $3 }')


prefix=${ipaddr##*/}
myaddr=${ipaddr%%/*}
hostaddr=${myaddr}
network=$(echo ${myaddr} | cut -d. -f1-3)

dns_server=${myaddr}
dhcp_server=${myaddr}
metadata_server=${myaddr}
metadata_port=9002

dhcp_start_ip=${network}.150
dhcp_range=10
local_store_path=/home/wakame/vdc/store
account_id=a-shpoolxx

vmimage_uuid=lucid0
vmimage_file=${vmimage_uuid}.qcow2
vmimage_s3=http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/${vmimage_file}.gz

#cat <<EOS | egrep -v ^# | mysql -uroot wakame_dcmgr
generate_sql() {
  cat <<EOS | egrep -v ^#
TRUNCATE TABLE host_pools;
TRUNCATE TABLE networks;
TRUNCATE TABLE images;
TRUNCATE TABLE instance_specs;
TRUNCATE TABLE instances;
TRUNCATE TABLE instance_nics;
TRUNCATE TABLE ip_leases;
TRUNCATE TABLE ssh_key_pairs;
TRUNCATE TABLE netfilter_groups;
TRUNCATE TABLE netfilter_rules;
TRUNCATE TABLE vlan_leases;
TRUNCATE TABLE tag_mappings;

INSERT INTO host_pools VALUES
 (1,'${account_id}','demohost',now(),now(),'hva.${hostaddr}','x86','kvm',100,400000);

# null is nat_netrowk_id column.
INSERT INTO networks VALUES
 (1, '${account_id}', 'demonet', '${ipv4_gw}', ${prefix}, 'vdc.local', '${dns_server}', '${dhcp_server}', '${metadata_server}', ${metadata_port}, 1, null, 'demo', now(), now());
INSERT INTO vlan_leases VALUES
 (1, '${account_id}', 'demovlan', 0, now(), now());

INSERT INTO tag_mappings VALUES
 (1, 1, 'hp-demohost'),
 (2, 2, 'nw-demonet'),
 (3, 3, 'sp-demostor');


INSERT INTO images VALUES
 (1,'${account_id}','${vmimage_uuid}',now(),now(),2,'--- \r\n:type: :http\r\n:uri: file://${local_store_path}/${vmimage_file}\r\n','x86', "Ubuntu 10.04 Server i386", 0,'init');

INSERT INTO instance_specs VALUES
 (1,'${account_id}','demospec','kvm','x86',1,256,1,'',now(),now());

INSERT INTO netfilter_groups VALUES
 (1,'${account_id}','demonfgr',now(),now(),'default','demo','tcp:22,22,ip4:0.0.0.0\ntcp:80,80,ip4:0.0.0.0\nudp:53,53,ip4:0.0.0.0\nicmp:-1,-1,ip4:0.0.0.0\n');
INSERT INTO netfilter_rules VALUES
 (1,now(),now(),1,'tcp:22,22,ip4:0.0.0.0'),
 (2,now(),now(),1,'tcp:80,80,ip4:0.0.0.0'),
 (3,now(),now(),1,'udp:53,53,ip4:0.0.0.0'),
 (4,now(),now(),1,'icmp:-1,-1,ip4:0.0.0.0');

INSERT INTO ssh_key_pairs VALUES
 (1,'${account_id}','demopair','demo', '91:a1:28:8e:08:43:0f:06:82:ec:aa:a7:cc:1f:8e:8c',
'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZhAOcHSe4aY8GwwLCJ4Et3qUBcyVPokFoCyCrtTZJVUU++B9554ahiVcrQCbfuDlaXV2ZCfIND+5N1UEk5umMoQG1aPBw9Nz9wspMpWiTKGOAm99yR9aZeNbUi8zAfyYnjrpuRUKCH1UPmh6EDaryFNDsxInmaZZ6701PgT++cZ3Vy/r1bmb93YvpV+hfaL/FmY3Cu8n+WJSoJQZ4eCMJ+4Pw/pkxjfuLUw3mFl40RVAlwlTuf1I4bB/m1mjlmirBEU6+CWLGYUNWDKaFBpJcGB6sXoQDS4FvlV92tUAEKIBWG5ma0EXBdJQBi1XxSCU2p7XMX8DhS7Gj/TSu7011 wakame-vdc.pem\n',
'-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA2YQDnB0nuGmPBsMCwieBLd6lAXMlT6JBaAsgq7U2SVVFPvgf\neeeGoYlXK0Am37g5Wl1dmQnyDQ/uTdVBJObpjKEBtWjwcPTc/cLKTKVokyhjgJvf\nckfWmXjW1IvMwH8mJ466bkVCgh9VD5oehA2q8hTQ7MSJ5mmWeu9NT4E/vnGd1cv6\n9W5m/d2L6VfoX2i/xZmNwrvJ/liUqCUGeHgjCfuD8P6ZMY37i1MN5hZeNEVQJcJU\n7n9SOGwf5tZo5ZoqwRFOvglixmFDVgymhQaSXBgerF6EA0uBb5VfdrVABCiAVhuZ\nmtBFwXSUAYtV8UglNqe1zF/A4Uuxo/00ru9NdQIDAQABAoIBAC/WHakerFadOGxH\nRPsIDxvUZDuOZD1ANNw53kSFBNxZ2XHAxcNcjLpH5xjG8gWvkUVzVRtMGaSPxVvu\ns3X3JpPb8PFBk+dzoopYZX83vWjnsAJfxWNvsx1reuuhlzUagXyfohaQOtE9LMrS\nnTVzgA3fUBdSHfXDcOm2aS08ApXSJOIxYxD/9AF6HNBsqTe+qvHiHVy570wkc2gf\nK8m90NITTefIv67YzyVNubqCa2k9AiDojRKv0MeBpMqzHA3Lyw8El6Z0RTH694aV\nAM1+y760DKw3SE320p9wz/onh6mei5jg4eoGDZHqGCY4rb3U9qLkMFHPmsOssWQq\n/O5056ECgYEA+y0DHYCq3bcJFxhHqogVYbSnnJTJriC4XObjMK5srz1Y9GL6mfhd\n3qJIbyjgRofqLEdOUXq2LR8BVcSnWxVwwzkThtYpRlbHPMv3MPr/PKgyNj3Gsvv5\n0Y2EzcLiD1cm1f5Z//EWu+mOAfzW8JOLL8w+ZedsdvCUmFrZp/eClR0CgYEA3bGA\nNwWOpERSylkA3cK5XGMFYwj6cE2+EMaFqzdEy4bLKhkdLMEA1NA7CbtO46e7AvCu\nsthj5Qty605uGEI6+S5M/IPlX/Gh66f3qnXXNsVKXJbOcUC9lEbRwZa0V1u1Eqrx\nmJ3g1as31EgmKRv4vIJ2wQTVgorBNDuUdZUzYjkCgYA3h78Nkbm05Nd8pKCLgiSA\nAmmgA4EHHzLDT0RhKd7ba0u0VAGlcrSGGQi8kqPq0/egrG8TMnb+SMGJzb1WNMpG\nTuMTR1u+skbAGTPgP02YgnL/bO71+SFFA+2dc/14eMMcQmxxWkK1brA3nkeCzovS\nGGyfKOfg79VaTZObP+w9vQKBgQC4dpBLt/kHX75Plh0taHAZml8KF5diyJ1Ekhr4\n6wT4IJF91uW6rmFFsnndUBiFPrRR7vg94eXE2HDnsBvVXY56dfcjCZBa89CaJ+ng\n0Sqg7SpBvk3KWGcmMIMqBH7MTYduIATky0EgKNZMcTgnbpnaKOgtFRufAlteXdDa\nwam+qQKBgHxGg9HJI3Ax8M5rgmsGReBM8e1GHojV5pmgWm0AsX04RS/7/gNkXHdv\nMoU4FfcO/Tf7b+qwp40OjN0dr7xDwIWXih2LrAxGK2Lw43hlC5huYmqpEIYoiag+\nPxIk/VB7tQxkp4Rtv005mWHPUYlh8x4lMqiVAhPJzEBfN9UEfkrk\n-----END RSA PRIVATE KEY-----\n',
now(),now()
);
EOS
}

generate_sql | cat -n
generate_sql | mysql -uroot wakame_dcmgr


[ -d /var/lib/vm/ ] || {
  mkdir /var/lib/vm/
  chown wakame:wakame /var/lib/vm/
  chmod 755 /var/lib/vm/
}


{
cat<<EOS
# wakame system configuration
[ -d /home/wakame/vdc ] || {
  mkdir /home/wakame/vdc
}

[ -d ${local_store_path} ] || {
  mkdir ${local_store_path}
}

[ -f ${local_store_path}/${vmimage_file} ] || {
  cd ${local_store_path}
  wget ${vmimage_s3}
  gunzip ${vmimage_file}.gz
}
EOS
} | su - wakame -c /bin/bash


exit 0
