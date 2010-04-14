module Wakame
  module Actions
    module Util

      def deploy_configuration(service_instance)
        Wakame.log.debug("Begin: #{self}.deploy_configuration(#{service_instance.property.class})")
        
        begin
          tmpl = Wakame::Template.new(service_instance)
          tmpl.render_config
          
          agent = service_instance.agent
          src_path = tmpl.tmp_basedir.dup
          src_path.sub!('/$', '') if File.directory? src_path
          
          dest_path = File.expand_path("tmp/config/" + File.basename(tmpl.basedir), service_instance.agent.root_path)
          Wakame::Util.exec("rsync -e 'ssh -i #{Wakame.config.ssh_private_key} -o \"UserKnownHostsFile #{Wakame.config.ssh_known_hosts}\"' -au #{src_path}/ root@#{agent.agent_ip}:#{dest_path}")
          #Util.exec("rsync -au #{src_path}/ #{dest_path}")
          
        ensure
          tmpl.cleanup if tmpl
        end

        Wakame.log.debug("End: #{self}.deploy_configuration(#{service_instance.property.class})")
      end

      def test_agent_candidate(svc_prop, agent)
        return false if agent.has_service_type?(svc_prop.class)
        svc_prop.vm_spec.current.satisfy?(agent) 
      end

      # Arrange an agent for the paticular service instance from agent pool.
      def arrange_agent(svc_prop)
        agent = nil
        agent_monitor.each_online { |ag|
          if test_agent_candidate(svc_prop, ag)
            agent = ag
            break
          end
        }
        agent = agent[1] if agent

        agent
      end
    end
  end
end
