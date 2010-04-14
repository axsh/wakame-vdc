class Wakame::Command::TerminateInstance
  include Wakame::Command

  command_name 'terminate_instance'

  def run
    trigger_action(Wakame::Actions::TerminateInstance.new(@options))
  end
end
