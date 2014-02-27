#!/bin/bash

set -e

screen_it dolphin   "cd ./dolphin/bin; ./dolphin_server 2>&1 | tee ${tmp_path}/vdc-dolphin.log"

exit 0
