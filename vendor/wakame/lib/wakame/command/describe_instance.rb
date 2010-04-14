class Wakame::Command::DescribeInstance
  include Wakame::Command

  command_name 'describe_instance'
  def initialize
    @response = {}
  end

  def run
    active_agents = []
    Wakame::StatusDB.barrier{
      active_agents = Wakame::Models::AgentPool.group_active
    }
    agent = Wakame::Service::Agent.find(active_agents[0])
    hva_ip = agent.id.split('-')
    @response[hva_ip[0]] ={}
    @response[hva_ip[0]][:status] = agent.status
    @response[hva_ip[0]][:instances] = {}
    return_value = master.actor_request(active_agents[0], '/xen/describe_instance').request.wait
    domu_lists = return_value.split("\n")
    domu_lists.shift
    domu_lists.each{ |list|
      list = list.split(' ')
      status = 'running' if list[4] == "r-----" || list[4] == "-b----"
      @response[hva_ip[0]][:instances][:ip] = {
        :uuid => list[0],
        :id =>list[1],
        :memory =>list[2],
        :cpus =>list[3],
        :status => status,
        :time => list[5]
      }
    }
    @response
  end
end
