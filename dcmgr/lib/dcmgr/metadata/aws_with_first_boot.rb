# -*- coding: utf-8 -*-

module Dcmgr::Metadata
  class AWSWithFirstBoot < AWS
    def get_items
      items = super

      # We add this little empty file to let Windows know that this is the first time
      # this instance is being booted. Therefore it needs to generate a new password.
      items['first-boot'] = ''

      items
    end
  end
end
