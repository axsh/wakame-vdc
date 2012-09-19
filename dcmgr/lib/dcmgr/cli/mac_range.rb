# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class MacRange < Base
    namespace :macrange
    M = Dcmgr::Models

    no_tasks {
      def mac_to_int(mac)
        mac.split('::').join.hex
      end
      
      def int_to_mac(int)
        mac = int.to_s(16)
        while mac.length < 6
          mac.insert(0,'0')
        end
        mac.insert(2,'::')
        mac.insert(6,'::')
      end
    }

    desc "add VENDOR_ID BEGIN END", "Create a new mac address range"
    method_option :description, :type => :string,  :desc => "Description for the mac address range"
    def add(vendor_id,r_begin,r_end)
      #TODO: Check hex format of all variables

      # Convert hex format to ints
      int_vendor_id = mac_to_int vendor_id
      int_begin = mac_to_int r_begin
      int_end = mac_to_int r_end

      fields = {
        :vendor_id   => int_vendor_id,
        :range_begin => int_begin,
        :range_end   => int_end,
        :description => options[:description]
      }

      M::MacRange.create(fields)
    end

    desc "del VENDOR_ID [BEGIN] [END]", "Delete an existing mac address range"
    def del(vendor_id, r_begin=nil, r_end=nil)
      #TODO: Check hex format for vendor id
      # Convert vendor id hex format to int
      int_vendor_id = mac_to_int vendor_id
      if r_begin.nil? && r_end.nil?
        ranges = M::MacRange.filter(:vendor_id => int_vendor_id).all
        Error.raise("Vendor id '#{vendor_id}' does not exist",100) if ranges.empty?
      else
        #TODO: raise error if either r_begin or r_end is nil
        #TODO: Check hex format for ranges

        # Convert ranges hex format to int
        int_begin = mac_to_int r_begin
        int_end = mac_to_int r_end

        ranges = M::MacRange.filter(:vendor_id => int_vendor_id, :range_begin => int_begin, :range_end => int_end).all
        Error.raise("A mac address range from #{r_begin} to #{r_end} for vendor id '#{vendor_id}' does not exist",100) if ranges.empty?
      end

      ranges.each { |range|
        range.destroy()
      }
    end

    desc "show [VENDOR_ID]", "Show existing mac address range(s)"
    def show(vendor_id=nil)
      if vendor_id
        #TODO: Check hex format for vendor id
        
        # Convert vendor id hex format to int
        int_vendor_id = mac_to_int(vendor_id)
        
        # Show only the ranges for this vendor id
        ranges = M::MacRange.filter(:vendor_id => int_vendor_id).all
        Error.raise("Vendor id '#{vendor_id}' does not exist",100) if ranges.empty?
      else
        # Show all ranges for all vendor ids
        ranges = M::MacRange.order(:vendor_id).all
      end
      
      print ERB.new(<<__END, nil, '-').result(binding)
Dynamic MAC Address Range:
<%- ranges.each { |r| -%>
  <%= int_to_mac(r.vendor_id) %>::<%= int_to_mac(r.range_begin) %> - <%= int_to_mac(r.vendor_id) %>::<%= int_to_mac(r.range_end) %>
<%- } -%>
__END
    end
  end
end
