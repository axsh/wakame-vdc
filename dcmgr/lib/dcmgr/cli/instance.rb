# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Instance < Base
    namespace :instance
    M = Dcmgr::Models
    include Dcmgr::Constants::Instance

    no_tasks {
      def show_single_instance(inst)
        # Placeholder code
        show_instances_list([inst])
      end
      private :show_single_instance

      def show_instances_list(inst_dataset)
        puts ERB.new(<<__END, nil, '-').result(binding)
<%- inst_dataset.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.host_node.nil? ? "unassigned" : row.host_node.canonical_uuid %>\t<%= row.state %>
<%- } -%>
__END
      end
      private :show_single_instance
    }

    desc "force-state UUID STATE", "Force an instance's state to chance in the database without any other action taken by Wakame. Use only if you know what you're doing!"
    def force_state(uuid,state)
      raise "Invalid state: #{state} possible states are: [#{STATES.join(',')}]" unless STATES.member?(state)
      modify(M::Instance,uuid,{:state => state})
    end

    desc "show [UUID] [options]", "Show instance(s)"
    method_option :show_terminated, :type => :boolean, :default => false, :desc => "Will include terminated instances in the results"
    def show(uuid=nil)
      insts = options[:show_terminated] ? M::Instance.dataset : M::Instance.alives
      if uuid
        # We get these constants loaded so they're searchable
        # by the Taggable#find method.
        M::Instance
        M::HostNode

        resource = M::Taggable.find(uuid)
        case resource
        when M::Instance
          show_single_instance(resource)
        when M::HostNode
          show_instances_list(insts.filter(:host_node => resource))
        else
          UnknownUUIDError.raise(uuid)
        end
      else
        show_instances_list(insts)
      end

    end

    desc "force-delete UUID", "Delete all of an instance's resources in the database but don't terminate the actual VM. Use only if you know what you're doing!"
    def force_delete(uuid)
      del(M::Instance,uuid)
    end

  end
end
