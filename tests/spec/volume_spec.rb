
require File.expand_path('../spec_helper', __FILE__)
include Config

if is_enabled? :volume_api_spec
  cfg = get_config[:volume_api_spec]

  describe "/api/volumes" do
    include RetryHelper

    it "should create #{cfg[:test_volume_size]}MB blank volume and delete" do
      res = APITest.create("/volumes", {:volume_size=>cfg[:test_volume_size]})
      res.success?.should be_true
      volume_id = res["id"]
      retry_until_available(volume_id)
      APITest.get("/volumes/#{volume_id}")["size"].to_i.should == cfg[:test_volume_size]
      APITest.delete("/volumes/#{volume_id}").success?.should be_true
      retry_until do
        APITest.get("/volumes/#{volume_id}")["state"] == "deleted"
      end
    end

    it "should create volume from snapshot #{cfg[:snapshot_id]} and delete" do
      snap = APITest.get("/volume_snapshots/#{cfg[:snapshot_id]}")
      snap.success?.should be_true
      res = APITest.create("/volumes", {:snapshot_id=>cfg[:snapshot_id]})
      res.success?.should be_true
      volume_id = res["id"]
      retry_until_available(volume_id)
      APITest.get("/volumes/#{volume_id}")["size"].to_i.should == snap["size"].to_i
      APITest.delete("/volumes/#{volume_id}").success?.should be_true
      retry_until do
        APITest.get("/volumes/#{volume_id}")["state"] == "deleted"
      end
    end

    # volume_min_size
    it "should create blank volume less than minimum size. (volume_min_size #{cfg[:minimum_volume_size]})" do
      res = APITest.create("/volumes", {:volume_size=>cfg[:minimum_volume_size] - 1})
      res.success?.should_not be_true
    end

    it "should create minimum size blank volume (volume_min_size #{cfg[:minimum_volume_size]})" do
      res = APITest.create("/volumes", {:volume_size=>cfg[:minimum_volume_size]})
      res.success?.should be_true
      volume_id = res["id"]
      retry_until_available(volume_id)
      APITest.get("/volumes/#{volume_id}")["size"].to_i.should == cfg[:minimum_volume_size]
      APITest.delete("/volumes/#{volume_id}").success?.should be_true
      retry_until do
        APITest.get("/volumes/#{volume_id}")["state"] == "deleted"
      end
    end

    # volume_max_size
    it "should create blank volume more than maximum size. (volume_max_size #{cfg[:maximum_volume_size]})" do
      res = APITest.create("/volumes", {:volume_size=>cfg[:maximum_volume_size]+1})
      res.success?.should_not be_true
    end

    it "should create maximum size blank volume (volume_max_size #{cfg[:maximum_volume_size]})" do
      res = APITest.create("/volumes", {:volume_size=>cfg[:maximum_volume_size]})
      res.success?.should be_true
      volume_id = res["id"]
      retry_until_available(volume_id)
      APITest.get("/volumes/#{volume_id}")["size"].to_i.should == cfg[:maximum_volume_size]
      APITest.delete("/volumes/#{volume_id}").success?.should be_true
      retry_until do
        APITest.get("/volumes/#{volume_id}")["state"] == "deleted"
      end
    end

    private
    def retry_until_available(volume_id)
      retry_until do
        case APITest.get("/volumes/#{volume_id}")["state"]
        when 'available'
          true
        when 'deleted'
          raise "Volumes was deleted by the system due to failure."
        else
          false
        end
      end
    end

  end
end
