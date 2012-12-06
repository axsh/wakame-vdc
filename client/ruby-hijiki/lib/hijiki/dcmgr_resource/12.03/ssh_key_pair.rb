# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class SshKeyPair < Base

    module ClassMethods
      include Hijiki::DcmgrResource::Common::ListMethods::ClassMethods

      def create(params)
        ssh_key_pair = self.new
        ssh_key_pair.display_name = params[:display_name]
        ssh_key_pair.description = params[:description]
        ssh_key_pair.download_once = params[:download_once]
        ssh_key_pair.public_key = params[:public_key]
        ssh_key_pair.save
        ssh_key_pair
      end

      def update(uuid,params)
        self.put(uuid,params).body
      end

      def destroy(uuid)
        self.delete(uuid).body
      end
    end
    extend ClassMethods

  end
end
