# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  class NetworkRoute < BaseNew
    
    many_to_one :outer_network, :key => :outer_network_id, :class => Network
    many_to_one :inner_network, :key => :inner_network_id, :class => Network

    many_to_one :outer_vif, :key => :outer_vif_id, :class => NetworkVif
    many_to_one :inner_vif, :key => :inner_vif_id, :class => NetworkVif

    subset(:alives, {:deleted_at => nil})

    dataset_module {
      def join_with_routes
        self.join_table(:left, :network_vifs,
                        {:network_vifs__id => :network_routes__inner_vif_id} |
                        {:network_vifs__id => :network_routes__outer_vif_id}).alives
      end

      def routes_between_vifs(outer_vif, inner_vif)
        self.where({:network_routes__outer_vif_id => outer_vif.id} &
                   {:network_routes__inner_vif_id => inner_vif.id}).select_all(:network_routes).alives
      end
    }

    def outer_ipv4
      return IPAddress::IPv4::parse_u32(self[:outer_ipv4]) if self[:outer_ipv4]
      return nil
    end

    def inner_ipv4
      return IPAddress::IPv4::parse_u32(self[:inner_ipv4]) if self[:inner_ipv4]
      return nil
    end

    def outer_ipv4_s
      outer_ipv4.to_s
    end

    def inner_ipv4_s
      inner_ipv4.to_s
    end

    def outer_ipv4_i
      self[:outer_ipv4]
    end

    def inner_ipv4_i
      self[:inner_ipv4]
    end

    #
    # Sequel methods:
    #

    def validate
      [:inner, :outer].each { |arg|
        # We don't validate anything beyond the above when the network
        # route is being deleted.
        next if self.deleted_at

        current_vif = self.send((current_vif_sym = "#{arg}_vif".to_sym))
        current_network = self.send((current_network_sym = "#{arg}_network".to_sym))
        current_ipv4 = self.send((current_ipv4_sym = "#{arg}_ipv4".to_sym))

        errors.add(current_network_sym, "No #{arg} network defined.") if current_network.nil?
        errors.add(current_vif_sym, "Cannot use deleted #{arg} network vif.") if current_vif && current_vif.deleted_at

        if current_ipv4
          if current_network && !current_network.include?(current_ipv4)
            errors.add(current_ipv4_sym, "#{arg} IP address out of range: #{current_ipv4}")
          end

          # Validate vif ip and ipv4 set when not leasing.
        else
          # Validate only allows ipv4 to be nil during pre-create.
          if @create_options.nil? ||
              (@create_options[arg][:find_ipv4].nil? &&
               @create_options[arg][:ip_handle].nil? &&
               @create_options[arg][:lease_ipv4].nil?)
            errors.add(current_ipv4_sym, "No #{arg} IPv4 specified.")
          end

          # Validate ip address.
        end
      }

      super
    end

    def around_create
      Sequel.transaction([NetworkRoute.db, NetworkVifIpLease.db, IpLease.db]) {
        if @create_options.nil?
          super
          next
        end

        [:inner, :outer].each { |arg|
          options = @create_options[arg]

          current_vif_id_sym = "#{arg}_vif_id".to_sym
          current_vif = self.send((current_vif_sym = "#{arg}_vif".to_sym))
          current_network = self.send((current_network_sym = "#{arg}_network".to_sym))
          current_ipv4 = self.send((current_ipv4_sym = "#{arg}_ipv4".to_sym))

          if options[:find_service]
            params = {:network_services__name => options[:find_service]}
            params[:network_vifs__id] = current_vif.id if current_vif

            vifs = current_network.network_vifs_with_service(params)
            raise("Could not find network service for supplied network vif.") if vifs.empty?

            if current_vif.nil?
              current_vif = vifs.first
              self[current_vif_id_sym] = current_vif.id
            end
          end

          if options[:ip_handle]
            current_lease = options[:ip_handle].ip_lease
            lease_vif = current_lease.network_vif

            if lease_vif.nil?
              current_vif.add_ip_lease({:ip_lease => current_lease, :allow_multiple => true}) || raise("Could not add IP lease to network vif.")
            elsif lease_vif != current_vif
              raise("Cannot use IP handle already attached to a network vif.")
            end

            self[current_ipv4_sym] = current_lease.ipv4_i

          elsif options[:lease_ipv4]
            raise("Cannot pass #{arg} IPv4 address argument when leasing address.") if current_ipv4
            self[current_ipv4_sym] = (current_vif.lease_ipv4({:multiple => true}) ||
                                          raise("Could not lease #{arg} IPv4 address")).ipv4_i
          elsif current_ipv4
            ip_lease = current_network.find_ip_lease(current_ipv4)
            raise("Could not find network vif for IPv4 address: #{current_ipv4.to_s}") if ip_lease.nil? || ip_lease.network_vif.nil?
            self[current_vif_id_sym] = ip_lease.network_vif.id

          elsif options[:find_ipv4] == :vif_first
            self[current_ipv4_sym] = (current_vif.ip.first ||
                                      raise("Could not find #{arg} IPv4 address for network vif.")).ipv4_i
          end

          options.delete(:find_ipv4)
          options.delete(:ip_handle)
          options.delete(:lease_ipv4)
        }

        # Validate again to ensure the new values pass the sanity test.
        self.validate
        super
      }
    end

    #
    # Private methods
    #
    private

    def before_destroy
      # Add flag to either routes or ip_lease to indicate if we should release.
      #
      # Currently just release any ip_lease that isn't on a network_vif belonging to a instance.
      
      [:inner, :outer].each { |arg|
        current_vif = self.send("#{arg}_vif")
        # current_network = self.send("#{arg}_network")
        current_ipv4 = self.send("#{arg}_ipv4")

        next if current_ipv4.nil?
        next if current_vif.nil?
        next if current_vif.instance

        ip_lease = current_vif.find_ip_lease(current_ipv4)
        ip_lease.destroy if ip_lease
      }

      super
    end

    def initialize_set(values)
      @create_options = values.delete(:create_options)
      super
    end

    def _destroy_delete
      self.deleted_at ||= Time.now
      self.is_deleted = self.id
      self.save_changes
    end

  end
end
