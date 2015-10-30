#!/bin/bash

set -e -o pipefail

ln -s /usr/lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyS0.service
egrep -w "^ttyS0" /etc/securetty || { echo ttyS0 >> /etc/securetty; }
