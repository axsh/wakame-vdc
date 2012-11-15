# -*- coding: utf-8 -*-

require 'tmpdir'

module Dcmgr::Models
  # SSH Key database for account.
  class SshKeyPair < AccountResource
    taggable 'ssh'
    accept_service_type
    one_to_many :instances

    attr_accessor :private_key
    #
    # @return [Hash] {:private_key=>'pkey string',
    #                 :public_key=>'pubkey string'}
    def self.generate_key_pair(name)
      Dir.mktmpdir('sshkey') { |dir|
        pkey = File.expand_path('sshkey', dir)
        pubkey = pkey + '.pub'

        system("ssh-keygen -q -t rsa -C '%s' -N '' -f %s >/dev/null" % [name, pkey])
        unless $?.exitstatus == 0
          raise "Failed to run ssh-keygen: exitcode=#{$?.exitstatus}"
        end

        # get finger print of pkey file
        fp = `ssh-keygen -l -f #{pkey}`
        unless $?.exitstatus == 0
          raise "Failed to collect finger print value"
        end
        fp = fp.split(/\s+/)[1]

        return {:private_key=>IO.read(pkey),
                :public_key=>IO.read(pubkey),
                :finger_print => fp
               }
      }
    end

    def to_api_document
      super
    end

    def self.entry_new(account, &blk)
      raise ArgurmentError unless account.is_a?(Account)

      ssh = self.new &blk
      ssh.account_id = account.canonical_uuid

      ssh
    end

    def delete(force=false)
      instance_count = instances_dataset.count
      if(!force && instance_count > 0)
        raise "#{instance_count} instance references."
      end
      self.deleted_at ||= Time.now
      self.save_changes
      self
    end

  end
end
