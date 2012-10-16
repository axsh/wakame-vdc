
require File.expand_path('../spec_helper', __FILE__)
include Config

if is_enabled? :images_api_spec
  cfg = get_config[:images_api_spec]

  describe "/api/images" do
    include CliHelper

    it_should_behave_like "show_api", "/images", cfg[:local_image_ids] + cfg[:snapshot_image_ids]
    it_should_behave_like "image_delete_and_register", cfg[:local_image_ids], :local
    it_should_behave_like "image_delete_and_register", cfg[:snapshot_image_ids], :snapshot
  end
end
