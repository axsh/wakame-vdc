# Development guide

If you want try hacking away at the Wakame-vdc source code, this guide should be able to help you out a bit. The source can be found on [github](https://github.com/axsh/wakame-vdc).

You can just clone it as you would any [git](http://git-scm.com) respository.

    git clone https://github.com/axsh/wakame-vdc

## Code map

Now that you know where the code is, let's see what we can tell you about how it's structured.

The main backend source code is in the [dcmgr](https://github.com/axsh/wakame-vdc/tree/master/dcmgr) directory.

The file [dcmgr/lib/dcmgr.rb](https://github.com/axsh/wakame-vdc/blob/master/dcmgr/lib/dcmgr.rb) provides a nice overview of the code. It shows the module and class structure.

### WebAPI

The WebAPI code uses [Sinatra](http://www.sinatrarb.com) and is in the [dcmgr/lib/dcmgr/endpoints/12.03](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/lib/dcmgr/endpoints/12.03) directory.

#### Hypervisor drivers

The code that actually starts instances is in the [dcmgr/lib/dcmgr/drivers/hypervisor](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/lib/dcmgr/drivers/hypervisor) directory.

### Scheduling

All decisions that need to be made in order to start instances (assignment of [host node](jargon-dictionary.md#hva), IP address, MAC address, etc.) are referred to as scheduling and are located in the [dcmgr/lib/dcmgr/scheduler](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/lib/dcmgr/scheduler) directory. The code that actually executes these schedulers can be found here: [dcmgr/lib/dcmgr/node_modules/scheduler.rb](https://github.com/axsh/wakame-vdc/blob/master/dcmgr/lib/dcmgr/node_modules/scheduler.rb)

### Security Groups

The firewall ([Security Groups](security-groups/index.md)) related code is located in the [dcmgr/lib/dcmgr/edge_networking](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/lib/dcmgr/edge_networking) directory. This code is executed from the following file: [dcmgr/lib/dcmgr/node_modules/service_netfilter.rb](https://github.com/axsh/wakame-vdc/blob/master/dcmgr/lib/dcmgr/node_modules/service_netfilter.rb).

The [dcmgr/lib/dcmgr/edge_networking/openflow](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/lib/dcmgr/edge_networking/openflow) directory is actually a leftover from an obsolete feature concerning virtual networks. That feature got split off and turned into [OpenVNet](https://github.com/axsh/openvnet). The directory is still there because [the NATbox](jargon-dictionary#natbox) uses [OpenFlow](http://archive.openflow.org) to provide network address translation.

### AMQP messaging

Wakame-vdc uses an in-house developed framework that handles all the [AMQP](http://www.amqp.org) messaging. It's called Isono and can be found in its own [github repository](https://github.com/axsh/isono).

The classes that implement Isono can be found in the [dcmgr/lib/dcmgr/node_modules](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/lib/dcmgr/node_modules) and [dcmgr/lib/dcmgr/rpc](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/lib/dcmgr/rpc) directories.

### Database access

We use [Sequel](http://sequel.jeremyevans.net) to handle database access. The model classes are in the [dcmgr/lib/dcmgr/models](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/lib/dcmgr/models) directory.

The database schema is managed using [Sequel Migrations](http://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html). The migration files are in [config/db/migrations](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/config/db/migrations).

### GUI

The GUI is a [Rails](http://rubyonrails.org) application and is located in the [frontend/dcmgr_gui](https://github.com/axsh/wakame-vdc/tree/master/frontend/dcmgr_gui) directory. There's also a not quite as pretty admin GUI available if you want to play around with it. [frontend/admin](https://github.com/axsh/wakame-vdc/tree/master/frontend/admin)

### CLI (vdc-manage and gui-manage)

Both CLI's used by Wakame-vdc are implemented using [Thor](http://whatisthor.com).

The *vdc-manage* CLI is located in the [dcmgr/lib/dcmgr/cli](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/lib/dcmgr/cli) directory and is executed from [dcmgr/bin/vdc-manage](https://github.com/axsh/wakame-vdc/blob/master/dcmgr/bin/vdc-manage).

The *gui-manage* CLI can be found in [frontend/dcmgr_gui/lib/cli](https://github.com/axsh/wakame-vdc/tree/master/frontend/dcmgr_gui/lib/cli) and is executed from [frontend/dcmgr_gui/bin/gui-manage](https://github.com/axsh/wakame-vdc/blob/master/frontend/dcmgr_gui/bin/gui-manage).

### Configuration files

The configuration files use an in-house developed framework called [Fuguta](https://github.com/axsh/fuguta). Their definitions can be found in the [dcmgr/lib/dcmgr/configurations](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/lib/dcmgr/configurations) directory. Examples of the configuration files themselves can be found here: [dcmgr/config](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/config)

### RPM packaging

The RPM packaging scripts are in the aptly named [rpmbuild](https://github.com/axsh/wakame-vdc/tree/master/rpmbuild) directory.

### Debian packaging

You might notice a [debian](https://github.com/axsh/wakame-vdc/tree/master/debian) directory in the main repository. Even though the directory is there, Debian packaging is currently **not** officially supported. Feel free to play around with the packaging info in this directory but don't expect it to work.

### Mussel

Mussel is an API client and autotesting framework for Wakame-vdc written in bash. It can be found here: [client/mussel](https://github.com/axsh/wakame-vdc/tree/master/client/mussel)

### Autotesting

There are currently three autotest suites for Wakame-vdc.

Unit tests using [RSpec](http://rspec.info) are here: [dcmgr/spec](https://github.com/axsh/wakame-vdc/tree/master/dcmgr/spec)

Integration tests using the Mussel framework are here: [client/mussel/test](https://github.com/axsh/wakame-vdc/tree/master/client/mussel/test)

Integration tests using [RSpec](http://rspec.info) are here: [spec_integration](https://github.com/axsh/wakame-vdc/tree/master/spec_integration)

### Instance init scripts

The instances need to be made aware of meta-data that Wakame-vdc sets for them like IP address, hostname, etc. Scripts to do this are located here: [wakame-init](https://github.com/axsh/wakame-vdc/tree/master/wakame-init)

### Upstart jobs

The upstart jobs that are used to start Wakame-vdc services are located here: [contrib/etc](https://github.com/axsh/wakame-vdc/tree/master/contrib/etc)

## Contributing code

We encourage you to send some of your code back to us. You can do so by using github's *fork & pull* method as described [here](https://help.github.com/articles/using-pull-requests/#fork--pull). You will need to have a github account.

Once you've made a pull request to us, we will run our automated test suite on it and review the code. We might ask you to make certain modifications before (and if) we finally merge your code into the main repository.

