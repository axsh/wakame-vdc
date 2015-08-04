# -*- coding: utf-8 -*-

module Cli
  class Error < StandardError
    attr_reader :exit_code
    def initialize(msg, exit_code=1)
      super(msg)
      @exit_code = exit_code
    end

    def self.raise(msg, exit_code)
      Kernel.raise(if msg.is_a?(self)
                     msg
                   else
                     self.new(msg, exit_code)
                   end)
    end
  end

  class UnknownUUIDError < Error
    def initialize(uuid,exit_code=100)
      super("Unknown UUID: '#{uuid}'.")
    end

    def self.raise(uuid,exit_code=100)
      super
    end
  end

  class UnsupportedArchError < Error
    def initialize(arch,exit_code=100)
      super("Unsupported arch type: '#{arch}'.")
    end

    def self.raise(arch,exit_code=100)
      super
    end
  end

  class UnknownModelError < Error
    def initialize(model,exit_code=100)
      super("Not a sequel model: '#{model}'.")
    end

    def self.raise(model,exit_code=100)
      super
    end
  end

  class UnsupportedHypervisorError < Error
    def initialize(arch,exit_code=100)
      super("Unsupported hypervisor type: '#{arch}'.")
    end

    def self.raise(arch,exit_code=100)
      super
    end
  end
end
