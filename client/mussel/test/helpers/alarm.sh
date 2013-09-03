#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

declare alarm_uuid

### required

resource_id=${resource_id:-i-demo0001}
metric_name=${metric_name:-log}
enabled=${enabled:-true}

### params
params=${params:-}

### optional
evaluation_periods=${evaluation_periods:-60}
notification_periods=${notification_periods:-180}
ok_actions=${ok_actions:-}
alarm_actions=${alarm_actions:-}
insufficient_data_actions=${insufficient_data_actions:-}


