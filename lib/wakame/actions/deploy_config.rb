module Wakame
  module Actions
    class DeployConfig < Action
      def initialize(svc)
        @svc = svc
      end

      def run
        Wakame.log.debug("#{self.class}: run() Begin: #{@svc.resource.class}")
        raise "CloudHost is not mapped Agent: CloudHost.id=#{@svc.cloud_host.id}" unless @svc.cloud_host.mapped?

        acquire_lock(@svc.resource.class.to_s)

        begin
          tmpl = Wakame::Template.new(@svc)
          tmpl.render_config
          
          src_path = tmpl.tmp_basedir.dup
          src_path.sub!('/$', '') if File.directory? src_path
          
          dest_path = File.expand_path("tmp/config/" + File.basename(tmpl.basedir), @svc.cloud_host.root_path)
          #Wakame::Util.exec("rsync -e 'ssh -i #{Wakame.config.ssh_private_key} -o \"UserKnownHostsFile #{Wakame.config.ssh_known_hosts}\"' -au #{src_path}/ root@#{@svc.cloud_host.agent_ip}:#{dest_path}")
          Wakame::Util.exec("rsync -e 'ssh -i #{Wakame.config.ssh_private_key} -o \"StrictHostKeyChecking no\"' -au #{src_path}/ root@#{@svc.cloud_host.agent_ip}:#{dest_path}")
          
        ensure
          tmpl.cleanup if tmpl
        end

        Wakame.log.debug("#{self.class}: run() End: #{@svc.resource.class}")
      end
    end
  end
end
