class GroupsController < ApplicationController
  respond_to :json
  before_filter :system_manager?
  
  # グループ管理初期画面
  def index
    account_uuid = User.primary_account_id(@current_user.uuid)
  end

  # 指定ページのグループ一覧取得  
  def list
   data = {
     :start => params[:start].to_i - 1,
     :limit => params[:limit]
   }
   @group = Account.list(data)
   respond_with(@group[0],:to => [:json])
  end

  # 指定UUIDのグループ情報取得  
  def show
    uuid = params[:id]
    @group = Account.show(uuid)
    respond_with(@group,:to => [:json])
  end

  # 指定UUIDのグループ情報削除  
  def destroy
    uuid = params[:id]
    @group = Account.delete_account(uuid)
    render :json => @group    
  end
  
  # グループ新規作成
  def create_group
    data = {
      :name => params[:name],
      :description => params[:description],
    }

    @group = Account.insert_account(data)
    render :json => @group 
  end

  # 指定UUIDのグループ情報更新
  def edit_group
    data = {
      :name => params[:name],
      :description => params[:description],
    }
    logger.debug(params[:description])
    @group = Account.edit_account(data)
    render :json => @group 
  end
  
  # 全グループの一覧を取得
  def show_groups
    @group = Account.list
    respond_with(@group[0],:to => [:json])
  end

  # グループからユーザへの紐付け
  def link_group_users
    # 選択されているグループのUUID
    @group_uuid = params[:id]
    # 画面から受け取った選択ユーザ
    @arg_sel_users = params[:sel_user_uuid]

    # グループ情報取得(DB)
    @group = Account.sel(@group_uuid)
    @group_id = @group[:id]
    
    # DB よりアカウント-ユーザ リンク情報一覧を取得(列 uuid(user),flg(リンク存在時 1),id(user,PKEY))
    @relation_list = User.get_list(@group_uuid)
    # 画面とDB情報を比較(画面は選択されたユーザUUIDのみ送信）
    add_links = []
    j = 0
    del_links = []
    k = 0
    for i in 0..(@relation_list.size - 1)
      #  DB情報を取り出し
      @row = @relation_list[i]
      sel_flg = false;
      #  ループ対象のDBレコードのユーザUUIDが画面で選択されているかどうかをフラグにセット
      @arg_sel_users.each_value {
        |value| if @row[:uuid] == value then
                  sel_flg = true
                  break
                end
      }
      # もともとリンク存在し、画面選択が解除された場合はリンク削除 
      if @row[:flg] == 1 and sel_flg == false then
        logger.debug("delete relation #{@group_uuid}:#{@group_id} to #{@row[:uuid]}:#{@row[:id]} ")
        j += 1
        del_links[j] = { :user_id => @row[:id] , :group_id => @group_id }
      # もともとリンクなく、画面選択された場合はリンク追加
      elsif @row[:flg] != 1 and sel_flg == true then
        logger.debug("add relation #{@group_uuid}:#{@group_id} to #{@row[:uuid]}:#{@row[:id]} ")
        k += 1
        add_links[k] = { :user_id => @row[:id] , :group_id => @group_id }
      end
    end
    Account.change_relations(add_links,del_links)

    @group = Account.show(@group_uuid)
    render :json => @group
  end
  
end
