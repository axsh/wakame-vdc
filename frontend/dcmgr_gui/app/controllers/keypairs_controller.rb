class KeypairsController < ApplicationController
  respond_to :json,:except => [:create,:prk_download]
  
  def index
  end
  
  def list
    catch_error do
      data = {
        :start => params[:start].to_i - 1,
        :limit => params[:limit]
      }
      @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.list(data)
      respond_with(@ssh_key_pair[0],:to => [:json])
    end
  end
  
  def show
    catch_error do
      uuid = params[:id]
      @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.show(uuid)
      respond_with(@ssh_key_pair,:to => [:json])
    end
  end
  
  def destroy
    catch_error do
      name = params[:id]
      @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.destroy(name)
      render :json => @ssh_key_pair
    end
  end

  def create_ssh_keypair
    catch_error do
      data = {
        :display_name => params[:display_name],
        :description => params[:description],
        :download_once => params[:download_once],
        :public_key => params[:public_key]
      }
      @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.create(data)
      @filename = @ssh_key_pair.uuid + ".pem"
      send_data(@ssh_key_pair.private_key,{
                  :filename => @filename,
                  :type => 'application/pgp-encrypted',
                  :status => 200
                })
    end
  end

  def edit_ssh_keypair
    catch_error do
      uuid = params[:id]
      data = {
        :display_name => params[:display_name],
        :description => params[:description]
      }

      @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.update(uuid,data)
      render :json => @ssh_key_pair
    end
  end
  
  def show_keypairs
    catch_error do
      @ssh_key_pair = Hijiki::DcmgrResource::SshKeyPair.list
      respond_with(@ssh_key_pair[0],:to => [:json])
    end
  end
  
  def total
    catch_error do
      total_resource = Hijiki::DcmgrResource::SshKeyPair.total_resource
      render :json => total_resource
    end
  end
  
  def prk_download
    catch_error do
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
end
