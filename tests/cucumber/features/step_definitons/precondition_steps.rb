begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

api_type_match = '(volume|instance_spec)'

Given /^the #{api_type_match} (.+) exists$/ do |api_type,arg_1|
  uuid = variable_get_value(arg_1)

  case api_type
  when 'volume'
    unless APITest.get("/images/#{uuid}").success?
      #Set variabled for the setup script
      ENV["vdc_root"]=VDC_ROOT
      ENV["vmimage_snap_uuid"]=uuid.split("-").last
      ENV["account_id"]="a-shpoolxx"
      ENV["local_store_path"]="#{VDC_ROOT}/tmp/snap/#{ENV["account_id"]}"
      ENV["vmimage_file"]="snap-#{uuid.split("-").last}.snap"
      ENV["dcmgr_dbname"]="wakame_dcmgr"
      ENV["dcmgr_dbuser"]="root"
      ENV["image_arch"]="x86"

      case uuid
      when 'wmi-secgtest'
        ENV["vmimage_s3"] = "http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/ubuntu-10.04_secgtest_kvm_i386.raw.gz"
      else
        ENV["vmimage_s3"] = "http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/ubuntu-lucid-kvm-ms-32.raw.gz"
      end

      steps %Q{
        Given the working directory is tests/cucumber/features/1shot/setup_script
        When the following command is run: ./1shot_setup.sh
        Then the command should be successful
      }
    end

  when 'instance_spec'
    raise "Cannot use instance_spec api after 11.12." if api_ver_cmp(TARGET_API_VER, '11.12') > 0

    unless APITest.get("/instance_specs/#{uuid}").success?
      steps %Q{
        Given the working directory is dcmgr/bin
        When the following command is run: ./vdc-manage spec add --uuid #{uuid} --account-id a-shpoolxx --hypervisor kvm --arch x86_64 --cpu-cores 1 --memory-size 256 --quota-weight 1.0
        Then the command should be successful
      }
    end
  else
    raise "No such api type: #{api_type}."
  end

end

Given /^the #{api_type_match} (.+) exists for api until ([0-9][0-9].[0-9][0-9])$/ do |api_type,arg_1,precondition|
  next if api_ver_cmp(TARGET_API_VER, precondition) > 0

  steps %Q{
    Given the #{api_type} #{arg_1} exists
  }
end
