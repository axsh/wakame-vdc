module Wakame
  module Actions
    class DeployApplication < Action
      def initialize(app_name)
        @app_name = app_name
      end

      def run
        Wakame.log.debug("#{self.class}: run() Begin:")
        #raise "CloudHost is not mapped Agent: CloudHost.id=#{@svc.cloud_host.id}" unless @svc.cloud_host.mapped?

        repo_data = Models::ApplicationRepository.find(:app_name=>@app_name) || raise
        deploy_opts={}
        if repo_data[:repo_type] == 's3'
          deploy_opts[:aws_access_key] ||= Wakame.config.aws_access_key
          deploy_opts[:aws_secret_key] ||= Wakame.config.aws_secret_key
        end
        deploy_ticket = Wakame::Util.gen_id


        resclass_names = []
        svc_lst = []
        cluster.each_instance { |svc|
          next  unless svc.resource.tags.member?(repo_data.resource_tag.to_sym)
          resclass_names << svc.resource.class.to_s
          svc_lst << svc
        }

        if svc_lst.empty?
          return
        end

        resclass_names.uniq!
        acquire_lock(resclass_names)
        
        # Checkout apps from each repository
        svc_lst.each { |svc|
          trigger_action {|action|
            action.actor_request(svc.cloud_host.agent_id, '/deploy/checkout',
                                 deploy_ticket,
                                 repo_data[:repo_type],
                                 repo_data[:repo_uri],
                                 repo_data[:revision],
                                 svc.resource.application_root_path,
                                 repo_data[:app_name],
                                 deploy_opts
                                 ).request.wait
          }
        }
        flush_subactions

        # Reload Appserver
        svc_lst.each { |svc|
          actor_request(svc.cloud_host.agent_id, '/deploy/swap_current_link', svc.resource.application_root_path, repo_data[:app_name]).request.wait
          svc.resource.on_reload_application(svc, self, repo_data)
        }
      end

    end
  end
end
