### config.yml

copy `config.yml.sample` to `config.yml`in this directory, then edit it.

#### dc_network
* vnet

The name of dc_network on which the users are allowed to create the networks. This should be the same as the one specified in hva.conf. Otherwise a new dc_network will automatically be created with allow_new_networks options.

* management

The name of dc_network for management. This should be the same as the one specified in hva.conf
