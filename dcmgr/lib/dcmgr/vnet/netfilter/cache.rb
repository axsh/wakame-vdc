# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Netfilter

      module CacheErrors
        class GroupNotFoundError < Exception
        end
        class VNicNotFoundError < Exception
        end
        class NetworkNotFoundError < Exception
        end
      end

      class NetfilterCache
        include Dcmgr::Logger
        include CacheErrors

        EMPTY_CACHE_SET = {
          :empty_vnics => {}.freeze,
          :security_groups => {}.freeze,
          :networks => {}.freeze
        }.freeze

        def initialize(node)
          # Initialize the values needed to do rpc requests
          @node = node
          @rpc ||= Isono::NodeModules::RpcChannel.new(@node)
          # expects to be replaced by #update() method as soon as possible.
          @cache = EMPTY_CACHE_SET
        end

        #****************#
        # Helper methods #
        #****************#

        def deep_clone(something)
          Marshal.load(Marshal.dump(something))
        end
        private :deep_clone

        def add_network_mode(network)
          logger.debug "Setting network mode for '#{network[:uuid]}'"
          network[:network_mode_class] = Dcmgr::VNet::NetworkModes.get_mode(network[:network_mode])
        end
        private :add_network_mode

        #***********************#
        # Update methods        #
        #***********************#

        # These should always return nil. We don't want the cache te be returned by reference

        def update
          logger.info "updating cache from database"
          @cache = @rpc.request('hva-collector', 'get_netfilter_data', @node.node_id)

          @cache[:networks].each {|k,v| add_network_mode(v) }

          nil
        end

        def update_rules(group_id)
          logger.info "updating rules for group '#{group_id}'"
          group = @cache[:security_groups][group_id]
          group[:rules] = @rpc.request('hva-collector', 'get_rules_of_security_group', group_id)

          nil
        end

        def update_referencees(group_id)
          logger.info "updating referencees for group '#{group_id}'"
          group = @cache[:security_groups][group_id]
          group[:referencees] = @rpc.request('hva-collector', 'get_referencees_of_security_group', group_id)

          nil
        end

        def update_referencers(group_id)
          logger.info "updating referencers for group '#{group_id}'"
          group = @cache[:security_groups][group_id]
          group[:referencers] = @rpc.request('hva-collector', 'get_referencers_of_security_group', group_id)

          nil
        end

        #########################
        # Add methods           #
        #########################

        def add_security_group(group_id)
          logger.info "Adding #{group_id}"
          @rpc.request('hva-collector', 'get_netfilter_security_group', group_id, @node.node_id).tap do |security_group|
            unless security_group
              logger.warn "Security group not found from hva-collector: #{group_id}"
              return
            end
            @cache[:security_groups][group_id] = security_group
            @cache[:security_groups][group_id][:local_vnics].values.each do |vnic|
              add_network vnic[:network_id]
            end
          end
          nil
        end

        def add_network(network_id)
          unless @cache[:networks].has_key?(network_id)
            nw = @rpc.request('hva-collector', 'get_netfilter_network', network_id)
            raise NetworkNotFoundError, "Network #{network_id} doesn't exit" if nw.nil?
            add_network_mode(nw)
            @cache[:networks][network_id] = nw
          end
        end

        def add_vnic(vnic_id)
          result = @rpc.request('hva-collector', 'get_netfilter_vnic_with_node_id', vnic_id)

          raise VNicNotFoundError, "VNic #{vnic_id} doesn't exist" if result.nil?
          if result[:vnic][:security_groups].empty?
            @cache[:empty_vnics][vnic_id] = result[:vnic]
          else
            result[:vnic][:security_groups].each { |group_id|
              logger.info "Adding #{vnic_id} to #{group_id}"
              if @cache[:security_groups].has_key?(group_id)
                @cache[:security_groups][group_id][result[:node_id] == @node.node_id ? :local_vnics : :foreign_vnics][vnic_id] = result[:vnic]

                # Add to referencers and referencees
                @cache[:security_groups].values.each { |group|
                  group[:referencees][group_id][vnic_id] = result[:vnic] if group[:referencees].has_key?(group_id)
                  group[:referencers][group_id][vnic_id] = result[:vnic] if group[:referencers].has_key?(group_id)

                  # Update the vnic in other places in the cache
                  group[:local_vnics][vnic_id] = result[:vnic] if group[:local_vnics].has_key?(vnic_id)
                  group[:foreign_vnics][vnic_id] = result[:vnic] if group[:foreign_vnics].has_key?(vnic_id)
                }
              else
                add_security_group(group_id)
              end
            }
          end

          add_network(result[:vnic][:network_id]) unless network_exists?(result[:vnic][:network_id])

          nil
        end

        def add_vnic_to_security_group(vnic_id,group_id)
          logger.info "Adding #{vnic_id} to #{group_id}"
          if @cache[:security_groups].has_key?(group_id)
            result = @rpc.request('hva-collector', 'get_netfilter_vnic_with_node_id', vnic_id)
            raise VNicNotFoundError, "VNic #{vnic_id} doesn't exist" if result.nil?

            @cache[:security_groups][group_id][result[:node_id] == @node.node_id ? :local_vnics : :foreign_vnics][vnic_id] = result[:vnic]
            logger.debug "#{vnic_id} is a #{result[:node_id] == @node.node_id ? "local" : "foreign"} vnic in #{group_id}"
            # Add to referencers and referencees
            @cache[:security_groups].values.each { |group|
              group[:referencees][group_id][vnic_id] = result[:vnic] if group[:referencees].has_key?(group_id)
              group[:referencers][group_id][vnic_id] = result[:vnic] if group[:referencers].has_key?(group_id)
            }
          else
            add_security_group(group_id)
          end

          nil
        end

        def add_vnic_to_referencers_and_referencees(vnic_id)
          vnic = @rpc.request('hva-collector', 'get_netfilter_vnic', vnic_id)
          raise VNicNotFoundError, "VNic #{vnic_id} doesn't exist" if vnic.nil?
          logger.info "Adding #{vnic_id} in groups #{vnic[:security_groups].join(",")} to referencers and referencees"
          @cache[:security_groups].values.each { |group|
            vnic[:security_groups].each { |group_id|
              group[:referencees][group_id][vnic_id] = vnic if group[:referencees].has_key?(group_id)
              group[:referencers][group_id][vnic_id] = vnic if group[:referencers].has_key?(group_id)
            }
          }

          nil
        end

        def add_vnic_to_referencers_and_referencees_for_group(vnic_id,group_id)
          vnic = @rpc.request('hva-collector', 'get_netfilter_vnic', vnic_id)
          raise VNicNotFoundError, "VNic #{vnic_id} doesn't exist" if vnic.nil?
          logger.info "Adding #{vnic_id} in group #{group_id} to referencers and referencees"
          @cache[:security_groups].values.each { |group|
            group[:referencees][group_id][vnic_id] = vnic if group[:referencees].has_key?(group_id)
            group[:referencers][group_id][vnic_id] = vnic if group[:referencers].has_key?(group_id)
          }

          nil
        end

        #***********************#
        # Removal methods       #
        #***********************#

        # Removes a vnic from any place in the cache
        def remove_vnic(vnic_id)
          @cache[:security_groups].values.each { |group|
            group[:local_vnics].delete vnic_id
            group[:foreign_vnics].delete vnic_id
            group[:referencers].delete vnic_id
            group[:referencees].delete vnic_id
          }

          @cache[:empty_vnics].delete(vnic_id)

          nil
        end

        def remove_local_vnic_from_group(vnic_id,group_id)
          group = @cache[:security_groups][group_id]
          group[:local_vnics].delete vnic_id
          group[:referencers].values.each { |r|
            ref_group = @cache[:security_groups][r[:uuid]]
            unless ref_group.nil?
              ref_group[:referencees].values.each { |ref_group|
                ref_group[:vnics].delete vnic_id
              }
            end
          }

          @cache[:security_groups].values.each { |sg|
            if sg[:local_vnics][vnic_id]
              sg[:local_vnics][vnic_id][:security_groups] -= [group_id]
            end
          }

          nil
        end

        def remove_foreign_vnic(group_id,vnic_id)
          group = @cache[:security_groups][group_id]
          group[:foreign_vnics].delete vnic_id unless group.nil?

          nil
        end

        def remove_vnic_from_referencees(group_id,vnic_id)
          group = @cache[:security_groups].values.each {|local_group|
            ref_group = local_group[:referencees][group_id]
            ref_group.delete vnic_id unless ref_group.nil?
          }

          nil
        end

        def remove_local_vnic(vnic_id)
          vnic = @cache[:security_groups].each { |group_id,group|
            remove_local_vnic_from_group(group_id) if group[:local_vnics].has_key?(vnic_id)
          }

          nil
        end

        def remove_referencer_from_group(group_id,ref_group_id)
          group = @cache[:security_groups][group_id]
          group[:referencers].delete ref_group_id

          nil
        end

        def remove_security_group(group_id)
          logger.info "deleting #{group_id} from cache"
          @cache[:security_groups].delete group_id

          nil
        end

        def remove_network(network_id)
          logger.info "deleting #{network_id} from cache"
          @cache[:networks].delete(network_id)

          nil
        end

        #***********************#
        # Boolean methods       #
        #***********************#

        def is_local_vnic?(vnic_id)
          not get_local_vnic(vnic_id).nil?
        end

        def is_local_vnic_in_group?(vnic_id,group_id)
          (not @cache[:security_groups][group_id].nil?) && @cache[:security_groups][group_id][:local_vnics].has_key?(vnic_id)
        end

        def is_foreign_vnic?(vnic_id)
          not @cache[:security_groups].values.find {|group| group[:foreign_vnics].has_key?(vnic_id)}.nil?
        end

        # Checks if there is a local group that has this vnic as a referencee
        def is_referencee_vnic_in_group?(vnic_id,ref_group_id)
          @cache[:security_groups].values.each { |group|
            return true if group[:referencees].has_key?(ref_group_id) && group[:referencees][ref_group_id].has_key?(vnic_id)
          }

          false
        end

        def is_foreign_vnic_in_group?(vnic_id,group_id)
          group = @cache[:security_groups][group_id]

          group.nil? ? false : group[:foreign_vnics].has_key?(vnic_id)
        end

        def vnic_has_ip?(vnic_id)
          vnic = get_vnic(vnic_id)
          not (vnic.nil? || vnic[:address].nil?)
        end

        def vnic_is_natted?(vnic_id)
          vnic = get_vnic(vnic_id)
          not vnic[:nat_ip_lease].nil?
        end

        def local_vnics_left_in_group?(group_id)
          group = get_group(group_id)
          (not group.nil?) && (not group[:local_vnics].empty?)
        end

        def other_local_vnics_left_in_group?(vnic_id,group_id)
          group = get_group(group_id)
          return false if group.nil?

          deleted = group[:local_vnics].dup
          deleted.delete(vnic_id)
          not deleted.empty?
        end

        def local_referencers_left?(group_id)
          @cache[:security_groups].values.each { |group|
            return true if group[:referencers].has_key?(group_id)
          }

          false
        end

        def local_referencees_left?(group_id)
          @cache[:security_groups].values.each { |group|
            return true if group[:referencees].has_key?(group_id)
          }

          false
        end

        def is_local_group?(group_id)
          @cache[:security_groups].has_key?(group_id)
        end

        def other_groups_referencing_group?(referencer_id,referencee_id)
          other_groups = @cache[:security_groups].dup
          other_groups.delete(referencer_id)

          other_groups.each { |group_id,group|
            return true if group[:referencees].has_key?(group_id)
          }

          false
        end

        def local_vnics_left_in_network?(network_id)
          vnics = @cache[:security_groups].values.map {|g| g[:local_vnics].values }.flatten.uniq.find { |vnic|
            vnic[:network_id] == network_id
          }

          not vnics.nil?
        end

        def empty_vnics_left_in_network?(network_id)
          not @cache[:empty_vnics].values.find {|vnic| vnic[:network_id] == network_id }.nil?
        end

        def network_exists?(network_id)
          @cache[:networks].has_key?(network_id)
        end

        #***********************#
        # Get methods           #
        #***********************#

        def get_all_security_groups
          deep_clone @cache[:security_groups].values
        end

        def get_security_groups_of_local_vnic(vnic_id)
          vnic = get_local_vnic(vnic_id)
          deep_clone vnic[:security_groups].map { |group_id| @cache[:security_groups][group_id] }
        end

        def get_group(group_id)
          deep_clone @cache[:security_groups][group_id]
        end

        def get_all_local_vnics
          deep_clone @cache[:security_groups].values.map {|g| g[:local_vnics].values }.flatten.uniq
        end

        def get_local_vnic(vnic_id)
          @cache[:security_groups].each { |secg_id,secg|
            return deep_clone(secg[:local_vnics][vnic_id]) if secg[:local_vnics].has_key?(vnic_id)
          }

          nil
        end

        def get_empty_vnic(vnic_id)
          deep_clone @cache[:empty_vnics][vnic_id]
        end

        def get_vnic(vnic_id)
          vnic = get_empty_vnic(vnic_id)
          vnic = get_local_vnic(vnic_id) if vnic.nil?
          vnic = get_foreign_vnic(vnic_id) if vnic.nil?

          # Above methods already deep clone the vnic. No need to do it again
          vnic
        end

        def get_foreign_vnic(vnic_id,group_id = nil)
          if group_id.nil?
            @cache[:security_groups].each { |secg|
              return deep_clone(secg[:foreign_vnics][vnic_id]) if secg[:foreign_vnics].has_key?(vnic_id)
            }

            nil
          else
            group = @cache[:security_groups][group_id]
            deep_clone group[:foreign_vnics][vnic_id]
          end
        end

        def get_referencee_vnics(group_id)
          group_map = @cache[:security_groups][group_id]
          raise GroupNotFoundError, "Security group not found in cache: '#{group_id}'" if group_map.nil?
          deep_clone group_map[:referencees].values
        end

        def get_referencer(group_id,ref_id)
          group = @cache[:security_groups][group_id]
          raise GroupNotFoundError, "Security group not found in cache: '#{group_id}'" if group.nil?

          deep_clone group[:referencers][ref_id]
        end

        def get_local_vnics_in_group(group_id)
          group = @cache[:security_groups][group_id]
          return [] if group.nil?

          deep_clone group[:local_vnics].values
        end

        def get_foreign_vnics_in_group(group_id)
          group = @cache[:security_groups][group_id]
          raise GroupNotFoundError, "Security group not found in cache: '#{group_id}'" if group.nil?

          group[:foreign_vnics].values
        end

        def get_local_groups_that_reference_group(ref_group_id)
          deep_clone @cache[:security_groups].values.map { |local_group|
            next unless local_group[:referencees].has_key?(ref_group_id)
            local_group
          }.compact
        end

        def get_all_local_friends(vnic_id)
          vnic_map = get_vnic(vnic_id)
          raise VNicNotFoundError, "VNic not found in cache: '#{vnic_id}'" if vnic_map.nil?

          friends = vnic_map[:security_groups].map {|group_id|
            next unless @cache[:security_groups][group_id]
            @cache[:security_groups][group_id][:local_vnics].values
          }.flatten.compact

          chk_dup = {}
          friends.delete_if { |friend|
            isdel = (friend[:uuid] == vnic_id || chk_dup.has_key?(friend[:uuid]))
            chk_dup[friend[:uuid]]=1
            isdel
          }

          deep_clone friends
        end

        def get_local_friends_in_group(vnic_id,group_id)
          friends = @cache[:security_groups][group_id][:local_vnics].dup
          friends.delete vnic_id

          deep_clone friends.values
        end

        def get_friends_in_group(vnic_id, group_id)
          friends = {}

          friends.merge! @cache[:security_groups][group_id][:local_vnics]
          friends.merge! @cache[:security_groups][group_id][:foreign_vnics]

          friends.delete(vnic_id)

          deep_clone friends.values
        end

        def get_all_friends(vnic_id)
          vnic_map = get_vnic(vnic_id)
          raise VNicNotFoundError, "VNic not found in cache: '#{vnic_id}'" if vnic_map.nil?
          friends = []
          vnic_map[:security_groups].each {|group_id|
            friends << @cache[:security_groups][group_id][:local_vnics].values
            friends << @cache[:security_groups][group_id][:foreign_vnics].values
          }

          friends.flatten!
          chk_dup = {}
          friends.delete_if { |friend|
            isdel = (friend[:uuid] == vnic_id || chk_dup.has_key?(friend[:uuid]))
            chk_dup[friend[:uuid]]=1
            isdel
          }

          deep_clone friends
        end

        def get_all_empty_vnics()
          deep_clone @cache[:empty_vnics].values
        end

        def get_vnic_network(vnic_id)
          network_id = get_vnic(vnic_id)[:network_id]
          deep_clone @cache[:networks][network_id]
        end

        def get_network(network_id)
          deep_clone @cache[:networks][network_id]
        end

        def get_vnic_network_mode(vnic_id)
          network_id = get_vnic(vnic_id)[:network_id]
          @cache[:networks][network_id][:network_mode_class]
        end

        #################
        # Debug methods #
        #################
        def dump
          logger.debug @cache
        end

      end

    end
  end
end
