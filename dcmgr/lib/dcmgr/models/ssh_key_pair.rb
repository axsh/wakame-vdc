# -*- coding: utf-8 -*-

require 'tmpdir'

module Dcmgr::Models
  # SSH Key database for account.
  class SshKeyPair < AccountResource
    taggable 'ssh'

    inheritable_schema do
      String :name, :size=>100, :null=>false
      Text :public_key, :null=>false
      Text :private_key, :null=>true
      
      index [:account_id, :name], {:unique=>true}
    end
    with_timestamps

    def validate
    end

    def before_destroy
      # TODO: check running instances which are associated to ssh key
      # pairs. reject deletion if exist.
    end

    # 
    # @return [Hash] {:private_key=>'pkey string',
    #                 :public_key=>'pubkey string'}
    def self.generate_key_pair()
      pkey = File.expand_path(randstr, Dir.tmpdir)
      pubkey = pkey + '.pub'
      begin
        system("ssh-keygen -q -t rsa -C '' -N '' -f %s >/dev/null" % [pkey])
        unless $?.exitstatus == 0
          raise "Failed to run ssh-keygen: exitcode=#{$?.exitstatus}"
        end
        
        {:private_key=>IO.read(pkey),
          :public_key=>IO.read(pubkey)}
      rescue
        # clean up tmp key files
        [pkey, pubkey].each { |i|
          File.unlink(i) if File.exist?(i)
        }
      end
    end

    private
    def self.randstr
      Array.new(10) {  (('a'..'z').to_a + (0..9).to_a)[rand(36)] }.join
    end
    
  end
end
