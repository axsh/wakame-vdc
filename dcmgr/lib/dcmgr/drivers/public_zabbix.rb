# -*- coding: utf-8 -*-

require 'multi_json'

module Dcmgr::Drivers
  class PublicZabbix < Zabbix
    include Dcmgr::Logger

    class Configuration < Zabbix::Configuration
      param :hostgroup_name, :default=>"Public_Template"
      param :template_name
      param :template_id

      def validate(errors)
        if @config[:template_id].nil? && @config[:template_name].nil?
          errors << "template_id or template_name either or them need to be set."
        end
      end
    end

    ITEMS = {
      'PING' => {
        :monitor_type => :vif,
        :item_key => 'icmpping[{$IPADDRESS},,,,1000]',
        :macros => lambda {|vifmon, macroset|
        }
      },
      'PORT' => {
        :monitor_type => :vif,
        :item_key => 'tcp,{$PORT}',
        :macros => lambda {|vifmon, macroset|
          macroset['{$PORT}'] = vifmon.params['port'] || "0"
        }
      },
      'PROCESS' => {
        :monitor_type => :process,
        :item_key => 'proc.num[,,,{$PROCESS}]',
        :macros => lambda {|params, macroset|
          macroset['{$PROCESS}'] = params[:params]['name'] || "0"
        }
      },
    }.freeze

    MACRO_DEFAULT = {
      '{$PORT}'=>"0",
      '{$PROCESS}'=>"0",
    }.freeze

    def register_instance(instance)
      title2pmonitors = {}
      instance.monitor_items.each_pair { |k, v|
        if v[:title] =~ /^PROCESS$/
          title2pmonitors[v[:title]]=v.merge({:uuid=>k})
        end
      }

      vif = instance.network_vif_dataset.alives.filter(:device_index =>0).first

      if vif.nil?
        logger.warn("No VIF found on #{instance.canonical_uuid}. Skipping to register to Zabbix #{configuration.api_uri}")
        return
      end

      res = rpc_request('hostgroup.get', {:filter=>{:name=>configuration.hostgroup_name}, :output=>'extend', :limit=>1})
      raise "Failed to find hostgroup: #{configuration.hostgroup_name}" unless res.result

      hgrpids = []
      hgrpids << res.result.first['groupid']

      res = if configuration.template_name
              rpc_request('template.get', {:filter=>{:host=>configuration.template_name}, :output=>'extend', :select_macros=>'extend', :limit=>1})
            else
              rpc_request('template.get', {:filter=>{:templateid=>configuration.template_id}, :output=>'extend', :select_macros=>'extend', :limit=>1})
            end

      template = res.result.first

      host_created = false
      res = rpc_request('host.get', {:filter=>{:host=>instance.canonical_uuid}, :output=>'extend', :limit=>1})
      if res.result.first.nil?
        res = rpc_request('host.create',
                          {:host=>instance.canonical_uuid,
                            :dns=>vif.direct_ip_lease.first.ipv4_s,
                            :ip => vif.direct_ip_lease.first.ipv4_s,
                            :port => 10050,
                            :useip => 1, # here is 1 = true
                            :groups=>hgrpids.map{ |g| {:groupid=>g} },
                            :templates=>[{:templateid=>template['templateid']}],
                            :status => (instance.label('monitoring.enabled').value == 'true') ? 0 : 1,
                          })

        hostid = res.result['hostids'].first
        host_created = true
      else
        hostid = res.result.first['hostid']
        if (res.result.first['status'].to_i == 0) != (instance.label('monitoring.enabled').value == 'true')
          rpc_request('host.update', [{:hostid=>hostid, :status=> ((instance.label('monitoring.enabled').value == 'true') ? 0: 1), }])
        end
      end

      # update host macros
      macros = MACRO_DEFAULT.dup.merge({'{$IPADRESS1}'=>vif.direct_ip_lease.first.ipv4_s})

      vif.network_vif_monitors_dataset.alives.each { |vifmon|
        ITEMS[vifmon.title][:macros].call(vifmon, macros)
      }
      title2pmonitors.each_pair { |title, params|
        ITEMS[title][:macros].call(params, macros)
      }

      if host_created
        res = rpc_request('host.massAdd',
                          {:hosts=>{:hostid=>hostid},
                            :macros => macros.map { |k,v| {:macro=>k, :value=>v} },
                          })
      else
        res = rpc_request('host.massUpdate',
                          {:hosts=>{:hostid=>hostid},
                            :macros => macros.map { |k,v| {:macro=>k, :value=>v} },
                          })
      end

      # fetch monitoring items set by template.
      res = rpc_request('item.get', {:filter=>{:hostid=>[hostid]}, :select_triggers=>'extend', :output=>'extend'})

      title2monitors = Hash[*vif.network_vif_monitors_dataset.alives.all.map {|i| [i.title, i]  }.flatten]

      key2itm = {}
      triggers = {}
      res.result.each { |itm|
        key2itm[itm['key_']] = itm
        triggers[itm['key_']] = itm['triggers'].map { |i| i['triggerid'] }
      }

      # enable items
      rpc_request('item.update', ITEMS.map { |title, tmpl|
                    itm = key2itm[tmpl[:item_key]]
                    r = {:itemid=>itm['itemid'], :status=>1}
                    if title2monitors[title]
                      r[:status] = title2monitors[title].enabled ? 0 : 1
                    elsif title2pmonitors[title]
                      r[:status] = title2pmonitors[title][:enabled] ? 0 : 1
                    end
                    r
                  })

      # enable triggers
      res = rpc_request('trigger.update', ITEMS.map { |title, tmpl|
                          triggerids = triggers[tmpl[:item_key]]
                          triggerids.map { |t|
                            r = {:triggerid=>t, :status=>1}
                            if title2monitors[title]
                              r[:status] = title2monitors[title].params['trigger_enabled'] ? 0 : 1
                              r[:comments] = "#{title2monitors[title].canonical_uuid}:#{title}:#{title2monitors[title].params['notification_id']}"
                            elsif title2pmonitors[title]
                              r[:status] = title2pmonitors[title][:params]['trigger_enabled'] ? 0 : 1
                              r[:comments] = "#{title2pmonitors[title][:uuid]}:#{title}:#{title2pmonitors[title][:params]['notification_id']}"
                            end
                            r
                          }
                        }.flatten)
    end

    def update_instance(instance)
      register_instance(instance)
    end

    def unregister_instance(instance)
      res = rpc_request('host.get', {:filter=>{:host=>instance.canonical_uuid}, :limit=>1})
      if !res.result.empty?
        rpc_request('host.delete', [{:hostid=>res.result.first['hostid']}])
      end

    end
  end
end


