# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class SecurityGroup < Base
    namespace :securitygroup
    M = Dcmgr::Models

    no_tasks {
      def read_rule_text
        if options[:rule].nil?
          # Set blank string as rule.
          return ''
        elsif options[:rule] == '-'
          # Read from STDIN
          STDIN.read
        else
          # Read from file.
          raise "Unknown rule file: #{options[:rule]}" if !File.exists?(options[:rule])
          File.read(options[:rule])
        end
      end
    }

    desc "add [options]", "Add a new security group"
    method_option :uuid, :type => :string, :desc => "The UUID for the new security group."
    method_option :account_id, :type => :string, :desc => "The UUID of the account this security group belongs to.", :required => true
    method_option :description, :type => :string, :desc => "The description for this new security group."
    method_option :rule, :type => :string, :desc => "Path to the rule text file. (\"-\" is from STDIN)"
    method_option :service_type, :type => :string, :default=>Dcmgr.conf.default_service_type, :desc => "Service type of the sercurity group. (#{Dcmgr.conf.service_types.keys.sort.join(', ')})"
    method_option :display_name, :type => :string, :required => true, :desc => "Display name of the security group"
    def add
      fields = options.dup
      fields[:rule] = read_rule_text

      puts super(M::SecurityGroup,fields)
    end

    desc "del UUID", "Delete a security group"
    def del(uuid)
      super(M::SecurityGroup,uuid)
    end

    desc "show [UUID]", "Show security group(s)"
    def show(uuid=nil)
      if uuid
        sg = M::SecurityGroup[uuid] || UnknownUUIDError.raise(uuid)
        puts ERB.new(<<__END, nil, '-').result(binding)
UUID: <%= sg.canonical_uuid %>
Name: <%= sg.display_name %>
Account ID: <%= sg.account_id %>
Service Type: <%= sg.service_type %>
Create: <%= sg.created_at %>
Update: <%= sg.updated_at %>
Rules:
<%= sg.rule %>
<%- if sg.description -%>
Description:
  <%= sg.description %>
<%- end -%>
__END
      else
        ds = M::SecurityGroup.dataset
        table = [['UUID', 'Account ID', 'Service Type', 'Name']]
        ds.each { |r|
          table << [r.canonical_uuid, r.account_id, r.service_type, r.display_name]
        }
        shell.print_table(table)
      end
    end

    desc "modify UUID [options]", "Modify an existing security group"
    method_option :account_id, :type => :string, :desc => "The UUID of the account this security group belongs to."
    method_option :description, :type => :string, :desc => "The description for this new security group."
    method_option :rule, :type => :string, :desc => "Path to the rule text file. (\"-\" is from STDIN)"
    method_option :service_type, :type => :string, :desc => "Service type of the security group. (#{Dcmgr.conf.service_types.keys.sort.join(', ')})"
    method_option :display_name, :type => :string, :desc => "Display name of the security group"
    def modify(uuid)
      fields = options.dup
      if options[:rule]
        fields[:rule] = read_rule_text
      end

      super(M::SecurityGroup,uuid, fields)
    end

    desc "apply UUID [options]", "Apply a security group to an instance"
    method_option :instance, :type => :string, :required => :true, :desc => "The instance to apply the group to"
    def apply(uuid)
      group = M::SecurityGroup[uuid] || UnknownUUIDError.raise(uuid)
      instance = M::Instance[options[:instance]] || UnknownUUIDError.raise(options[:instance])
      Error.raise("Group #{uuid} is already applied to instance #{options[:instance]}.",100) if group.instances.member?(instance)
      group.add_instance(instance)
    end

    desc "remove UUID [options]", "Remove a security group from an instance"
    method_option :instance, :type => :string, :required => :true, :desc => "The instance to remove the group from"
    def remove(uuid)
      group = M::SecurityGroup[uuid] || UnknownUUIDError.raise(uuid)
      instance = M::Instance[options[:instance]] || UnknownUUIDError.raise(options[:instance])
      Error.raise("Group #{uuid} is not applied to instance #{options[:instance]}.",100) unless group.instances.member?(instance)
      group.remove_instance(instance)
    end

  end
end
