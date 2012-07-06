
require 'tzinfo'

DEFAULT_TIMEZONE='Asia/Tokyo'

if defined?(DcmgrGui::Application)
  DcmgrGui::Application.config.time_zone = DEFAULT_TIMEZONE
end
