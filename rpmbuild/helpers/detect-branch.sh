#!/bin/bash
#
# requires:
#   bash
#   git, sed
#

set -e

LANG=C

git branch --no-color | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
