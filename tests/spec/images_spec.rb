
require File.expand_path('../spec_helper', __FILE__)
include Config

if is_enabled? :images_spec
  cfg = get_config[:images_spec]

  images ||= cfg[:images]
  specs ||= cfg[:specs]
  ssh_key_id ||= cfg[:ssh_key_id]

  describe "Machine images and instance specs" do
    include InstanceHelper

    # Test all images with each spec
    images.each { |img|
      specs.each { |spec|
        it "should run an instance of (#{img[:id]}, #{spec}) -> reboot -> terminate" do
          run_instance_then_reboot_then_terminate({:image_id=>img[:id], :instance_spec_id=>spec, :ssh_key_id=>ssh_key_id},img[:user],img[:uses_metadata])
        end

        it "should run an instance of (#{img[:id]}, #{spec}) -> stop -> terminate" do
          instance_id = run_instance({:image_id=>img[:id], :instance_spec_id=>spec, :ssh_key_id=>ssh_key_id})

          #p "retry until running"
          retry_until_running(instance_id)

          #p "/instances/#{instance_id}/stop"
          #p APITest.update("/instances/#{instance_id}/stop", [])
          APITest.update("/instances/#{instance_id}/stop", []).success?.should be_true
          retry_until_stopped(instance_id)
          # check volume state
          instance = APITest.get("/instances/#{instance_id}")
          instance['volume'].each { |v|
            v['state'].should == 'attached'
          }
          instance['ips'].nil?.should be_true

          terminate_instance(instance_id)
        end

        it "should run an instance of (#{img[:id]}, #{spec}) -> stop -> running -> terminate" do
          instance_id = run_instance({:image_id=>img[:id], :instance_spec_id=>spec, :ssh_key_id=>ssh_key_id})
          retry_until_running(instance_id)
          instance = APITest.get("/instances/#{instance_id}")

          APITest.update("/instances/#{instance_id}/stop", []).success?.should be_true
          retry_until_stopped(instance_id)

          APITest.update("/instances/#{instance_id}/start", []).success?.should be_true
          retry_until_running(instance_id)

          # compare differences of parameters to the old one.
          new_instance = APITest.get("/instances/#{instance_id}")

          #p "instance"
          #p instance

          #p "new_instance"
          #p new_instance

          instance['vif'].first['vif_id'].should == new_instance['vif'].first['vif_id']
          instance['vif'].first['ipv4']['address'].should_not == new_instance['vif'].first['ipv4']['address']

          terminate_instance(instance_id)
        end

        it "should run an instance of (#{img[:id]}, #{spec}) -> stop -> running -> stop -> terminate" do
          instance_id = run_instance({:image_id=>img[:id], :instance_spec_id=>spec, :ssh_key_id=>ssh_key_id})
          retry_until_running(instance_id)

          APITest.update("/instances/#{instance_id}/stop", []).success?.should be_true
          retry_until_stopped(instance_id)

          APITest.update("/instances/#{instance_id}/start", []).success?.should be_true
          retry_until_running(instance_id)

          APITest.update("/instances/#{instance_id}/stop", []).success?.should be_true
          retry_until_stopped(instance_id)

          terminate_instance(instance_id)
        end
      }
    }

    private
    # Runs an instance and returns its id
    def run_instance(params)
      res = APITest.create("/instances", params)
      res.success?.should be_true
      res["id"]
    end

    def terminate_instance(id)
      APITest.delete("/instances/#{id}").success?.should be_true
      retry_until_terminated(id)
      # check volume state
      instance = APITest.get("/instances/#{id}")
      instance['volume'].each { |v|
        v['state'].should == 'available'
      }
    end

    def run_instance_then_reboot_then_terminate(params,username,uses_metadata = true)
      res = APITest.create("/instances", params)
      res.success?.should be_true
      instance_id = res["id"]

      #p "retry until running"
      retry_until_running(instance_id)
      #p "retry until network started"
      retry_until_network_started(instance_id)
      #p "retry until ssh started"
      retry_until_ssh_started(instance_id)

      if uses_metadata
        #p "retry until logged in"
        retry_until_loggedin(instance_id, username)
      end

      APITest.update("/instances/#{instance_id}/reboot", []).success?.should be_true
      #p "retry until network stopped"
      retry_until_network_stopped(instance_id)

      APITest.delete("/instances/#{instance_id}").success?.should be_true
      #p "retry until terminated"
      retry_until_terminated(instance_id)
    end

  end
end
