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
  
  #unless cfg[:snapshot_image_id].nil?
    #it "should delete machine image (wmi-lucid1) and then register with CLI." do
      #image_id = cfg[:snapshot_image_id]
      #res = APITest.get("/images/#{image_id}")

      ## TODO: Image should be registerd via API.
      #require 'yaml'
      #snap_id = YAML.load(res["source"])[:snapshot_id]
      #cmd = "./bin/vdc-manage image add volume #{snap_id} -m #{res["md5sum"]} -a #{res["account_id"]} -u #{res["id"]} -r #{res["arch"]} -d \"#{res["description"]}\" -s init"

      #res = APITest.delete("/images/#{image_id}")
      #res.success?.should be_true

      #`#{cmd}`
      #$?.exitstatus.should == 0
    #end
  #end
end
