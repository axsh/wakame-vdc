module Dcmgr
  module Helpers
    module StaTgtHelper
      def register_target(tid, iqn)
        sh("/usr/sbin/tgtadm --lld iscsi --op new --mode=target --tid=#{tid} --targetname #{iqn}")
        if $?.exitstatus != 0
          raise "failed create iscsi target: #{tid}"
        end 
      end 
   
      def register_logicalunit(tid, lun, backing_store)
        sh("/usr/sbin/tgtadm --lld iscsi --op new --mode=logicalunit --tid=#{tid} --lun=#{lun} -b #{backing_store}")
        if $?.exitstatus != 0
         raise "failed add new backing store : #{backing_store}"
        end 
      end 
   
      def bind_target(tid, initiator_address)
        sh("/usr/sbin/tgtadm --lld iscsi --op bind --mode=target --tid=#{tid} --initiator-address=#{initiator_address}")
        if $?.exitstatus != 0
         raise "failed bind iscsi target: #{tid}"
        end 
      end
    end
  end
end
