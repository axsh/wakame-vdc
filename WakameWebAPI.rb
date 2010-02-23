#-
# Copyright (c) 2010 axsh co., LTD.
# All rights reserved.
#
# Author: Takahisa Kamiya
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# -*- coding: utf-8 -*-

require 'rubygems'
require 'active_resource'
require 'logger'

load('dcmgr-gui.conf')

if DEBUG_LOG
  @@logger = Logger.new('dcmgr-gui.log')
  def @@logger.write(str)
    self << str
  end
  use Rack::CommonLogger, @@logger
end

def debug_log(str)
  @@logger.debug str if DEBUG_LOG
end

class WebAPI < ActiveResource::Base
  self.site     = API_SERVER_URL
  self.format   = :json
  def self.login(user, pass)
    self.user = user
    self.password = pass
  end
end

class Account < WebAPI
end

class User < WebAPI
end

class AuthTag < WebAPI
end

class NameTag < WebAPI
end

class Instance < WebAPI
end

class HvController < WebAPI
end

class ImageStorage < WebAPI
end

class ImageStorageHost < WebAPI
end

class PhysicalHost < WebAPI
end
