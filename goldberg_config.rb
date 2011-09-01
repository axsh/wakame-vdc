Project.configure do |config|
  config.timeout = 60.minutes
  config.command = "/bin/sh -c 'cd tests && ./vdc.sh install && ./vdc.sh standalone:ci --without_screen=1'"
end
