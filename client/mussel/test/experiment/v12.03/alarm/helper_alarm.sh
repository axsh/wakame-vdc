#!/bin/bash
#
# requires:
#   bash
#

## include files

## variables

## variables
resource_id=${resource_id:-}
resource_ids=${resource_ids:-}
metric_name=${metric_name:-log}
notification_periods=${notification_periods:-180}

alarm_actions=${alarm_actions:-"notification_type=dolphin notification_id=1 notification_message_type=log"}

