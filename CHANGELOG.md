# Change Log

All notable changes to Wakame-vdc will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

`Added` Security groups support to the OpenVNet integration.

`Fixed` A crash that occurred when performing a POST request to the ssh_key_pairs endpoint without including the "public_key" field in the parameters.

`Fixed` A bug in the `lxc-start` command generation, causing LXC instances to crash on startup.

`Fixed` A bug that would some times occur when starting LXC instances, causing `/dev/pty` to become mounted read only.

## [16.1] - 2015-10-2

`Added` More bash completion for mussel commands. Specifically alarm, *ip_pool*, *ip_handle*, *dc_network*, *host_node*, *volume*, *network_vif* and *instance_show_password*.

`Added` A new WebAPI endpoint to delete an instance's Windows password. 'DELETE instances/i-xxxxx/password'.

`Added` A Mussel command to decrypt the password of Windows instances.

`Changed` Improved the Windows machine image build scripts to make it easier to go straight from "git clone" to a building a fresh Windows machine image.

`Changed` Improved the way integration with OpenVNet is handled. Wakame-vdc will no longer take part in OpenVNet's 0mq traffic and instead make requests to OpenVNet's Web API like any other client would.

`Removed` A configuration option to automatically delete an instance's Windows password the first time it's queried from the API. Passwords can now be manually deleted instead.

`Fixed` A bug in wakame-init for Ubuntu where the instance's IP address didn't get set if the network got started before metadata drive was mounted.

`Fixed` A critical bug in the *PipedRules* host node scheduler that caused it to crash when used.

`Fixed` A race condition that could make collector crash and restart when restarting td-agent.

`Fixed` A minor race condition that could some times cause an unexpected (but still valid) IP address to be assigned when scheduling new instances.

## [16.0] - 2015-07-31

`Changed` Adopted Semantic Versioning.

Before this version, Wakame-vdc was constantly releasing every time we merged code while sometimes assigning a version number based on the current date. Since version numbers based on date don't conform to semantic versioning, we have decided to drop that format.

From now on we will release stable versions every few months while keeping track of the changes in this file.

`Added` Support for Windows instances.

`Added` An RPM package to install mussel.

`Added` Bash completion for the mussel commands.

`Added` A .deb package to install the wakame-init script on machine images running Ubuntu.

`Changed` Deleting a load balancer now only outputs its UUID instead of a full hash.

`Fixed` Several small bugfixes in vdc-manage.

`Fixed` A couple of missing localization lines in the GUI.

`Fixed` An issue where HVA would crash if dc_network wasn't set in the database.

`Fixed` An issue where it was impossible to filter WebAPI output for halted instances or load balancers.

`Fixed` An issue where load balancers would some times fail because they were trying to start before the network is up.

`Fixed` A crash that would occur in the GUI when logging in with a user that's not associated to any accounts.

`Fixed` An issue where the backup cleaner script wouldn't be able to connect to the MySQL database.

## [15.03] - 2015-03-18

## [13.08] - 2013-08-29

## [13.06] - 2013-06-13

## [11.12] - 2011-12-22

## [11.06] - 2011-06-30

## [10.12] - 2010-12-24

## [10.11] - 2010-11-19
