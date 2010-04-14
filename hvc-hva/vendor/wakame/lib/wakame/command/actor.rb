
class Wakame::Command::Actor
  include Wakame::Command
  include Wakame::Service

  command_name 'actor'

  def run
    agent = Agent.find(params['agent_id'])
    raise "Unknown agent: #{params['agent_id']}" if agent.nil?
    raise "Invalid agent status (Not Online): #{agent.status} #{params['agent_id']}" if agent.status != Agent::STATUS_ONLINE
    raise "Invalid actor path: #{params['path']}" if params['path'].nil? || params['path'] == ''
    if params['args'].is_a? String
      params['args'] = eval(params['args'])
    end

    request = master.actor_request(params['agent_id'], params['path'], *params['args']).request
  end

end
