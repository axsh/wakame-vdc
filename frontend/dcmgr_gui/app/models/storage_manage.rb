# ストレージプール用vdc-manageコマンド発行
class StorageManage < VdcManage
   # 対象（第一パラメータ）
   def self.get_name
       "storage"
   end

   # uuidのプレフィクス
   def self.get_prefix
       "sn"
   end

   # ノードIDのプレフィクス
   def self.get_nodeid_prefix
       "sta"
   end

   # 強制指定
   def self.get_force_param
       "--force"
   end

   # 作成コマンド
   def self.add(options,id)
     # 指定可能オプション
     d_options = [ "account-id" , "disk-space" , "ipaddr" , "base-path" , "snapshot-base-path" , "transport-type" , "storage-type" , "uuid" ]
     exec("add",d_options,options,id)
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
