# Change Log

All notable changes to Wakame-vdc will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [1.0] - 2015-07-31

`Changed` Adopted Semantic Versioning.

Before this version, Wakame-vdc was constantly releasing every time we merged code while some times assigning a version number based on the current date. Since version numbers based on date don't conform to semantic versioning, we have decided to drop that format.

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
