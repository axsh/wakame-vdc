#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

## variables

## functions

### shunit2 setup

function oneTimeSetUp() {
  create_load_balancer
}

function oneTimeTearDown() {
  destroy_load_balancer
}
