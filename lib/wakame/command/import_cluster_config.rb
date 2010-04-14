
class Wakame::Command::ImportClusterConfig
  include Wakame::Command

  def run
    Wakame::StatusDB.barrier {
      master.cluster_manager.load_config_cluster
    }
  end
end
