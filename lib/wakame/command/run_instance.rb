class Wakame::Command::RunInstance
  include Wakame::Command

  command_name 'run_instance'

  def run
    trigger_action(Wakame::Actions::RunInstance.new(@options))
  end
end
