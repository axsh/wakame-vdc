#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

## required

## email
email=${email:-'{}'}
email_path=${email_path:-${BASH_SOURCE[0]%/*}/email.$$}

## message
message=${email:-'{}'}
message_path=${message_path:-${BASH_SOURCE[0]%/*}/message.$$}

## functions
function json_sh() {
  echo ${JSONSH}
}

function setup_email() {
  render_email_address > ${email_path}
  email=${email_path}
}

function delete_email() {
  rm -f ${email_path}
}

function setup_message() {
  render_message > ${message_path}
  message=${message_path}
}

function delete_message() {
  rm -f ${message_path}
}
