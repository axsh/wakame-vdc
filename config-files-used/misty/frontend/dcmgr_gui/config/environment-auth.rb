# Load the rails application
require File.join(File.dirname(__FILE__), 'application')

# Initialize the rails application
DcmgrGui::Application.initialize!

$stdout.reopen(File.expand_path("log/auth_server.log", Rails.root) , "a")
$stdout.sync = true
$stderr.reopen($stdout)
