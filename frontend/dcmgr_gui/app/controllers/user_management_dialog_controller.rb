require "yaml"

class UserManagementDialogController < ApplicationController
  layout false
  before_filter :system_manager?
  
  # ユーザ作成
  def create_user
    @uuid = ''
    @user_id = ''
    @login_id = ''
    @name = ''
    @password = ''
    @primary_account_id = ''
    @locale = ''
    @time_zone = ''
    @accounts = Account.all
  end
  
  # ユーザ削除
  def delete_user
    @uuid = params[:ids][0]
    logger.debug(@uuid)
    @user = User.sel(@uuid)
    @user_id = @user[:id]
    @login_id = @user[:login_id]
    @name = @user[:name] 
    @password = @user[:password]
    @primary_account_id = @user[:primary_account_id]
    @locale = @user[:locale]
    @time_zone = @user[:time_zone]
  end
 
  # ユーザ編集
  def edit_user
    @uuid = params[:ids][0]
    logger.debug(@uuid)
    @user = User.sel(@uuid)
    @user_id = @user[:id]
    @login_id = @user[:login_id]
    @name = @user[:name] 
    @password = @user[:password]
    @primary_account_id = @user[:primary_account_id]
    @locale = @user[:locale]
    @time_zone = @user[:time_zone]
    @accounts = Account.all
  end

  # グループ編集
  def edit_group
    @uuid = params[:ids][0]
    @account = Account.sel(@uuid)
    @name = @account[:name]
    @description = @account[:description]
  end

  # グループ削除
  def delete_group
    @uuid = params[:ids][0]
    @account = Account.sel(@uuid)
    @name = @account[:name]
    @description = @account[:description]
  end

  # グループへのリンク（ユーザ画面より）
  def link_group
    @user_uuid = params[:ids][0]
    @user = User.sel(@user_uuid)
    @user_name = @user[:name]
    @login_id = @user[:login_id]
    @pr_account = @user[:primary_account_id]

    @groups = Account.order_all
    logger.debug(@groups.size)
    # 以下の結果（全グループのuuid,特定ユーザの所属フラグ（1:所属）　ただし論理削除考慮）
    # SELECT a.uuid,b.flg,a.id 
    #   from accounts a LEFT OUTER JOIN (
    #                     SELECT accounts.uuid,1 AS flg 
    #                       FROM accounts,users,users_accounts 
    #                       WHERE accounts.id = users_accounts.account_id AND 
    #                         users.id = users_accounts.user_id AND 
    #                         users.uuid = ? AND 
    #                         accounts.is_deleted = 0
    #                   ) b ON a.uuid = b.uuid 
    #   WHERE is_deleted = 0 
    #   ORDER BY uuid   
    # Place holder = user_uuid
    @check_list = Account.get_list(@user_uuid)
    # ラジオボタン、チェックボックスの初期値の配列
    @radio_sel = []
    @check_sel = []
    # 全グループのループ
    for i in 0..(@check_list.size - 1)
      @row = @check_list[i]
      @row.each{ |key,value| logger.debug("[#{key}] = [#{value}]") }
      # ディフォルトグループのラジオボタンをON
      if  @pr_account == @row[:uuid] then
        @radio_sel[i] = true
      else
        @radio_sel[i] = false
      end
      logger.debug("radio_sel[#{i}]= #{@radio_sel[i]}" )
      # 関連するチェックBOXをON
      if  @row[:flg] == 1 then
        @check_sel[i] = true
      else
        @check_sel[i] = false
      end
      logger.debug("check_sel[#{i}]= #{@check_sel[i]}" )
    end
  end

  # ユーザへのリンク（グループ管理画面より）
  def link_user
    @group_uuid = params[:ids][0]
    @group = Account.sel(@group_uuid)
    @name = @group[:name]
    @description = @group[:description]

    @users = User.order_all
    logger.debug(@users.size)
    # 以下の結果（全ユーザのuuid,特定グループへの所属フラグ（1:所属）　ただし論理削除考慮）
    # SELECT a.uuid,b.flg,a.id 
    #   from users a LEFT OUTER JOIN (
    #                  SELECT users.uuid,1 AS flg 
    #                    FROM accounts,users,users_accounts 
    #                      WHERE accounts.id = users_accounts.account_id AND 
    #                        users.id = users_accounts.user_id AND 
    #                        accounts.uuid = ? AND accounts.is_deleted = 0
    #                ) b ON a.uuid = b.uuid 
    #   ORDER BY uuid
    # Place holder = account_uuid
    @check_list = User.get_list(@group_uuid)
    # チェックボックスの初期値の配列
    @check_sel = []
    for i in 0..(@check_list.size - 1)
      @row = @check_list[i]
      # 関連するチェックBOXをON
      if  @row[:flg] == 1 then
        @check_sel[i] = true
      else
        @check_sel[i] = false
      end
    end
  end

end
