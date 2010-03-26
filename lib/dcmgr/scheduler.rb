
module Dcmgr
  module PhysicalHostScheduler
    class NoPhysicalHostError < StandardError; end

    autoload :Algorithm1, 'dcmgr/scheduler/algorithm1'
    autoload :Algorithm2, 'dcmgr/scheduler/algorithm2'
    autoload :FindFirst, 'dcmgr/scheduler/find_first'
  end
end
