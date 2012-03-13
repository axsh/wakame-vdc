# マシンイメージ用vdc-manageコマンド発行
class ImageManage < VdcManage
   # 対象（第一パラメータ）
   def self.get_name
       "image"
   end

   # uuidのプレフィクス
   def self.get_prefix
       "wmi"
   end

   # ノードIDのプレフィクス（ノードでない）
   def self.get_nodeid_prefix
       ""
   end

   # 強制指定なし
   def self.get_force_param
       ""
   end

   # 作成コマンド
   def self.add_local(options,id,image_location)
     d_options = [ "account-id" , "md5sum" , "arch" , "is-public" , "description" , "uuid" ]
     required ="local #{image_location}"
     exec("add",d_options,options,required)
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
