class KeypairsController < ApplicationController
  respond_to :json,:except => [:create,:prk_download]
  
  def index
  end
  
  def list
   data = {
     :start => params[:start].to_i - 1,
     :limit => params[:limit]
   }
   @ssh_key_pair = Frontend::Models::DcmgrResource::SshKeyPair.list(data)
   respond_with(@ssh_key_pair[0],:to => [:json])
  end
  
  def show
    uuid = params[:id]
    @ssh_key_pair = Frontend::Models::DcmgrResource::SshKeyPair.show(uuid)
    respond_with(@ssh_key_pair,:to => [:json])
  end
  
  def destroy
    name = params[:id]
    @ssh_key_pair = Frontend::Models::DcmgrResource::SshKeyPair.destroy(name)
    render :json => @ssh_key_pair    
  end
  
  def create_ssh_keypair
    data = {
      :name => params[:name],
      :download_once => params[:download_once]
    }
    
    @filename = params[:name] + ".pem"
    @ssh_key_pair = Frontend::Models::DcmgrResource::SshKeyPair.create(data)
    
    send_data(@ssh_key_pair.private_key,{
              :filename => @filename,
              :type => 'application/pgp-encrypted',
              :status => 200
            })
  end
  
end
