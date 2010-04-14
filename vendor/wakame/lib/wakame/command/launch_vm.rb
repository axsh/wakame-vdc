
class Wakame::Command::LaunchVm
  include Wakame::Command

  command_name 'launch_vm'

  def run
    inst_id_key = "new_inst_id_" + Wakame::Util.gen_id
    trigger_action(Wakame::Actions::LaunchVM.new(inst_id_key))
  end
end
