class ResourceController < ApplicationController
  def index
    # 直接URL入力のガード（システムアカウントでないときはhomeへリダイレクト）
    account_uuid = User.primary_account_id(@current_user.uuid)
    if account_uuid != '00000000' then
      redirect_to :controller => 'home',
                  :action => 'index'
    end
  end
end
