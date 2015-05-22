# -*- coding: utf-8 -*-

require 'pp'

module Dcmgr
  module EdgeNetworking
    module Netfilter
      # Decorator class to dump @cache contents.
      # cache = NetfilterCache.new(....)
      # cache = CacheDumper.new(cache)
      #
      # % ls /tmp/hvanf20130514-3841-7nf1js
      # 1368529295632124.update
      # 1368529639817285.remove_vnic_from_referencees
      # 1368529518940258.add_network
      # 1368529518943902.add_security_group
      # 1368529518967889.add_network
      class CacheDumper
        def initialize(subject, dump_dst=nil)
          raise ArgumentError, "Only supports #{NetfilterCache} object" unless subject.is_a?(NetfilterCache)
          @subject = subject

          case dump_dst
          when String
            if File.exists?(dump_dst) && File.directory?(dump_dst)
              @dump_dst = Dir.open(dump_dst)
            else
              raise ArgumentError, "CacheDumper string destination must be a directory. #{dump_dst}"
            end
          when Dir, IO
            @dump_dst = dump_dst
          when NilClass
            @dump_dst = STDOUT
          end
        end

        # methods to alter @cache.
        [[:update, []],
         [:update_rules, [:group_id]],
         [:update_referencees, [:group_id]],
         [:update_referencers, [:group_id]],
         [:add_security_group, [:group_id]],
         [:add_network,        [:network_id]],
         [:add_vnic, [:vnic_id]],
         [:add_vnic_to_security_group, [:vnic_id, :group_id]],
         [:add_vnic_to_referencers_and_referencees, [:vnic_id]],
         [:add_vnic_to_referencers_and_referencees_for_group, [:vnic_id, :group_id]],
         [:remove_vnic, [:vnic_id]],
         [:remove_local_vnic_from_group, [:vnic_id, :group_id]],
         [:remove_foreign_vnic, [:group_id, :vnic_id]],
         [:remove_vnic_from_referencees, [:group_id, :vnic_id]],
         [:remove_vnic_from_referencers, [:group_id, :vnic_id]],
         [:remove_referencer_from_group, [:group_id, :ref_group_id]],
         [:remove_security_group, [:group_id]],
         [:remove_network, [:network_id]],
        ].each { |m|
          class_eval %Q{
            def #{m[0]}(#{m[1].join(', ')})
              res = @subject.#{m[0]}(#{m[1].join(', ')})
              dump_cache("#{m[0]}", [#{m[1].join(', ')}])
              res
            end
          }
        }

        def logger
          @subject.logger
        end

        private
        def dump_cache(cache_method_name, cache_args)
          case @dump_dst
          when Dir
            dump_to_dir(@dump_dst.path, cache_method_name, cache_args)
          when IO
            dump_to_io(@dump_dst, cache_method_name, cache_args)
          else
            raise TypeError, "Unknown Type of @dump_dst: #{@dump_dst.class}"
          end
        end

        def dump_to_dir(dir_path, cache_method_name, cache_args)
          t = Time.now
          File.open(File.expand_path(("%d%06d.%s" % [t.to_i, t.usec, cache_method_name]), dir_path), "w") { |f|
            dump_to_io(f, cache_method_name, cache_args)
          }
        end

        def dump_to_io(f, cache_method_name, cache_args)
          f.puts "#{cache_method_name}(#{cache_args.join(', ')}), #{Thread.current}"
          f.puts ""
          PP.pp(@subject.instance_variable_get(:@cache), f, 200)
        end

        def method_missing(name, *args)
          @subject.public_send(name, *args)
        end
      end
    end
  end
end
