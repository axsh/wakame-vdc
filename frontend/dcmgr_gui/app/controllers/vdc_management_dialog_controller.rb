require "yaml"

class VdcManagementDialogController < ApplicationController
  layout false
  before_filter :system_manager?

  def create_hostnode
  end

  # ホストノード作成時
  def create_hostnode_exec
    data = {
      "account-id" => params[:account_id],
      "cpu-cores" => params[:cpu_cores],
      "memory-size" => params[:memory_size],
      "arch" => params[:arch],
      "hypervisor" => params[:hypervisor],
      "uuid" => "hn-" + params[:hostid],
    }

    # 指定されている場合のみ追加
    if params[:name] != "" then
      data.store("name",params[:name])
    end

    # vdc-manegeを実行して、生成処理
    ret = HostManage.add(data,params[:hostid])
    logger.debug("return:#{ret}")
    data = { "result" => ret }

    render :json => data
  end

  def edit_and_delete_hostnode
  end

  # ホストノード一覧取得(特定グループの全情報）
  def get_hn_list
    # カレントのグループが、指定グループでない場合、HTTPヘッダのグループを変更
    user = User.sel(@current_user.uuid)
    save_account_uuid = "a-%s" % user[:primary_account_id]
    account_uuid = params[:account_id]

    logger.debug("save_account_uuid:#{save_account_uuid} account_uuid:#{account_uuid}")
    if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(account_uuid)
    end

    data = {
      :start => 0,
      :limit => 1000
    }

    # WebAPI経由でホストプールの一覧情報を取得
    host_pools = DcmgrResource::HostPool.list(data)
    logger.debug(host_pools[0])  

    if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(save_account_uuid)
    end
    
    render  :json => host_pools[0]     
  end

  # ホストノード情報更新
  def edit_hostnode_exec
    data = {
      "account-id" => params[:account_id],
      "cpu-cores" => params[:cpu_cores],
      "memory-size" => params[:memory_size],
     }
    # 指定されている場合のみ追加
    if params[:name] != "" then
      data.store("name",params[:name])
    end

    # vdc-manegeを実行して、更新処理
    ret = HostManage.modify(data,params[:uuid])
    logger.debug("return:#{ret}")
    data = { "result" => ret }
    render :json => data
  end

  # ホストノード削除処理
  def delete_hostnode_exec
    uuid = params[:id]
    ret = HostManage.del(uuid)
    logger.debug("return:#{ret}")
    data = { "result" => ret }
    render :json => data
  end

  # ストレージノード作成処理
  def create_storagenode_exec
    data = {
      "account-id" => params[:account_id],
      "uuid" => "sn-" + params[:storageid],
      "disk-space" => params[:disk_space],
      "ipaddr" => params[:ipaddr],
      "base-path" => params[:base_path],
      "snapshot-base-path" => params[:snapshot_base_path],
      "transport-type" => params[:transport_type],
      "storage-type" => params[:storage_type]
    }

    # vdc-manegeを実行して、生成処理
    ret = StorageManage.add(data,params[:storageid])
    logger.debug("return:#{ret}")
    data = { "result" => ret }
    render :json => data
  end

  # ストレージノード削除ダイアログ出力処理
  def delete_storagenode
  end

  # ストレージノード一覧処理(特定グループの全情報）
  def get_sn_list
    # カレントのグループが、指定グループでない場合、HTTPヘッダのグループを変更
    user = User.sel(@current_user.uuid)
    save_account_uuid = "a-%s" % user[:primary_account_id]
    account_uuid = params[:account_id]

    logger.debug("save_account_uuid:#{save_account_uuid} account_uuid:#{account_uuid}")
    if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(account_uuid)
    end

    data = {
      :start => 0,
      :limit => 1000
    }

    # WebAPI経由でストレージプールの一覧情報を取得
    storage_pools = DcmgrResource::StoragePool.list(data)
    logger.debug(storage_pools[0])  

    if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(save_account_uuid)
    end
    
    render  :json => storage_pools[0]     
  end

  # ストレージノード削除処理
  def delete_storagenode_exec
    uuid = params[:id]
    ret = StorageManage.del(uuid)
    logger.debug("return:#{ret}")
    data = { "result" => ret }
    render :json => data
  end

  def create_spec
  end

  # インスタンススペック生成処理
  def create_spec_exec
    data = {
      "account-id" => params[:account_id],
      "cpu-cores" => params[:cpu_cores],
      "memory-size" => params[:memory_size],
      "arch" => params[:arch],
      "hypervisor" => params[:hypervisor],
      "uuid" => "is-" + params[:specid],
    }
    if params[:quota_weight] != "" then
      data.store("quota_weight",params[:quota_weight])
    end

    # vdc-manegeを実行して、生成処理
    ret = SpecManage.add(data)
    logger.debug("return:#{ret}")
    data = { "result" => ret }
    render :json => data
  end

  def edit_and_delete_spec
  end

  # インスタンススペック一覧処理(特定グループの全情報）
  def get_is_list
    # カレントのグループが、指定グループでない場合、HTTPヘッダのグループを変更
    user = User.sel(@current_user.uuid)
    save_account_uuid = "a-%s" % user[:primary_account_id]
    account_uuid = params[:account_id]

    logger.debug("save_account_uuid:#{save_account_uuid} account_uuid:#{account_uuid}")
    if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(account_uuid)
    end

    data = {
      :start => 0,
      :limit => 1000
    }

    # WebAPI経由でインスタンススペックの一覧情報を取得
    specs = DcmgrResource::InstanceSpec.list(data)
    logger.debug(specs[0])  

    if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(save_account_uuid)
    end
    
    render  :json => specs[0]     
  end

  # インスタンススペック更新処理
  def edit_spec_exec
    data = {
      "account-id" => params[:account_id],
      "cpu-cores" => params[:cpu_cores],
      "memory-size" => params[:memory_size],
    }
    if params[:quota_weight] != "" then
      data.store("quota_weight",params[:quota_weight])
    end

    # vdc-manageによる更新処理
    ret = SpecManage.modify(data,params[:uuid])
    logger.debug("return:#{ret}")
    data = { "result" => ret }
    render :json => data
  end

  def delete_spec_exec
    uuid = params[:id]
    ret = SpecManage.del(uuid)
    logger.debug("return:#{ret}")
    data = { "result" => ret }
    render :json => data
  end
  
  def additional_drives_and_IFs
  end

  # ドライブ情報の一覧取得処理
  def get_is_drives_list  
    if params[:uuid] != "" and params[:uuid] != nil then
      # カレントのグループが、指定グループでない場合、HTTPヘッダのグループを変更
      user = User.sel(@current_user.uuid)
      save_account_uuid = "a-%s" % user[:primary_account_id]
      account_uuid = params[:account_id]

      logger.debug("save_account_uuid:#{save_account_uuid} account_uuid:#{account_uuid}")
      if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(account_uuid)
      end

      uuid = params[:uuid]
      logger.debug(uuid)

      # WebAPI経由で特定インスタンススペックの詳細情報を取得
      spec = DcmgrResource::InstanceSpec.show(uuid)
      logger.debug(spec.inspect)  
    
      if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(save_account_uuid)
      end

      # 行数と取得ページを引数から取得
      rows = params[:rows].to_i
      page = params[:page].to_i
      # ドライブ情報をYAMLで取り込み
      drives = YAML.load(spec["drives"])
      # 返却情報の最初と最後の行数を計算
      st_row = (page - 1) * rows + 1
      ed_row = st_row + rows
      # 返却配列初期化
      drive = []
      i = 1
      j = 0
      # 取り込んだ全行に関してループ
      drives.each {|k,v|
          logger.debug(v);
          # 対象行を配列に取り込み
          if  (i >= st_row) && (i <= ed_row) then   
              drive[j] = {:id => k,:type =>v[:type],:index => v[:index],:drive_size => v[:size]};
              j += 1
          end;
          i += 1
      }
      # 全レコード数をセット
      totalrecords = i - 1
      # 全ページ数をセット
      totalpage = ((totalrecords - 1) / rows).to_i + 1
      # 返却するハッシュに全情報セット
      result = { :currpage => page,:totalpages =>totalpage,:totalrecords =>totalrecords,:drive_data => drive }       
    else
      # 対象のドライブ情報がない場合
      drive = []
      result = { :currpage => 0,:totalpages =>0,:totalrecords =>0,:drive_data => drive }
    end
    render  :json => result     
  end

  # IF情報の一覧取得処理
  def get_is_vifs_list  
    if params[:uuid] != "" and params[:uuid] != nil then
      # カレントのグループが、指定グループでない場合、HTTPヘッダのグループを変更
      user = User.sel(@current_user.uuid)
      save_account_uuid = "a-%s" % user[:primary_account_id]
      account_uuid = params[:account_id]

      logger.debug("save_account_uuid:#{save_account_uuid} account_uuid:#{account_uuid}")
      if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(account_uuid)
      end

      uuid = params[:uuid]
      logger.debug(uuid)

      # WebAPI経由で特定インスタンススペックの詳細情報を取得
      spec = DcmgrResource::InstanceSpec.show(uuid)
      logger.debug(spec.inspect)  
    
      if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(save_account_uuid)
      end
    
      # 行数と取得ページを引数から取得
      rows = params[:rows].to_i
      page = params[:page].to_i
      # VIF情報をYAMLで取り込み
      vifs = YAML.load(spec["vifs"])
      # 返却情報の最初と最後の行数を計算
      st_row = (page - 1) * rows + 1
      ed_row = st_row + rows
      # 返却配列初期化
      vif = []
      i = 1
      j = 0
      # 取り込んだ全行に関してループ
      vifs.each {|k,v|
          logger.debug(v);
          # 対象行を配列に取り込み
          if  (i >= st_row) && (i <= ed_row) then   
              vif[j] = {:id => k,:bandwidth =>v[:bandwidth],:index => v[:index]};
              j += 1
          end;
          i += 1
      }
      # 全レコード数をセット
      totalrecords = i - 1
      # 全ページ数をセット
      totalpage = ((totalrecords - 1)/ rows).to_i + 1
      # 返却するハッシュに全情報セット
      result = { :currpage => page,:totalpages =>totalpage,:totalrecords =>totalrecords,:vif_data => vif }       
    else
      # 対象のVIF情報がない場合
      vif = []
      result = { :currpage => 0,:totalpages =>0,:totalrecords =>0,:vif_data => vif }
    end
    render  :json => result     
  end

  # ドライブ情報の更新イベント（作成、編集、削除）
  def is_drive_change
    oper = params[:oper]
    case oper
    # 作成処理
    when "add"
      # ドライブサイズ指定時
      data = Hash.new
      if params[:drive_size] != "" then
        data.store("size",params[:drive_size])
      end

      # インデックス番号指定時
      if params[:index] != "" then
        data.store("index",params[:index])
      end

      # vdcマネージのadd_driveサブコマンド実行
      ret = SpecManage.add_drive(params[:uuid],params[:type],params[:id],data)
      logger.debug("return:#{ret}")
      data = { "result" => ret }
    # 編集処理
    when "edit"
      data = Hash.new
      if params[:drive_size] != "" then
        data.store("size",params[:drive_size])
      end

      if params[:index] != "" then
        data.store("index",params[:index])
      end

      ret = SpecManage.modify_drive(params[:uuid],params[:id],data)
      logger.debug("return:#{ret}")
      data = { "result" => ret }
    # 削除処理
    when "del"
      ret = SpecManage.del_drive(params[:uuid],params[:id])
    end
    render :json => data
  end

  # IF情報の更新イベント（作成、編集、削除）
  def is_vif_change
    oper = params[:oper]
    case oper
    when "add"
      # 作成の場合
      data = Hash.new
      if params[:bandwidth] != "" then
        data.store("bandwidth",params[:bandwidth])
      end

      if params[:index] != "" then
        data.store("index",params[:index])
      end

      # vdc-manageにより作成処理
      ret = SpecManage.add_vif(params[:uuid],params[:id],data)
      logger.debug("return:#{ret}")
      data = { "result" => ret }
    when "edit"
      # 編集の場合
      data = Hash.new
      if params[:drive_size] != "" then
        data.store("bandwidth",params[:bandwidth])
      end

      if params[:index] != "" then
        data.store("index",params[:index])
      end

      # vdc-manageにより更新処理
      ret = SpecManage.modify_vif(params[:uuid],params[:id],data)
      logger.debug("return:#{ret}")
      data = { "result" => ret }
    when "del"
      # 削除の場合、vdc-manageによる削除処理
      ret = SpecManage.del_vif(params[:uuid],params[:id])
    end
    render :json => data    
  end

  def create_image
    @machine_image_base_path=DcmgrGui::Application.config.machine_image_base_path
  end

  # md5値を取得
  def get_md5sum
    # リモートホスト内ファイルのmd5を取得するシェルコマンドのパス
    md5cmd = DcmgrGui::Application.config.md5_rpath
    # リモートホスト上のマシンイメージ存在パス
    machine_image_path = DcmgrGui::Application.config.machine_image_base_path
    # コマンド文字列作成
    command_str = "(%s %s %s) 2>&1" % [md5cmd,machine_image_path,params[:image_location]]
    logger.debug(command_str)
    # コマンド実行
    r = `#{command_str}`
    logger.debug(r)
    if $?.exitstatus != 0
      # 実行ステータスが異常
      ret = { "message" => "errmsg_md5sum_failure" ,
              "exitcode" => $?.exitstatus,
              "detail" => r }
    else
        regex = /^([a-z0-9]+)\s+?(\S+)$/
        if r =~ regex then
          # md5値が取得できた場合
          ret = { "message" => "success" ,
              "exitcode" => $?.exitstatus,
              "detail" => $1 }
        else
          # md5値ではない、コマンド出力の場合
          ret = { "message" => "errmsg_md5sum_failure" ,
              "exitcode" => 9999,
              "detail" => r }
        end
    end
    data = { "result" => ret }
    render :json => data
  end

  # マシンイメージの作成処理
  def create_image_exec
    data = {
      "account-id" => params[:account_id],
      "uuid" => "wmi-" + params[:imageid],
      "arch" => params[:arch],
      "description" => params[:description],
      "md5sum" => params[:md5sum]
    }

    # vdc-manegeを実行して、作成処理
    machine_image_path = DcmgrGui::Application.config.machine_image_base_path
    ret = ImageManage.add_local(data,params[:imageid],machine_image_path + "/" + params[:image_location])
    logger.debug("return:#{ret}")
    data = { "result" => ret }
    render :json => data
  end

  def delete_image
  end

  def get_wmi_list
    # カレントのグループが、指定グループでない場合、HTTPヘッダのグループを変更
    user = User.sel(@current_user.uuid)
    save_account_uuid = "a-%s" % user[:primary_account_id]
    account_uuid = params[:account_id]

    logger.debug("save_account_uuid:#{save_account_uuid} account_uuid:#{account_uuid}")
    if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(account_uuid)
    end

    data = {
      :start => 0,
      :limit => 1000
    }

    machine_images = DcmgrResource::Image.list(data)
    logger.debug(machine_images[0])  

    if save_account_uuid != account_uuid then 
        ActiveResource::Connection.set_vdc_account_uuid(save_account_uuid)
    end
    
    render  :json => machine_images[0]     
  end

  def delete_image_exec
    uuid = params[:id]
    ret = ImageManage.del(uuid)
    logger.debug("return:#{ret}")
    data = { "result" => ret }
    render :json => data
  end

end
