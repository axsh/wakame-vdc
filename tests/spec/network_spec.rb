
require File.expand_path('../spec_helper', __FILE__)
include Config

cfg = get_config[:network_api_spec]

if is_enabled? :network_api_spec
  describe "/api/networks" do
    it_should_behave_like "show_api", "/networks", cfg[:network_ids]
  end
end
