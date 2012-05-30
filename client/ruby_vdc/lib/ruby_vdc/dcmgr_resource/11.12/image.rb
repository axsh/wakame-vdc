# -*- coding: utf-8 -*-

require 'yaml'

module DcmgrResource::V1112
  class Image < Base
    include DcmgrResource::ListMethods
    include ListTranslateMethods
  end

  Image.preload_resource('Result', Module.new {
    def source
      find_or_create_resource_for('source').new(YAML::load(attributes['source']))
    end

    def features
      find_or_create_resource_for('features').new(YAML::load(attributes['features']))
    end
  })

end

