# -*- coding: utf-8 -*-

module Dcmgr
  module Models
    class InvalidUUIDError < StandardError; end
    class UUIDPrefixDuplication < StandardError; end

    class InvalidSecurityGroupRuleSyntax < StandardError; end
  end
end
