#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

## functions

### instance.create

function  before_create_instance() {
  needs_secg && { create_security_group; } || :
  render_vif_table > ${vifs_path}
  vifs=${vifs_path}
}

### instance.destroy

function after_destroy_instance() {
  rm -f ${vifs_path}
  needs_secg && { destroy_security_group; } || :
  rm -f ${rule_path}
}
