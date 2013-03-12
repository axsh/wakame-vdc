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
  setup_vif
}

### instance.destroy

function after_destroy_instance() {
  teardown_vif
}
