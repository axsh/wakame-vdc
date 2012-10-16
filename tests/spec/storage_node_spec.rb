
require File.expand_path('../spec_helper', __FILE__)
include Config

if is_enabled?(:storage_nodes_api_spec)
  cfg = get_config[:storage_nodes_api_spec]

  describe "/api/storage_nodes" do
    it_should_behave_like "show_api", "/storage_nodes", cfg[:storage_ids]
  end
end
