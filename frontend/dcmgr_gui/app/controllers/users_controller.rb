class UsersController < ApplicationController
  respond_to :json
  
  # ユーザ管理初期画面
  def index
    # 直接URL入力のガード（システムアカウントでないときはhomeへリダイレクト）
    account_uuid = User.primary_account_id(@current_user.uuid)
    if account_uuid != '00000000' then
      redirect_to :controller => 'home',
                  :action => 'index'
    end
  end
  
  # 指定ページのユーザ一覧取得
  def list
   data = {
     :start => params[:start].to_i - 1,
     :limit => params[:limit]
   }
   @user = User.list(data)
   respond_with(@user[0],:to => [:json])
  end

  # 指定UUIDのユーザ情報取得  
  def show
    uuid = params[:id]
    @user = User.show(uuid)
    respond_with(@user,:to => [:json])
  end
  
  # 指定UUIDのユーザ情報削除
  def destroy
    uuid = params[:id]
    @user = User.delete_user(uuid)
    render :json => @user    
  end
  
  # ユーザ新規作成
  def create_user
    password = encrypted_password = User.encrypt_password(params[:password])
    data = {
      :login_id => params[:login_id],
      :name => params[:name],
      :primary_account_id => params[:primary_account_id],
      :locale => params[:locale],
      :time_zone => params[:time_zone],
      :password => password
    }
    cnt = User.count(params[:login_id])
    if cnt != 0 then
      logger.debug("User.count:" + cnt.to_s)
      raise UsersController::DuplicateLoginIDError
    end

    @user = User.insert_user(data)
    render :json => @user 
  end

  # 指定UUIDのユーザ情報更新
  def edit_user
    data = {
      :login_id => params[:login_id],
      :name => params[:name],
      :locale => params[:locale],
      :time_zone => params[:time_zone]
    }

    @user = User.edit_user(data)
    render :json => @user 
  end

  # 全ユーザの一覧を取得  
  def show_users
    @user = User.list
    respond_with(@user[0],:to => [:json])
  end
  
  # ユーザからグループ（アカウント）への紐付け
  def link_user_groups
    # 選択されているユーザのUUID
    @user_uuid = params[:id]
    # 画面から受け取った既定グループと選択グループ
    @arg_pr_group = params[:pr_group_uuid]
    @arg_sel_groups = params[:sel_group_uuid]

    # ユーザ情報取得(DB)
    @user = User.sel(@user_uuid)
    @user_id = @user[:id]
    @db_pr_group = @user[:primary_account_id]

    # 画面とDBが異なれば、DB更新
    if @arg_pr_group != @db_pr_group then
      @user = User.update_pr_user(@user_uuid,@arg_pr_group)
    end
    
    # DB よりユーザ-アカウント リンク情報一覧を取得(列 uuid(account),flg(リンク存在時 1),id（account,PKEY))
    @relation_list = Account.get_list(@user_uuid)
    # 画面とDB情報を比較(画面は選択されたアカウントUUIDのみ送信）
    add_links = []
    j = 0
    del_links = []
    k = 0
    for i in 0..(@relation_list.size - 1)
      #  DB情報を取り出し
      @row = @relation_list[i]
      sel_flg = false;
      #  ループ対象のDBレコードのアカウントUUIDが画面で選択されているかどうかをフラグにセット
      @arg_sel_groups.each_value {
        |value| if @row[:uuid] == value then
                  sel_flg = true
                  break
                end
      }
      # もともとリンク存在し、画面選択が解除された場合はリンク削除 
      if @row[:flg] == 1 and sel_flg == false then
        logger.debug("delete relation #{@user_uuid}:#{@user_id} to #{@row[:uuid]}:#{@row[:id]} ")
        j += 1
        del_links[j] = { :user_id => @user_id , :group_id => @row[:id] }
      # もともとリンクなく、画面選択された場合はリンク追加
      elsif @row[:flg] != 1 and sel_flg == true then
        logger.debug("add relation #{@user_uuid}:#{@user_id} to #{@row[:uuid]}:#{@row[:id]} ")
        k += 1
        add_links[k] = { :user_id => @user_id , :group_id => @row[:id] }
      end
    end
    Account.change_relations(add_links,del_links)    

    @user = User.show(@user_uuid)
    render :json => @user
  end

  def duplicate_login_id
      response.status = 200
      response.body = 'Duplicated User Login ID.'
  end
end
