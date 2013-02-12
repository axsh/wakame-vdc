### Fluentd configuration for wakame-vdc

```
<source>
  type tail
  format /^(?<message>.+)$/
  path /home/wakame/work/wakame-vdc/tmp/vdc-collector.log
  pos_file /home/wakame/work/wakame-vdc/tmp/vdc-collector.log.pos
  tag wakame-vdc.collector
</source>

<source>
  type tail
  format /^(?<message>.+)$/
  path /home/wakame/work/wakame-vdc/tmp/vdc-nsa.log
  pos_file /home/wakame/work/wakame-vdc/tmp/vdc-nsa.log.pos
  tag wakame-vdc.nsa
</source>

<source>
  type tail
  format /^(?<message>.+)$/
  path /home/wakame/work/wakame-vdc/tmp/vdc-hva.log
  pos_file /home/wakame/work/wakame-vdc/tmp/vdc-hva.log.pos
  tag wakame-vdc.hva
</source>

<source>
  type tail
  format /^(?<message>.+)$/
  path /home/wakame/work/wakame-vdc/tmp/vdc-dcmgr.log
  pos_file /home/wakame/work/wakame-vdc/tmp/vdc-dcmgr.log.pos
  tag wakame-vdc.dcmgr
</source>

<source>
  type tail
  format /^(?<message>.+)$/
  path /home/wakame/work/wakame-vdc/tmp/vdc-metadata.log
  pos_file /home/wakame/work/wakame-vdc/tmp/vdc-metadata.log.pos
  tag wakame-vdc.metadata
</source>

<source>
  type tail
  format /^(?<message>.+)$/
  path /home/wakame/work/wakame-vdc/tmp/vdc-auth.log
  pos_file /home/wakame/work/wakame-vdc/tmp/vdc-auth.log.pos
  tag wakame-vdc.auth
</source>

<source>
  type tail
  format /^(?<message>.+)$/
  path /home/wakame/work/wakame-vdc/tmp/vdc-proxy.log
  pos_file /home/wakame/work/wakame-vdc/tmp/vdc-proxy.log.pos
  tag wakame-vdc.proxy
</source>

<source>
  type tail
  format /^(?<message>.+)$/
  path /home/wakame/work/wakame-vdc/tmp/vdc-webui.log
  pos_file /home/wakame/work/wakame-vdc/tmp/vdc-webui.log.pos
  tag wakame-vdc.webui
</source>

<source>
  type tail
  format /^(?<message>.+)$/
  path /home/wakame/work/wakame-vdc/tmp/vdc-sta.log
  pos_file /home/wakame/work/wakame-vdc/tmp/vdc-sta.log.pos
  tag wakame-vdc.sta
</source>
```


### Fluentd configuration on Guest Instance. 
This plugin accept in_forward plugin.

```
<source>
  type wakame_vdc_guest_relay
  host 127.0.0.1
  port 8888
  instances_path /home/wakame/work/wakame-vdc/tmp/instances/
  flush_interval 5s
</source>
```

### Fluentd configuration on Cassandra Host. 
This plugin accept in_wakame_vdc_guest_relay plugin

```
<store>
   type wakame_vdc_logstore
   keyspace wakame_vdc_log_store
   columnfamily events
   host 127.0.0.1
   port 9160
   flush_interval 5s
</store>
```
