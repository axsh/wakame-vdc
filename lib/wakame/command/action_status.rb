
class Wakame::Command::ActionStatus
  include Wakame::Command

  def run
    walk_subactions = proc { |a, level|
      res = a.dump_attrs
      unless a.subactions.empty?
        res[:subactions] = a.subactions.collect { |s|
          walk_subactions.call(s, level + 1)
        }
      end
      res
    }

    Wakame::StatusDB.barrier {
      result = {}

      master.action_manager.active_jobs.each { |id, v|
        result[id]={}
        (v.keys - [:root_action]).each { |k|
          result[id][k]=v[k]
        }
        result[id][:root_action] = walk_subactions.call(v[:root_action], 0)

      }
      @status = result
      @status
    }
  end
end
