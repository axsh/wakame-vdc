# -*- coding: utf-8 -*-

module Dcmgr
  module Models
    class ModelError < StandardError; end
    class InvalidUUIDError < ModelError; end
    class UUIDPrefixDuplication < ModelError; end

    class InvalidSecurityGroupRuleSyntax < ModelError; end
    class OutOfIpRange < ModelError; end
  end
end
