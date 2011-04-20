module Dcmgr::Cli
  class Base < Thor
    protected
    def self.basename
      "#{super()} #{namespace}"
    end
  end
end
