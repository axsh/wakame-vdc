# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Netfilter

      module CacheErrors
        class GroupNotFoundError < Exception
        end
        class VNicNotFoundError < Exception
        end
      end
    
      class NetfilterCache
        include Dcmgr::Logger
        include CacheErrors
        
        def initialize(node)
          # Initialize the values needed to do rpc requests
          @node = node
          @rpc ||= Isono::NodeModules::RpcChannel.new(@node)
        end
        
        def deep_clone(something)
          Marshal.load(Marshal.dump(something))
        end

        #***********************#
        # Update methods        #
        #***********************#

        # These should always return nil. We don't want the cache te be returned by reference

        def update
          logger.info "updating cache from database"
          @cache = @rpc.request('hva-collector', 'get_netfilter_data', @node.node_id)

          nil
        end
        
        def update_rules(group_id)
          logger.info "updating rules for group '#{group_id}'"
          group = @cache[:security_groups].find {|g| g[:uuid] == group_id}
          group[:rules] = @rpc.request('hva-collector', 'get_rules_of_security_group', group_id)
          
          nil
        end
        
        def update_referencees(group_id)
          logger.info "updating referencees for group '#{group_id}'"
          group = @cache[:security_groups].find {|g| g[:uuid] == group_id}
          group[:referencees] = @rpc.request('hva-collector', 'get_referencees_of_security_group', group_id)
          
          nil
        end
        
        def update_referencers(group_id)
          logger.info "updating referencers for group '#{group_id}'"
          group = @cache[:security_groups].find {|g| g[:uuid] == group_id}
          group[:referencers] = @rpc.request('hva-collector', 'get_referencers_of_security_group', group_id)
          
          nil
        end
        
        #***********************#
        # Removal methods       #
        #***********************#
        
        # Removes a vnic from any place in the cache
        def remove_vnic(vnic_id)
          @cache[:security_groups].each { |group|
            group[:local_vnics].delete_if   { |vnic| vnic[:uuid] == vnic_id}
            group[:foreign_vnics].delete_if { |vnic| vnic[:uuid] == vnic_id}
            group[:referencers].delete_if   { |vnic| vnic[:uuid] == vnic_id}
            group[:referencees].delete_if   { |vnic| vnic[:uuid] == vnic_id}
          }
          
          nil
        end
        
        def remove_local_vnic_from_group(vnic_id,group_id)
          group = @cache[:security_groups].find {|g| g[:uuid] == group_id}
          group[:local_vnics].delete_if   { |vnic| vnic[:uuid] == vnic_id}
          group[:referencers].each { |r|
            ref_group = get_group(r[:uuid])
            unless ref_group.nil?
              ref_group[:referencees].each { |ref_group|
                ref_group[:vnics].delete_if   { |vnic| vnic[:uuid] == vnic_id}
              }
            end
          }
          
          nil
        end
        
        def remove_foreign_vnic(group_id,vnic_id)
          group = @cache[:security_groups].find { |group| group[:uuid] == group_id }
          group[:foreign_vnics].delete_if { |vnic| vnic[:uuid] == vnic_id} unless group.nil?
          
          nil
        end
        
        def remove_vnic_from_referencees(group_id,vnic_id)
          group = @cache[:security_groups].each {|local_group| 
            ref_group = local_group[:referencees].find { |group| group[:uuid] == group_id }
            ref_group[:vnics].delete_if { |vnic|
              vnic[:uuid] == vnic_id
            } unless ref_group.nil?
          }
          
          nil
        end
        
        def remove_local_vnic(vnic_id)
          vnic = @cache[:security_groups].map { |secg|
            secg[:local_vnics]
          }.flatten.find { |vnic|
            vnic[:uuid] == vnic_id
          }
          
          vnic[:security_groups].each { |group_id|
            remove_local_vnic_from_group(group_id)
          }
          
          nil
        end
        
        def remove_referencer_from_group(group_id,ref_group_id)
          group = @cache[:security_groups].find { |group| group[:uuid] == group_id }
          group[:referencers].delete_if {|r| r[:uuid] == ref_group_id}
          
          nil
        end
        
        def remove_security_group(group_id)
          logger.info "deleting #{group_id} from cache"
          @cache[:security_groups].delete_if {|group| group[:uuid] == group_id}
          
          nil
        end

        #***********************#
        # Boolean methods       #
        #***********************#

        def is_local_vnic?(vnic_id)
          not get_local_vnic(vnic_id).nil?
        end
        
        def is_foreign_vnic?(vnic_id)
          foreign_vnics = @cache[:security_groups].map {|group| group[:foreign_vnics]}.flatten
          
          not foreign_vnics.find {|vnic| vnic[:uuid] == vnic_id}.nil?
        end
        
        def is_referencee_vnic_in_group?(vnic_id,group_id)
          ref_group = nil
          @cache[:security_groups].each { |group|
            ref_group = group[:referencees].find { |ref| ref[:uuid] == group_id }
            break unless ref_group.nil?
          }
          not ref_group[:vnics].find {|vnic| vnic[:uuid] == vnic_id}.nil?
        end
        
        def is_foreign_vnic_in_group?(vnic_id,group_id)
          group = get_group(group_id)
          foreign_vnics = group.nil? ? [] : group[:foreign_vnics]
          
          not foreign_vnics.find {|vnic| vnic[:uuid] == vnic_id}.nil?
        end
        
        def vnic_has_ip?(vnic_id)
          vnic = get_vnic(vnic_id)
          not (vnic[:ipv4].nil? or vnic[:ipv4][:network].nil?)
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
          
          not group[:local_vnics].dup.delete_if {|vif| vif[:uuid] == vnic_id}.empty?
        end
        
        def local_referencers_left?(group_id)
          other_local_refs = @cache[:security_groups].map {|g|
            g[:referencers].find {|ref| ref[:uuid] == group_id}
          }.compact
          
          not other_local_refs.empty?
        end
        
        def local_referencees_left?(group_id)
          other_local_refs = @cache[:security_groups].map {|g|
            g[:referencees].find {|ref| ref[:uuid] == group_id}
          }.compact
          
          not other_local_refs.empty?
        end
        
        def is_local_group?(group_id)
          not @cache[:security_groups].find {|g| g[:uuid] == group_id}.nil?
        end
        
        def other_groups_referencing_group?(referencer_id,referencee_id)
          other_groups = @cache[:security_groups].dup.delete_if { |group| group[:uuid] == referencer_id }
          
          other_groups.map! {|g|
            g[:referencees].find { |r| r[:uuid] == referencee_id }
          }.compact
          
          not other_groups.empty?
        end

        #***********************#
        # Get methods           #
        #***********************#
        
        def get_all_security_groups
          deep_clone @cache[:security_groups]
        end
        
        def get_security_groups_of_local_vnic(vnic_id)
          deep_clone @cache[:security_groups].dup.delete_if {|g| 
            g[:local_vnics].find {|v| v[:uuid] == vnic_id}.nil?
          }
        end
        
        def get_group(group_id)
          group = @cache[:security_groups].find {|g| g[:uuid] == group_id}
          
          deep_clone group
        end
        
        def get_all_local_vnics
          deep_clone @cache[:security_groups].map {|g| g[:local_vnics] }.flatten.uniq
        end
        
        def get_local_vnic(vnic_id)
          deep_clone @cache[:security_groups].map { |secg|
            secg[:local_vnics]
          }.flatten.find { |vnic|
            vnic[:uuid] == vnic_id
          }
        end
        
        def get_vnic(vnic_id)
          vnic = get_local_vnic(vnic_id)
          vnic = get_foreign_vnic(vnic_id) if vnic.nil?
          
          deep_clone vnic
        end
        
        def get_foreign_vnic(vnic_id,group_id = nil)
          if group_id.nil?
            deep_clone @cache[:security_groups].map { |secg|
              secg[:foreign_vnics]
            }.flatten.find { |vnic|
              vnic[:uuid] == vnic_id
            }
          else
            group = get_group(group_id)
            deep_clone group[:foreign_vnics].find {|vnic| vnic[:uuid] == vnic_id}
          end
        end
        
        def get_referencee_vnics(group_id)
          group_map = get_group(group_id)
          raise GroupNotFoundError, "Security group not found in cache: '#{group_id}'" if group_map.nil?
          deep_clone group_map[:referencees].map {|r| r[:vnics] }.flatten.uniq
        end
        
        def get_referencer(group_id,ref_id)
          group = get_group(group_id)
          raise GroupNotFoundError, "Security group not found in cache: '#{group_id}'" if group.nil?
          
          deep_clone group[:referencers].find {|r| r[:uuid] == ref_id}
        end
        
        def get_local_vnics_in_group(group_id)
          group = get_group(group_id)
          raise GroupNotFoundError, "Security group not found in cache: '#{group_id}'" if group.nil?
          
          deep_clone group[:local_vnics]
        end
        
        def get_foreign_vnics_in_group(group_id)
          group = get_group(group_id)
          raise GroupNotFoundError, "Security group not found in cache: '#{group_id}'" if group.nil?
          
          group[:foreign_vnics]
        end
        
        def get_local_groups_that_reference_group(ref_group_id)
          deep_clone @cache[:security_groups].map { |local_group|
            next if local_group[:referencees].find {|r| r[:uuid] == ref_group_id }.nil?
            local_group
          }.compact
        end
        
        def get_all_local_friends(vnic_id)
          vnic_map = get_vnic(vnic_id)
          raise VNicNotFoundError, "VNic not found in cache: '#{vnic_id}'" if vnic_map.nil?
          
          friends = vnic_map[:security_groups].map {|group_id| 
            get_local_vnics_in_group(group_id)
          }.flatten.uniq
          
          friends.delete_if {|friend| friend[:uuid] == vnic_map[:uuid]}
          
          deep_clone friends
        end
        
        def get_local_friends_in_group(vnic_id,group_id)
          friends = get_local_vnics_in_group(group_id)
          friends.delete_if  { |friend| friend[:uuid] == vnic_id }
          
          deep_clone friends
        end
        
        def get_friends_in_group(vnic_id, group_id)
          friends = get_local_vnics_in_group(group_id) + get_foreign_vnics_in_group(group_id)
          friends.delete_if  { |friend| friend[:uuid] == vnic_id }
          
          deep_clone friends
        end
        
        def get_all_friends(vnic_id)
          vnic_map = get_vnic(vnic_id)
          raise VNicNotFoundError, "VNic not found in cache: '#{vnic_id}'" if vnic_map.nil?
          friends = vnic_map[:security_groups].map {|group_id| 
            get_local_vnics_in_group(group_id) + get_foreign_vnics_in_group(group_id)
          }.flatten.uniq
          
          friends.delete_if {|friend| friend[:uuid] == vnic_map[:uuid]}
          
          deep_clone friends
        end
        
      end
      
    end
  end
end
