# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/tag/tag_endpoint_factory'
include Dcmgr::Endpoints::V1203::Tag


Dcmgr::Endpoints::V1203::CoreAPI.namespace '/host_node_groups', &TagEndpointFactory.make_tag_endpoint(Dcmgr::Tags::HostNodeGroup)
