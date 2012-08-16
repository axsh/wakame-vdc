class DcNetworksController < ApplicationController
  respond_to :json
  include Util
  
  def allows_new_networks
    catch_error do
      @result = Hijiki::DcmgrResource::DcNetwork.list
      @result[0].results.select!{ |object| object.allow_new_networks }
      
      respond_with(@result[0],:to => [:json])
    end
  end
end
