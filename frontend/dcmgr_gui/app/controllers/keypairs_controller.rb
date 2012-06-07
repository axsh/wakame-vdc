class KeypairsController < ApplicationController
  respond_to :json,:except => [:create,:prk_download]
  
  def index
  end
  
  def list
   data = {
     :start => params[:start].to_i - 1,
     :limit => params[:limit]
   }
   @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.list(data)
   respond_with(@ssh_key_pair[0],:to => [:json])
  end
  
  def show
    uuid = params[:id]
    @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.show(uuid)
    respond_with(@ssh_key_pair,:to => [:json])
  end
  
  def destroy
    name = params[:id]
    @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.destroy(name)
    render :json => @ssh_key_pair    
  end
  
  def create_ssh_keypair
    data = {
      :display_name => params[:display_name],
      :description => params[:description],
      :download_once => params[:download_once]
    }

    @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.create(data)
    @filename = @ssh_key_pair.uuid + ".pem"
    
    send_data(@ssh_key_pair.private_key,{
              :filename => @filename,
              :type => 'application/pgp-encrypted',
              :status => 200
            })
  end
  
  def show_keypairs
    @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.list
    respond_with(@ssh_key_pair[0],:to => [:json])
  end
  
  def total
   total_resource = Hijiki::DcmgrResource::SshKeyPair.total_resource
   render :json => total_resource
  end
  
  def prk_download
    uuid = params[:id]
    @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.show(uuid)
    @filename = @ssh_key_pair['uuid'] + ".pem"
    send_data(@ssh_key_pair['private_key'],{
              :filename => @filename,
              :type => 'application/pgp-encrypted',
              :status => 200
            })
  end
end
