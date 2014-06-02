# encoding: utf-8

require 'logger'

# for passenger, messages in STDOUT are not appeared in
# error.log. $> is changed in initializers/logger.rb as per the
# server environment. so that here also refers $> instead of STDOUT or
# STDERR constant.
logdev = ::Logger::LogDevice.new($>)

# stdout is nomarlly buffered. So it changes the behavior globally.
if logdev.dev == STDOUT
  STDOUT.sync = true
end

Dcmgr::Logger.logger = ::Logger.new(logdev)



