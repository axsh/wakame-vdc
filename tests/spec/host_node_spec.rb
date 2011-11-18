
require File.expand_path('../spec_helper', __FILE__)
include Config

if is_enabled? :host_nodes_api_spec
  cfg = get_config[:host_nodes_api_spec]

  describe "/api/host_nodes" do
    it_should_behave_like "show_api", "/host_nodes", cfg[:host_node_ids]
  end
end
