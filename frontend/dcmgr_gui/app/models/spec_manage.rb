# -*- coding: utf-8 -*-
# インスタンススペック用vdc-manageコマンド発行
class SpecManage < VdcManage
   # 対象（第一パラメータ）
   def self.get_name
       "spec"
   end

   # uuidのプレフィクス
   def self.get_prefix
       "is"
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
   def self.add(options)
     d_options = [ "account-id" , "cpu-cores" , "memory-size" , "arch" , "hypervisor" , "uuid" , "quota-weight" ]
     exec("add",d_options,options,"")
   end

   # 更新
   def self.modify(options,id)
     d_options = [ "account-id" , "cpu-cores" , "memory-size", "quota-weight" ]
     exec("modify",d_options,options,id)
   end

   # 削除コマンド
   def self.del(id)
     exec("del","","",id)
   end

   # 追加ドライブ作成
   def self.add_drive(uuid,type,name,options)
     d_options = [ "size" , "index" ]
     required ="#{uuid} #{type} #{name}"
     exec("adddrive",d_options,options,required)
   end

   # 追加ドライブ更新
   def self.modify_drive(uuid,name,options)
     d_options = [ "snapshot-id" , "size" , "index" ]
     required ="#{uuid} #{name}"
     exec("modifydrive",d_options,options,required)
   end

   # 追加ドライブ削除
   def self.del_drive(uuid,name)
     required ="#{uuid} #{name}"
     exec("deldrive","","",required)
   end

   # VIF追加
   def self.add_vif(uuid,name,options)
     d_options = [ "bandwidth" , "index" ]
     required ="#{uuid} #{name}"
     exec("addvif",d_options,options,required)
   end

   # VIF更新
   def self.modify_vif(uuid,name,options)
     d_options = [ "bandwidth" , "index" ]
     required ="#{uuid} #{name}"
     exec("modifyvif",d_options,options,required)
   end

   # VIF削除
   def self.del_vif(uuid,name)
     required ="#{uuid} #{name}"
     exec("delvif","","",required)
   end

   # 情報取得
   def self.show
     info("show")
   end
end
