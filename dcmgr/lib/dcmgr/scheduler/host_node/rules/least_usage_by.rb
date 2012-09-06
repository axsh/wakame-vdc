# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::HostNode::Rules

  class LeastUsageBy < Rule
    configuration do
      param :key, :default=>:cpu_cores

      def validate(errors)
        unless [:cpu_cores, :memory_size, :quota_weight].member?(@config[:key].to_sym)
          errors << "Unknown key value for LeasetUsageBy: #{@config[:key]}"
        end
      end
    end

    def filter(dataset,instance)
      dataset
    end
    
    def reorder(array,instance)
      array.sort_by { |hn|
        hn.instances_dataset.alives.sum(options.key).to_f
      }
    end

  end
end
