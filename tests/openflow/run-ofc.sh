#!/usr/bin/env bash
#

work_dir=${work_dir:?"work_dir needs to be set"}

$work_dir/trema/trema run -v $work_dir/dcmgr/bin/ofc
