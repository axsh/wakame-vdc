# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::HostNode::Rules

  # Scatter the host node assignment based on the count grouped by the
  # given key.
  class ScatterBy < Rule
    configuration do
      param :column, :default=>:account_id

      def validate(errors)
        unless [:account_id].member?(@config[:column].to_sym)
          errors << "Unknown column value for ScatterBy: #{@config[:column]}"
        end
      end
    end

    def filter(dataset,instance)
      dataset
    end

    def reorder(array,instance)
      array.sort_by { |hn|
        hn.instances_dataset.alives.filter(options.column.to_sym => instance[options.column.to_sym]).count
      }
    end

  end

end
