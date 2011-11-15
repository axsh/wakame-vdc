
require File.expand_path('../spec_helper', __FILE__)
include Config

if is_enabled? :instance_specs_api_spec
  cfg = get_config[:instance_specs_api_spec]

  describe "/api/instance_specs" do
    it_should_behave_like "show_api", "/instance_specs", cfg[:instance_spec_ids]
  end
end
