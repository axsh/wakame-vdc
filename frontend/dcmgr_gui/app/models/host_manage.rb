# ホストプール用vdc-manageコマンド発行
class HostManage < VdcManage
   # 対象（第一パラメータ）
   def self.get_name
       "host"
   end

   # uuidのプレフィクス
   def self.get_prefix
       "hn"
   end

   # ノードIDのプレフィクス
   def self.get_nodeid_prefix
       "hva"
   end

   # 強制指定
   def self.get_force_param
       "--force"
   end

   # 作成コマンド
   def self.add(options,id)
     d_options = [ "account-id" , "cpu-cores" , "memory-size" , "arch" , "hypervisor" , "uuid" , "name" ]
     exec("add",d_options,options,id)
   end

   # 更新
   def self.modify(options,id)
     d_options = [ "account-id" , "cpu-cores" , "memory-size", "name" ]
     exec("modify",d_options,options,id)
   end

   # 削除コマンド
   def self.del(id)
     exec("del","","",id)
   end

   # 情報取得
   def self.show
     info("show")
   end
end
