class KeypairsController < ApplicationController
  respond_to :json,:except => [:create,:prk_download]
  
  def index
  end
  
  def list
   data = {
     :start => params[:start].to_i - 1,
     :limit => params[:limit]
   }
   @ssh_key_pair = DcmgrResource::SshKeyPair.list(data)
   respond_with(@ssh_key_pair[0],:to => [:json])
  end
  
  def show
    uuid = params[:id]
    @ssh_key_pair = DcmgrResource::SshKeyPair.show(uuid)
    respond_with(@ssh_key_pair,:to => [:json])
  end
  
  def destroy
    name = params[:id]
    @ssh_key_pair = DcmgrResource::SshKeyPair.destroy(name)
    render :json => @ssh_key_pair    
  end
  
  def create_ssh_keypair
    data = {
      :download_once => params[:download_once]
    }
    
    @ssh_key_pair = DcmgrResource::SshKeyPair.create(data)
    @filename = @ssh_key_pair.uuid + ".pem"
    
    send_data(@ssh_key_pair.private_key,{
              :filename => @filename,
              :type => 'application/pgp-encrypted',
              :status => 200
            })
  end
  
  def show_keypairs
    @ssh_key_pair = DcmgrResource::SshKeyPair.list
    respond_with(@ssh_key_pair[0],:to => [:json])
  end
  
  def total
   total_resource = DcmgrResource::SshKeyPair.total_resource
   render :json => total_resource
  end
  
  def prk_download
    uuid = params[:id]
    @ssh_key_pair = DcmgrResource::SshKeyPair.show(uuid)
    @filename = @ssh_key_pair['uuid'] + ".pem"
    send_data(@ssh_key_pair['private_key'],{
              :filename => @filename,
              :type => 'application/pgp-encrypted',
              :status => 200
            })
  end
end
