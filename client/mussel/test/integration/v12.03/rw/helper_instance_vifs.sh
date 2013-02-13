#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

vifs_path=${BASH_SOURCE[0]%/*}/vifs.$$
vifs=${vifs_path}

### required

## functions

function render_vif_table() {
  cat <<-EOS
	{}
	EOS
}

function  before_create_instance() {
  render_vif_table > ${vifs_path}
}

function after_create_instance() {
  rm -f ${vifs_path}
}
