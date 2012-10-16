shared_examples_for "show_api" do |api_suffix,ids|
  it "should show all" do
    res = APITest.get("#{api_suffix}")
    res.success?.should be_true
  end

  ids.each { |id|
    it "should show #{id}" do
      res = APITest.get("#{api_suffix}/#{id}")
      res["id"].should == id
      res.success?.should be_true
    end
  } unless ids.nil?
end

shared_examples_for "instances with custom network scheduler" do |images,specs,schedulers|
  include InstanceHelper

  images.each { |image|
    specs.each { |spec|
      schedulers.each { |scheduler|
        it "run instance of (#{image}, #{spec}) with #{scheduler} network scheduler" do
          # Always bring new instance to running.
          res = APITest.create("/instances", {:image_id => image, :instance_spec_id => spec, :network_scheduler => scheduler})
          res.success?.should be_true
          @instance_id = res["id"]

          retry_until_running(@instance_id)

          APITest.delete("/instances/#{@instance_id}").success?.should be_true
          retry_until_terminated(@instance_id)
        end
      }
    }
  }
end

shared_examples_for "image_delete_and_register" do |image_ids, image_type|
  before(:all) do
    @source = {:local => :uri, :snapshot => :snapshot_id}
    @command = {
      :local    => "local",
      :snapshot => "volume"
    }
    init_env
    cd_dcmgr_dir
  end

  image_ids.each { |image_id|
    it "should delete machine image (#{image_id}) and then register with CLI." do
      res = APITest.get("/images/#{image_id}")

      # TODO: Image should be registerd via API.
      require 'yaml'
      vmimage = YAML.load(res["source"])[@source[image_type]]
      vmimage = URI.parse(vmimage).path if image_type == :local
      cmd = "./bin/vdc-manage image add #{@command[image_type]} #{vmimage} --md5sum #{res["md5sum"]} --account-id #{res["account_id"]} --uuid #{res["id"]} --arch #{res["arch"]} --description \"#{res["description"]}\""
      #p cmd

      res = APITest.delete("/images/#{image_id}")
      res.success?.should be_true

      output = `#{cmd}`
      output.chomp.should == image_id
      $?.exitstatus.should == 0
    end
  }
end
