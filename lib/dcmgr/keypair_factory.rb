# -*- coding: utf-8 -*-

require 'net/http'

module Dcmgr::KeyPairFactory
  class KeyPairFactoryError < StandardError; end
  
  KEYGEN_PATH = '/usr/bin/ssh-keygen'
  TYPE = 'rsa'

  def self.generate(filename)
    tmp = "/tmp/#{filename}_key"
    command = "#{KEYGEN_PATH} -t #{TYPE} -f #{tmp} -N \"\""
    ret = system(command)
    raise KeyPairFactoryError unless ret

    private_key = ''
    public_key = ''

    File.open(tmp){|f|
      private_key = f.read
    }
    File.delete(tmp)
    
    File.open(tmp + ".pub"){|f|
      public_key = f.read
    }
    File.delete(tmp + ".pub")

    {:private=>private_key,
      :public=>public_key}
  end
end
