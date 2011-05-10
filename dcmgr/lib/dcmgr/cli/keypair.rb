# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class KeyPair < Base
    namespace :keypair
    M = Dcmgr::Models

    desc "add [options]", "Register a new key pair."
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new key pair."
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The UUID of the account this key pair belongs to.", :required => true
    method_option :name, :type => :string, :aliases => "-n", :desc => "The name for this key pair.", :required => true
    method_option :public_key, :type => :string, :aliases => "-pub", :desc => "The path to the public key.", :required => true
    method_option :private_key, :type => :string, :aliases => "-pri", :desc => "The path to the private key.", :required => true
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      Error.Raise "Private key file doesn't exist" unless File.exists?(options[:private_key])
      Error.Raise "Public key file doesn't exist" unless File.exists?(options[:public_key])
      
      fields = options.dup
      
      #Get the keys from their respective files.
      #TODO: Make this work with ~ for home directory
      fields[:public_key] = File.open(options[:public_key]) {|f| f.readline}
      fields[:private_key] = File.open(options[:private_key]) {|f| f.readlines.map.join}
      
      #Generate the fingerprint from the public key file
      fields[:finger_print] = %x{ssh-keygen -lf #{options[:public_key]} | cut -d ' ' -f2}.chomp
      
      puts super(M::SshKeyPair,fields)
    end
  end
end
