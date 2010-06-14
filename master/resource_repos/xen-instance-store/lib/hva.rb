module Hva
end


class Hva::XenMonitor < Isono::Monitors::Base
  def initialize
    super()
    self.vm_instance_id = nil
  end
  
  def check
    system("xm list #{self.vm_instance_id}")
  end
end
