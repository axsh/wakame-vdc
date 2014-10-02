#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

## functions

function render_tdagent_conf() {
  cat <<-EOS
	<source>
	  type tail
	  format /^(?<message>.*)$/
	  path /var/log/messages
	  pos_file /var/log/td-agent/position_files/messages.pos
	  tag var.log.messages
	</source>
	
	<match **>
	  type forward
	  flush_interval 60s
	  <server>
	    name logservice
	    host fluent.local
	    port 24224
	  </server>
	</match>
	EOS
}

### shunit2 setup

