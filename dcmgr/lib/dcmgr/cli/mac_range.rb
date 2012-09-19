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

        #puts "delimited: #{not (mac =~ delimited).nil?}"
        #puts "non_delimited: #{not (mac =~ non_delimited).nil?}"

        Error.raise "Invalid mac address syntax #{mac}",100 if  (mac =~ delimited).nil? && (mac =~ non_delimited).nil?
      end
    }

    #~ desc "k","k"
    #~ def check(mac)
      #~ check_mac_format(mac)
    #~ end

    desc "add VENDOR_ID BEGIN END", "Create a new mac address range"
    method_option :description, :type => :string,  :desc => "Description for the mac address range"
    def add(vendor_id,r_begin,r_end)
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

      r = M::MacRange.create(fields)

      print ERB.new(<<__END, nil, '-').result(binding)
<%= int_to_mac(r.vendor_id) %><%= DELIMITER %><%= int_to_mac(r.range_begin) %> - <%= int_to_mac(r.vendor_id) %><%= DELIMITER %><%= int_to_mac(r.range_end) %> <%= r.description.nil? ? "" : ( r.description ) %>
__END
    end

    desc "modify VENDOR_ID BEGIN END [OPTIONS]", "Modify a mac address range"
    method_option :description, :type => :string,  :desc => "Description for the mac address range"
    def modify(vendor_id,r_begin,r_end)
      # Convert hex format to ints
      int_vendor_id = mac_to_int vendor_id
      int_begin = mac_to_int r_begin
      int_end = mac_to_int r_end

      range = M::MacRange.find(:vendor_id => int_vendor_id, :range_begin => int_begin, :range_end => int_end)

      range.description = options[:description]
      range.save
    end

    desc "del VENDOR_ID [BEGIN] [END]", "Delete an existing mac address range"
    def del(vendor_id, r_begin=nil, r_end=nil)
      # Convert vendor id hex format to int
      int_vendor_id = mac_to_int vendor_id

      if r_begin.nil? && r_end.nil?
        ranges = M::MacRange.filter(:vendor_id => int_vendor_id).all
        Error.raise("Vendor id '#{vendor_id}' does not exist",100) if ranges.empty?
      else
        Error.raise "Missing range begin",100 if r_begin.nil?
        Error.raise "Missing range end",100 if r_end.nil?

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
  <%= int_to_mac(r.vendor_id) %><%= DELIMITER %><%= int_to_mac(r.range_begin) %> - <%= int_to_mac(r.vendor_id) %><%= DELIMITER %><%= int_to_mac(r.range_end) %> <%= r.description.nil? ? "" : ( r.description ) %>
<%- } -%>
__END
    end
  end
end
