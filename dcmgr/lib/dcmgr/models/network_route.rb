# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Models
  class NetworkRoute < AccountResource

    many_to_one :outer_lease, :key => :outer_lease_id, :class => NetworkVifIpLease
    many_to_one :inner_lease, :key => :inner_lease_id, :class => NetworkVifIpLease

    subset(:alives, {:network_routes__deleted_at => nil})

    dataset_module {
      def join_with_ip_leases
        self.join_table(:left, :network_vif_ip_leases,
                        {:network_vif_ip_leases__id => :network_routes__outer_lease_id} |
                        {:network_vif_ip_leases__id => :network_routes__inner_lease_id}).alives
      end

      def join_with_outer_ip_leases
        self.join_table(:left, :network_vif_ip_leases,
                        {:outer_ip_leases__id => :network_routes__outer_lease_id},
                        :table_alias => :outer_ip_leases).alives
      end

      def join_with_inner_ip_leases
        self.join_table(:left, :network_vif_ip_leases,
                        {:inner_ip_leases__id => :network_routes__inner_lease_id},
                        :table_alias => :inner_ip_leases).alives
      end

      def between_vifs(outer_vif, inner_vif)
        ds = self
        ds = ds.join_with_outer_ip_leases.where(:outer_ip_leases__network_vif_id => outer_vif.id)
        ds = ds.join_with_inner_ip_leases.where(:inner_ip_leases__network_vif_id => inner_vif.id).select_all(:network_routes).alives
      end
    }

    def outer_network
      lease = self.outer_lease
      return nil unless lease
      return lease.network
    end

    def inner_network
      lease = self.inner_lease
      return nil unless lease
      return lease.network
    end

    def outer_vif
      lease = self.outer_lease
      return nil unless lease
      return lease.network_vif
    end

    def inner_vif
      lease = self.inner_lease
      return nil unless lease
      return lease.network_vif
    end

    #
    # Sequel methods:
    #

    def validate
      [:inner, :outer].each { |arg|
        # We don't validate anything beyond the above when the network
        # route is being deleted.
        next if self.deleted_at || @create_options.nil?
        
        options = @create_options[arg]

        current_vif = self.send((current_vif_sym = "#{arg}_vif".to_sym))

        if options[:network_vif] && current_vif
          errors.add(arg, "IP handle's network vif must match the 'network_vif' parameter.") unless current_vif == options[:network_vif]
        end

        if options[:find_service]
          errors.add(arg, "Network must be defined when using 'find_service'.") unless options[:network]
          service_vifs = self.get_network_services(options[:network], options[:find_service], options[:network_vif])
          errors.add(arg, "Could not find network service for supplied network vif.") if service_vifs.empty?
        end
      }

      if self.inner_vif && self.outer_vif
        errors.add(:inner_vif, "Cannot create route between the same network vif.") if self.inner_vif == self.outer_vif
      end
      
      if self.inner_network && self.outer_network
        errors.add(:inner_network, "Cannot create route between the same network.") if self.inner_network == self.outer_network
      end
      
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

          current_release_sym = "release_#{arg}_vif".to_sym
          current_lease_id_sym = "#{arg}_lease_id".to_sym
          current_lease = self.send((current_lease_sym = "#{arg}_lease".to_sym))

          if options[:find_service]
            vifs = self.get_network_services(options[:network], options[:find_service], options[:network_vif])
            options[:network_vif] = vifs.first 
          end

          if options[:find_ipv4] == :vif_first
            # Check that current_lease is nil.
            options[:network_vif] || raise("Network Vif must be included when using ':find_ipv4 => :vif_first'")
            self[current_lease_id_sym] = (options[:network_vif].ip.first ||
                                          raise("Could not find #{arg} IPv4 address for network vif.")).id
          elsif current_lease
            lease_vif = current_lease.network_vif

            if lease_vif.nil?
              raise("Cannot add IP lease without network vif.") unless options[:network_vif]

              self[current_release_sym] = true

              if !options[:network_vif].add_ip_lease({:ip_lease => current_lease, :allow_multiple => true})
                raise("Could not add IP lease to network vif.")
              end
            end
          end
        }

        @create_options = nil

        # Validate again to ensure the new values pass the sanity test.
        self.validate
        super
      }
    end

    def get_network_services(network, service, network_vif)
      params = {:network_services__name => service}
      params[:network_vifs__id] = options[:network_vif].id if network_vif

      network.network_vifs_with_service(params)
    end

    #
    # Private methods
    #
    private

    def before_destroy
      # Destroy IP leases if they are not owned by a network vif.
      [:inner, :outer].each { |arg|
        current_lease = self.send("#{arg}_lease")

        next if current_lease.nil?

        if current_lease.network_vif && self.send("release_#{arg}_vif")
          current_lease.network_vif.remove_ip_lease(:ip_lease => current_lease)
        end
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
