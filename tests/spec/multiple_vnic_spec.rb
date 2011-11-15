require File.expand_path('../spec_helper', __FILE__)
include Config

if is_enabled? :multiple_vnic_spec
  cfg = get_config[:multiple_vnic_spec]

  describe "Multiple network interface support" do
    it_should_behave_like "instances with custom network scheduler",cfg[:images], cfg[:specs], cfg[:schedulers]
  end
end
