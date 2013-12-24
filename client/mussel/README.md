# mussel

Wakame-VDC DCMGR API Client with bash

## Usage

```
$ ./mussel.sh [filename] [function]
```

the first parameter is matched with filenames under ./v12.03.d/ directory without extension ".sh".
the second parameter is a function name without the prefix "task_" of inside of the file at the first parameter.

Example:
```
$ ./mussel.sh instance create {other params}
```

$

## Configure musselrc file

mussel will load `~/.musselrc` before api call if exists.

example:
```
DCMGR_HOST=10.0.2.15
DCMGR_PORT=9001

account_id=a-shpoolxx
hypervisor=openvz
```

## smoke test

run test suite.

```
$ cd test

$ make integration
$ make acceptance
```

run a specific scenario.

```
$ cd [suite]/path/to/[category]/
$ ./t.[scenario].sh
```
