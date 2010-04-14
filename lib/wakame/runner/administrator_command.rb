
require 'uri'
require 'cgi'
require 'optparse'
require 'net/http'
require 'json'
require 'erb'
require 'wakame'

#require 'openssl'
#require 'base64'

$root_constants = Module.constants

module Wakame
  module Runner
    class AdministratorCommand
      attr_reader :options
     
      def initialize(args)
        @args = args.dup      
	@options = {
          :command_server_uri => Wakame.config.http_command_server_uri,
          :json_print => false,
          :public_key => '1234567890'
        }

        load_subcommands
      end
      
      def parse(args=@args)
        args = args.dup
        
        comm_parser = OptionParser.new { |opts|
          opts.version = Wakame::VERSION
          opts.banner = "Usage: wakameadm [options] command [options]"
          opts.separator " "
          opts.separator "Sub Commands:"
          opts.separator show_subcommand_summary()
          opts.separator " "
          opts.separator "Common Options:"
          opts.on( "-s", "--server HttpURI", "command server" ) {|str| @options[:command_server_uri] = str }
          opts.on("--dump", "Print corresponded message body for debugging"){|j| @options[:json_print] = true }
        }

        comm_parser.order!(args)
        @options.freeze

        return parse_subcommand(args)
      end
      
      def run
        parse

	#if Wakame.config.enable_authentication == "true"
	#  get_params = authentication(req[:command_server_uri], req[:query_string])
	#else
	#  get_params = req[:command_server_uri] + req[:query_string]
	#end

        begin
          requester = JsonRequester.new(options.dup, {:action=>@subcmd.class.command_name})
          @subcmd.run(requester)


          @subcmd.print_result

        rescue JsonRequester::ResponseError => e
          abort(e)
        rescue => e
          abort("Unknown Error: #{e}\n" + e.backtrace.join("\n")  )
        end

        exit 0
      end
      
      private
      
      def parse_subcommand(args)
        subcmd_name = args.shift
        if subcmd_name.nil?
          fail "Please pass a sub command." 
        end
        subcommand_class = @subcommand_types[subcmd_name]
        fail "No such sub command: #{subcmd_name}" if subcommand_class.nil?

        @subcmd = subcommand_class.new

        options = @subcmd.parse(args)
      end

      def load_subcommands
        @subcommand_types = {}
        (Wakame::Cli::Subcommand.constants - $root_constants).each { |c|
          const = Util.build_const("Wakame::Cli::Subcommand::#{c}")
          if const.is_a?(Class)
            next unless const < Wakame::Cli::Subcommand
            @subcommand_types[const.command_name] = const
          end
        }
      end

      def show_subcommand_summary
        @subcommand_types.map { |k,v|
          "  #{k}: #{v.summary.nil? ? '' : v.summary.to_s}"
        }
      end
    end
  end

  class JsonRequester
    class ResponseError < StandardError
      attr_reader :json_hash
      def initialize(json_hash=nil, message_prefix=self.class.to_s)
        super(message_prefix + ":" + json_hash[0]["message"])
        @json_hash = json_hash
      end
    end

    class CommandError < ResponseError
      def initialize(hash)
        super(hash, "Command Error")
      end
    end
    class AuthenticationError < ResponseError
      def initialize(hash)
        super(hash, "Authentication Error")
      end
    end
    class ServerError < ResponseError
      def initialize(hash)
        super(hash, "Server Error")
      end
    end


    def initialize(common_opts, merge_opts={})
      @common_opts = common_opts
      @merge_opts = merge_opts.dup
    end

    def request(options={})
      request_uri = URI.parse(@common_opts[:command_server_uri])
      @merge_opts[:timestamp] = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
      request_uri.path = (request_uri.path.nil? || request_uri.path == '') ? '/' : request_uri.path
      request_uri.query = sign_query(build_escaped_query(options.merge(@merge_opts)))

      res = Net::HTTP.get_response(request_uri)
      hash = JSON.parse(res.body)
      if res.is_a?(Net::HTTPSuccess)
        # 
      else
        case res.code
        when '404'
          raise CommandError.new(hash)
        when '403'
          raise AuthenticationError.new(hash)
        when '500'
          raise ServerError.new(hash)
        else
          fail "Unknown HTTP Error Code: #{res.code}: #{res.message}"
        end
      end

      if @common_opts[:json_print]
        require 'pp'
        puts "Response for: #{request_uri.to_s}"
        pp hash
      end

      hash
    end

    private
    def sign_query(query_str)
      require 'openssl'
      require 'base64'

      hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, @common_opts[:public_key], query_str)
      (query_str + "&signature=" + CGI::escape(Base64.encode64(hash).gsub(/\+/, "").gsub(/\n/, "").to_s))
    end


    def build_escaped_query(hash)
      hash.map { |k,v|
        CGI::escape(k.to_s) + '=' + CGI::escape(v.to_s)
      }.join('&')
    end

  end


  module Cli
    module Subcommand
      class CommandArgumentError < StandardError; end

      def self.included(klass)
        klass.class_eval {
          class << self
            def command_name(name=nil)
              @command_name = name if name
              @command_name ||= Util.snake_case(self.to_s.split('::').last)
            end

            def summary(str=nil)
              @summary = str if str
              @summary
            end
          end
        }
      end

      def parse(args)
      end

      def run(requester)
      end

      def print_result()
      end

      
      def create_parser(args, &blk)
        parser = OptionParser.new { |opts|
          blk.call(opts) if blk
        }
        parser.order!(args)
        parser
      end

    end
  end
end

class Wakame::Cli::Subcommand::LaunchCluster
  include Wakame::Cli::Subcommand

  command_name 'launch_cluster'
  summary "Start up the cluster"

  def parse(args)
    create_parser(args) {|opts|
      opts.banner = "Usage: launch_cluster"
      opts.separator ""
      opts.separator "options:"
    }
  end

  def run(requester)
    requester.request()
  end

end

class Wakame::Cli::Subcommand::ShutdownCluster
  include Wakame::Cli::Subcommand

  summary "Shutdown the cluster"

  def parse(args)
    create_parser(args) {|opts|
      opts.banner = "Usage: shutdown_cluster"
      opts.separator ""
      opts.separator "options:"
    }
  end

  def run(requester)
    requester.request()
  end
end

class Wakame::Cli::Subcommand::Status
  include Wakame::Cli::Subcommand

  summary "Show summary status across the cluster"

  STATUS_TMPL = <<__E__
<%- if cluster -%>
Cluster : <%= cluster["name"].to_s %> (<%= cluster_status_msg(cluster["status"]) %>)
<%- cluster["resources"].keys.each { |res_id|
  resource = body["resources"][res_id]
-%>
  <%= resource["class_type"] %> : <current=<%= resource["instance_count"] %> min=<%= resource["min_instances"] %>, max=<%= resource["max_instances"] %><%= resource["require_agent"] ? "" : ", AgentLess" %>>
  <%- resource["services_ref"].each { |svc| -%>
     <%= svc["id"] %> (<%= svc_status_msg(svc["status"]) %>:<%= monitor_status_msg(svc["monitor_status"]) %>)
  <%- } -%>
<%- } -%>
<%- if cluster["services"].size > 0  -%>

Instances (<%= cluster["services"].size %>):
  <%- cluster["services"].keys.each { |svc_id| 
    svc = body["services"][svc_id]
  -%>
  <%= svc_id %> : <%= svc["resource_ref"]["class_type"] %> (<%= svc_status_msg(svc["status"]) %>:<%= monitor_status_msg(svc["monitor_status"]) %>)
    <%- if svc["agent_ref"] -%>
    On VM: <%= svc["agent_ref"]["id"] %>
    <%- end -%>
  <%- } -%>
<%- end -%>
<%- if cluster["cloud_hosts"].size > 0 -%>

Cloud Host (<%= cluster["cloud_hosts"].size %>):
  <%- cluster["cloud_hosts"].keys.each { |host_id| 
    cloud_host = body["cloud_hosts"][host_id]
  -%>
  <%= host_id %> : <% if cloud_host["agent_id"] %>bind to <%= cloud_host["agent_id"] %><% end %>
    <%- assigned_svcs = body['services'].values.find_all{|data| data['cloud_host_id'] == host_id } -%>
    <%- if assigned_svcs.size > 0 -%>
    Assigned: <%= body['services'].values.find_all{|data| data['cloud_host_id'] == host_id }.map{|data| data['resource_ref']['class_type'] }.join(', ')  %>
    <%- end -%>
  <%- } -%>
<%- end -%>
<%- else # if cluster -%>
Cluster: 
  No cluster data is loaded in master. (Run import_cluster_config first)
<%- end # if cluster -%>
<%- if agent_pool && agent_pool["group_active"].size > 0 -%>

Agents (<%= agent_pool["group_active"].size %>):
  <%- agent_pool["group_active"].each { |agent_id|
  a = body["agents"][agent_id]
  -%>
  <%= a["id"] %> : <%= a["vm_attr"]["private_dns_name"] %>, <%= a["vm_attr"]["dns_name"] %>, <%= (Time.now - Time.parse(a["last_ping_at"])).to_i %> sec(s), placement=<%= a["vm_attr"]["aws_availability_zone"] %> (<%= agent_status_msg(a["status"]) %>)
   <%- if a["reported_services"].size > 0 && !cluster["services"].empty? -%>
    Services (<%= a["reported_services"].size %>): <%= a["reported_services"].keys.collect{ |svc_id|
                body['services'][svc_id].nil? ? 'Unknown:' + svc_id[0,5] + '...' :  body["services"][svc_id]["resource_ref"]["class_type"]
              }.join(', ') %>
   <%- end -%>
  <%- } -%>
<%- else -%>

Agents (0):
  None of agents are observed.
<%- end -%>
__E__

  SVC_STATUS_MSG={
    Wakame::Service::STATUS_TERMINATE=>'Terminated',
    Wakame::Service::STATUS_INIT=>'Initialized',
    Wakame::Service::STATUS_OFFLINE=>'Offline',
    Wakame::Service::STATUS_ONLINE=>'Online',
    Wakame::Service::STATUS_UNKNOWN=>'Unknown',
    Wakame::Service::STATUS_FAIL=>'Fail',
    Wakame::Service::STATUS_STARTING=>'Starting...',
    Wakame::Service::STATUS_STOPPING=>'Stopping...',
    Wakame::Service::STATUS_RELOADING=>'Reloading...',
    Wakame::Service::STATUS_MIGRATING=>'Migrating...',
    Wakame::Service::STATUS_ENTERING=>'Entering...',
    Wakame::Service::STATUS_QUITTING=>'Quitting...',
    Wakame::Service::STATUS_RUNNING=>'Running'
  }

  SVC_MONITOR_STATUS_MSG={
    Wakame::Service::STATUS_OFFLINE=>'Offline',
    Wakame::Service::STATUS_ONLINE=>'Online',
    Wakame::Service::STATUS_UNKNOWN=>'Unknown',
    Wakame::Service::STATUS_FAIL=>'Fail'
  }

  AGENT_STATUS_MSG={
    Wakame::Service::Agent::STATUS_END     => 'Terminated',
    Wakame::Service::Agent::STATUS_INIT    => 'Initialized',
    Wakame::Service::Agent::STATUS_OFFLINE => 'Offline',
    Wakame::Service::Agent::STATUS_ONLINE  => 'Online',
    Wakame::Service::Agent::STATUS_UNKNOWN => 'Unknown',
    Wakame::Service::Agent::STATUS_TIMEOUT => 'Timedout',
    Wakame::Service::Agent::STATUS_RUNNING => 'Running',
    Wakame::Service::Agent::STATUS_REGISTERRING => 'Registerring...',
    Wakame::Service::Agent::STATUS_TERMINATING  => 'Terminating...'
  }

  CLUSTER_STATUS_MSG={
    Wakame::Service::ServiceCluster::STATUS_OFFLINE=>'Offline',
    Wakame::Service::ServiceCluster::STATUS_ONLINE=>'Online',
    Wakame::Service::ServiceCluster::STATUS_PARTIAL_ONLINE=>'Partial Online'
  }

  def parse(args)
    @params = {}
    create_parser(args){|opts|
      opts.banner = "Usage: status"
      #opts.separator ""
      #opts.separator "options:"
    }
  end

  def run(requester)
    @res = requester.request(@params)
  end

  def print_result()
    require 'time'
    body = @res[1]["data"]
    map_ref_data(body)

    cluster = body["cluster"]
    agent_pool = body["agent_pool"]
    puts ERB.new(STATUS_TMPL, nil, '-').result(binding)
  end

  private
  def svc_status_msg(stat)
    SVC_STATUS_MSG[stat.to_i] || "Unknown Code: #{stat}"
  end

  def monitor_status_msg(stat)
    SVC_MONITOR_STATUS_MSG[stat.to_i] || "Unknown Code: #{stat}"
  end

  def agent_status_msg(stat)
    AGENT_STATUS_MSG[stat.to_i] || "Unknown Code: #{stat}"
  end

  def cluster_status_msg(stat)
    CLUSTER_STATUS_MSG[stat.to_i] || "Unknown Code: #{stat}"
  end

  def map_ref_data(body)
    # Create reference for ServiceInstance to assciated object.(1:1)
    body["services"].each { |k,v|
      v["resource_ref"] = body["resources"][v["resource_id"]]
      v["cloud_host_ref"] = body["cloud_hosts"][v["host_id"]]
      if v["cloud_host_ref"]
        v["agent_ref"] = body["agents"][v["cloud_host_ref"]["agent_id"]]
      end
    }

    # Create reference for Resource object to ServiceInstance array. (1:N)
    body["resources"].each { |res_id,v|
      v["services_ref"] = body["services"].values.find_all{|v| v["resource_id"] == res_id }.map{|v| v}
    }
  end
end

class Wakame::Cli::Subcommand::ActionStatus
  include Wakame::Cli::Subcommand

  ACTION_STATUS_TMPL= <<__E__
Running Actions : <%= status.size %> action(s)
<%- if status.size > 0 -%>
<%- status.each { |id, j| -%>
JOB <%= id %> :
  start : <%= j["created_at"] %>
  <%= tree_subactions(j["root_action"]) %>
<%- } -%>
<%- end -%>
__E__

  def parse(args)
    @params = {}
    cmd = create_parser(args){|opts|
      opts.banner = "Usage: action_status"
      #opts.separator ""
      #opts.separator "options:"
    }
  end

  def run(requester)
    @res = requester.request()
  end

  def print_result
    if @res[1]["data"].nil?
      abort( @res[0]["message"] )
    else
      status = @res[1]['data']
      puts ERB.new(ACTION_STATUS_TMPL, nil, '-').result(binding)
    end
  end

  private
  def tree_subactions(root, level=0)
    str= ("  " * level) + "#{root["type"]} (#{root["status"]})"
    unless root["subactions"].nil?
      root["subactions"].each { |a|
        str << "\n  "
        str << tree_subactions(a, level + 1)
      }
    end
    str
  end
end

class Wakame::Cli::Subcommand::PropagateService
  include Wakame::Cli::Subcommand

  def parse(args)
    @params = {}
    create_parser(args) {|opts|
      opts.banner = 'Usage: propagate_service [options] "Service ID"'
      opts.separator('Options:')
      opts.on('-h CLOUD_HOST_ID', '--host CLOUD_HOST_ID', String, "Cloud Host ID to be used as template."){ |i| @params["cloud_host_id"] = i }
      opts.on('-n NUMBER', '--number NUMBER', Integer, "Number (>0) to propagate the specified service."){ |i| @params["number"] = i.to_i }
    }
    raise "Unknown Service ID: #{args}" unless args.size > 0
    @params[:service_id] = args.shift
  end

  def run(requester)
    requester.request(@params)
  end

end

class Wakame::Cli::Subcommand::PropagateResource
  include Wakame::Cli::Subcommand

  def parse(args)
    @params = {}
    create_parser(args) {|opts|
      opts.banner = 'Usage: propagate_resource [options] "Resource Name" "Cloud Host ID"'
      opts.separator("  Resource Name: ....")
      opts.separator("  Cloud Host ID: ....")
      opts.separator("  ")
      opts.separator("  Options:")
      opts.on("-n NUMBER", "--number NUMBER", Integer, "Number (>0) to propagate the specified resource."){|i| @params["number"] = i}
    }
    raise "Unknown Resource Name: #{args}" unless args.size > 0
    @params["resource"] = args.shift

    raise "Unknown Cloud Host ID: #{args}" unless args.size > 0
    @params["cloud_host_id"] = args.shift
  end

  def run(requester)
    requester.request(@params)
  end

end

class Wakame::Cli::Subcommand::StopService
  include Wakame::Cli::Subcommand

  def parse(args)
    @params = {}
    create_parser(args) {|opts|
      opts.banner = "Usage: stop_service [options] \"Service ID\""
      opts.separator ""
      opts.separator "options:"
      opts.on("-i INSTANCE_ID", "--instance INSTANCE_ID"){|i| @params[:service_id] = i}
      opts.on("-s SERVICE_NAME", "--service SERVICE_NAME"){|str| @params[:service_name] = str}
      opts.on("-a AGENT_ID", "--agent AGENT_ID"){|i| @params[:agent_id] = i}
    }
    @params
  end

  def run(requester)
    requester.request(@params)
  end

end

class Wakame::Cli::Subcommand::MigrateService
  include Wakame::Cli::Subcommand

  def parse(args)
    @params = {}
    cmd = create_parser(args){|opts|
      opts.banner = "Usage: migrate_service [options] \"Service ID\""
      opts.separator ""
      opts.separator "options:"
      opts.on("-a Agent ID", "--agent Agent ID"){ |i| @params[:agent_id] = i}
    }
    service_id = args.shift || abort("[ERROR]: Service ID was not given")
    @params[:service_id] = service_id
  end

  def run(requester)
    requester.request(@params)
  end

end

class Wakame::Cli::Subcommand::ShutdownVm
  include Wakame::Cli::Subcommand

  def parse(args)
    @params = {}
    cmd = create_parser(args) {|opts|
      opts.banner = "Usage: shutdown_vm [options] \"Agent ID\""
      opts.separator ""
      opts.separator "options:"
      opts.on("-f", "--force"){|str| @params[:force] = "yes"}
    }
    agent_id = args.shift || abort("[ERROR]: Agent ID was not given")
    @params[:agent_id] = agent_id
  end

  def run(requester)
    requester.request(@params)
  end

end

class Wakame::Cli::Subcommand::LaunchVm
  include Wakame::Cli::Subcommand

  def parse(args)
    @params={}
    cmd = create_parser(args) {|opts|
      opts.banner = "Usage: launch_vm"
      opts.separator ""
      opts.separator "options:"
    }
  end

  def run(requester)
    requester.request(@params)
  end

end

class Wakame::Cli::Subcommand::ReloadService
  include Wakame::Cli::Subcommand

  def parse(args)
    @params = {}
    cmd = create_parser(args) {|opts|
      opts.banner = "Usage: ReloadService [options] \"Service ID\""
      opts.separator ""
      opts.separator "options:"
    }
    service_id = args.shift || abort("[ERROR]: Service ID was not given")
    @params[:service_id] = service_id
  end

  def run(requester)
    requester.request(@params)
  end

end

class Wakame::Cli::Subcommand::StartService
  include Wakame::Cli::Subcommand

  def parse(args)
    @params = {}
    cmd = create_parser(args) { |opts|
      opts.banner = "Usage: start_service [options] \"Service ID\""
      opts.separator ""
      opts.separator "options:"
    }
    service_id = args.shift || abort("[ERROR]: Service ID was not given")
    @params[:service_id] = service_id
  end

  def run(requester)
    requester.request(@params)
  end

end

class Wakame::Cli::Subcommand::ImportClusterConfig
  include Wakame::Cli::Subcommand

  def parse(args)
    @params = {}
    cmd = create_parser(args) { |opts|
      opts.banner = "Usage: import_cluster_config"
      opts.separator ""
      opts.separator "options:"
    }
    @params
  end

  def run(requester)
    requester.request(@params)
  end

end

class Wakame::Cli::Subcommand::AgentStatus
  include Wakame::Cli::Subcommand

STATUS_TMPL = <<__E__
Agent :<%= agent["agent_id"]%> load=<%= agent["attr"]["uptime"]%>, <%= (Time.now - Time.parse(agent["last_ping_at"])).to_i%> sec(s), placement=<%= agent["attr"]["availability_zone"]%><%= agent["root_path"] %> (<%= trans_svc_status(agent["status"]) %>)
  Instance ID : <%= agent["attr"]["instance_id"]%>
  AMI ID : <%= agent["attr"]["ami_id"]%>
  Public DNS Name : <%= agent["attr"]["public_hostname"]%>
  Private DNS Name : <%= agent["attr"]["local_hostname"]%>
  Instance Type : <%= agent["attr"]["instance_type"]%>
  Availability Zone : <%= agent["attr"]["availability_zone"]%>

<%- if !agent["services"].nil? && agent["services"].size > 0 -%>
Services (<%= agent["services"].size%>):
  <%- agent["services"].each {|id| -%>
      <%= service_cluster["instances"][id]["instance_id"]%> : <%= service_cluster["instances"][id]["property"]%> (<%= trans_svc_status(service_cluster["instances"][id]["status"])%>)
  <%- } -%>
<%- end -%>
__E__

  SVC_STATUS_MSG={
    Wakame::Service::STATUS_OFFLINE=>'Offline',
    Wakame::Service::STATUS_ONLINE=>'ONLINE',
    Wakame::Service::STATUS_UNKNOWN=>'Unknown',
    Wakame::Service::STATUS_FAIL=>'Fail',
    Wakame::Service::STATUS_STARTING=>'Starting...',
    Wakame::Service::STATUS_STOPPING=>'Stopping...',
    Wakame::Service::STATUS_RELOADING=>'Reloading...',
    Wakame::Service::STATUS_MIGRATING=>'Migrating...',
  }

  def parse(args)
    @params = {}
    blk = Proc.new 
    cmd = create_parser(args) {|opts|
      opts.banner = "Usage: AgentStatus [options] \"Agent ID\""
      opts.separator ""
      opts.separator "options:"
    }
    @params[:agent_id] = args.shift || abort("[ERROR]: Agent ID was not given")
  end

  def run(requester)
    @res = requester.request(@params)
  end

  def print_result(res)
    require 'time'
    agent = @res[1]["data"]["agent_status"]
    service_cluster = res[1]["data"]["service_cluster"]
    puts ERB.new(STATUS_TMPL, nil, '-').result(binding)
  end

  private
  def trans_svc_status(stat)
    SVC_STATUS_MSG[stat]
  end
end

class Wakame::Cli::Subcommand::DeployApplication
  include Wakame::Cli::Subcommand

  def parse(args)
    @params = {}
    cmd = create_parser(args) { |opts|
      opts.banner = "Usage: deploy_application [options] \"Application Name\""
      opts.separator ""
    }
    @params[:app_name] = args.shift || abort("[ERROR]: Application name was not given")
    @params
  end

  def run(requester)
    requester.request(@params)
  end

end

class Wakame::Cli::Subcommand::Actor
  include Wakame::Cli::Subcommand

  summary 'Call actor method on an arbitrary agent.'

  def parse(args)
    @params = {}
    cmd = create_parser(args) { |opts|
      opts.banner = "Usage: actor [options] \"Agent ID\" \"/actor/path\" [\"args\"]"
      opts.separator ""
      opts.separator "options:"
    }
    @params[:agent_id] = args.shift || abort("[ERROR]: Agent ID was not given")
    @params[:path] = args.shift || abort("[ERROR]: Path was not given")
    @params[:args] = args.shift
    @params
  end

  def run(requester)
    requester.request(@params)
  end

end

class Wakame::Cli::Subcommand::ControlService
  include Wakame::Cli::Subcommand

  def parse(args)
    @params = {}
    create_parser(args) {|opts|
      opts.banner = 'Usage: control_service [options] "Resource Name" "Service ID" "Number"'
      opts.separator('Options:')
    }

    raise "Unknown Resource Name: #{args}" unless args.size > 0
    @params["resource"] = args.shift

    raise "Unknown Service ID: #{args}" unless args.size > 0
    @params[:service_id] = args.shift

    raise "Unknown Number: #{args}" unless args.size > 0
    @params[:number] = args.shift.to_i
  end

  def run(requester)
    requester.request(@params)
  end

end
