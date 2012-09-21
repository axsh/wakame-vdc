# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class MacRange < Base
    namespace :macrange
    M = Dcmgr::Models

    no_tasks {
      DELIMITER = ':'

      def mac_to_int(mac)
        check_mac_format(mac)

        mac.split(DELIMITER).join.hex
      end

      def int_to_mac(int)
        mac = int.to_s(16)
        while mac.length < 6
          mac.insert(0,'0')
        end
        mac.insert(2, DELIMITER)
        mac.insert(4 + DELIMITER.length, DELIMITER)
      end

      def check_mac_format(mac)
        delimited = /^([0-9a-fA-F]{1,2}#{DELIMITER}){1,2}([0-9a-fA-F]{1,2})$/
        non_delimited = /^[0-9a-fA-F]{1,6}$/

        Error.raise "Invalid mac address syntax #{mac}",100 if  (mac =~ delimited).nil? && (mac =~ non_delimited).nil?
      end
    }

    desc "add VENDOR_ID BEGIN END [OPTIONS]", "Create a new mac address range"
    method_option :uuid, :type => :string, :desc => "UUID of the mac address range"
    method_option :description, :type => :string,  :desc => "Description for the mac address range"
    def add(vendor_id,r_begin,r_end)
      # Convert hex format to ints
      int_vendor_id = mac_to_int vendor_id
      int_begin = mac_to_int r_begin
      int_end = mac_to_int r_end

      unless M::MacRange.find(:vendor_id => int_vendor_id, :range_begin => int_begin, :range_end => int_end).nil?
        Error.raise "This MAC address range already exists.", 100
      end

      fields = options.dup
      fields.merge!({
        :vendor_id   => int_vendor_id,
        :range_begin => int_begin,
        :range_end   => int_end,
      })

      puts super(M::MacRange,fields)
    end

    desc "modify UUID [OPTIONS]", "Modify a mac address range"
    method_option :description, :type => :string,  :desc => "Description for the mac address range"
    def modify(uuid)
      super(M::MacRange,uuid,options)
    end

    desc "del UUID", "Delete an existing mac address range"
    def del(uuid)
      super(M::MacRange,uuid)
    end

    desc "show [UUID]", "Show existing mac address range(s)"
    def show(uuid=nil)
      if uuid
        r = M::MacRange[uuid] || UnknownUUIDError.raise(uuid)
        print ERB.new(<<__END, nil, '-').result(binding)
UUID: <%= r.canonical_uuid %>
<%- unless r.description.nil? -%>
Description:
  <%= r.description %>
<%- end -%>
Vendor ID: <%= int_to_mac(r.vendor_id) %>
Dynamic MAC Address Range:
  <%= int_to_mac(r.vendor_id) %><%= DELIMITER %><%= int_to_mac(r.range_begin) %> - <%= int_to_mac(r.vendor_id) %><%= DELIMITER %><%= int_to_mac(r.range_end) %>
__END
      else
      print ERB.new(<<__END, nil, '-').result(binding)
<%- M::MacRange.all.each { |r| -%>
  <%= r.canonical_uuid %> <%= int_to_mac(r.vendor_id) %><%= DELIMITER %><%= int_to_mac(r.range_begin) %> - <%= int_to_mac(r.vendor_id) %><%= DELIMITER %><%= int_to_mac(r.range_end) %>
<%- } -%>
__END
      end
    end
  end
end
