# -*- coding: utf-8 -*-
require 'sequel/model'

# Sequal::Model plugin to inject the Taggable feature to the model
# class.
#
# Taggable model supports the features below:
# - Taggable.uuid_prefix to both set and get uuid_prefix for the model.
# - Collision detection for specified uuid_prefix.
# - Generate unique value for :uuid column at initialization.
# - Add column :uuid if the model is capable of :schema plugin methods.
module Taggable
  UUID_TABLE='abcdefghijklmnopqrstuvwxyz0123456789'.split('').freeze
  UUID_REGEX=%r/^(\w+)-([#{UUID_TABLE.join}]+)/

  class UUIDPrefixDuplication < StandardError; end

  def self.uuid_prefix_collection
    @uuid_prefix_collection ||= {}
  end

  # Find a taggable model object from the
  # given canonical uuid.
  #
  # # Find an account.
  # Taggble.find('a-xxxxxxxx')
  #
  # # Find a user.
  # Taggble.find('u-xxxxxxxx')
  def self.find(uuid)
    raise ArgumentError, "Invalid uuid syntax: #{uuid}" unless uuid =~ UUID_REGEX
    upc = uuid_prefix_collection[$1.downcase]
    raise "Unknown uuid prefix: #{$1.downcase}" if upc.nil?
    upc[:class].find(:uuid=>$2)
  end

  # Checks if the uuid object stored in the database.
  def self.exists?(uuid)
    !find(uuid).nil?
  end

  def self.configure(model)
    model.schema_builders << proc {
      unless has_column?(:uuid)
        # add :uuid column with unique index constraint.
        column(:uuid, String, :size=>8, :null=>false, :fixed=>true, :unique=>true)
      end
    }
  end

  module InstanceMethods
    # read-only instance method to retrieve @uuid_prefix class
    # variable.
    def uuid_prefix
      self.class.uuid_prefix
    end
  
    def after_initialize
      super
      # set random generated uuid value
      self[:uuid] ||= Array.new(8) do UUID_TABLE[rand(UUID_TABLE.size)]; end.join
    end

    # Returns canonicalized uuid which has the form of
    # "{uuid_prefix}-{uuid}".
    def canonical_uuid
      "#{self.uuid_prefix}-#{self[:uuid]}"
    end
    alias_method :cuuid, :canonical_uuid

    # Put the tag on the object.
    #
    # This method just delegates the method call of Tag#label().
    # @params [Models::Tag,String] tag_or_tag_uuid 'tag-xxxx' is expected when the type is string
    def label_tag(tag_or_tag_uuid)
      tag = case tag_or_tag_uuid
            when String
              Tag[tag_or_tag_uuid]
            when Tag
              tag_or_tag_uuid
            else
              raise ArgumentError, "Invalid type: #{tag_or_tag_uuid.class}"
            end
    
      tag.label(self.uuid)
    end

    # Remove the labeled tag from the object
    #
    # This method just delegates the method call of Tag#unlabel().
    # @params [Models::Tag,String] tag_or_tag_uuid 'tag-xxxx' is expected when the type is string
    def unlabel_tag(tag_or_tag_uuid)
      tag = case tag_or_tag_uuid
            when String
              Tag[tag_or_tag_uuid]
            when Tag
              tag_or_tag_uuid
            else
              raise ArgumentError, "Invalid type: #{tag_or_tag_uuid.class}"
            end

      tag.unlabel(self.uuid)
    end

  end

  module ClassMethods
    # Getter and setter for uuid_prefix of the class.
    #
    # @example
    #   class Model1 < Sequel::Model
    #     plugin Taggable
    #     uuid_prefix('m')
    #   end
    #   
    #   Model1.uuid_prefix # == 'm'
    #   Model1.new.canonical_uuid # == 'm-abcd1234'
    def uuid_prefix(prefix=nil)
      if prefix
        raise UUIDPrefixDuplication, "Found collision for uuid_prefix key: #{prefix}" if Taggable.uuid_prefix_collection.has_key?(prefix)
      
        Taggable.uuid_prefix_collection[prefix]={:class=>self}
        @uuid_prefix = prefix
      end
      @uuid_prefix || raise("uuid prefix is unset for:#{self}")
    end


    # Override Model.[] to add lookup by uuid.
    #
    # @example
    #   Account['a-xxxxxx']
    def [](*args)
      if args.size == 1 and args[0].is_a? String
        super(:uuid=>trim_uuid(args[0]))
      else
        super(*args)
      end
    end

    # Returns the uuid string which is removed prefix part: /^(:?\w+)-/.
    #
    # @example
    #   Account.trim_uuid('a-abcd1234') # = 'abcd1234'
    # @example Will get InvalidUUIDError as the uuid with invalid prefix has been tried.
    #   Account.trim_uuid('u-abcd1234') # 'u-' prefix is for User model.
    def trim_uuid(p_uuid)
      regex = %r/^#{self.uuid_prefix}-/
      if p_uuid and p_uuid =~ regex
        return p_uuid.sub(regex, '')
      end
      raise "Invalid uuid or unsupported uuid: #{p_uuid} in #{self}"
    end

    # Checks the general uuid syntax
    def check_trimmed_uuid_format(uuid)
      uuid.match(/^[a-z0-9 ]*$/) && uuid.length <= 8
    end

    # Checks the uuid syntax if it is for the Taggable class.
    def check_uuid_format(uuid)
      uuid =~ /^#{self.uuid_prefix}-/
    end
  end
    
end

# Sequel::Model plugin extends :schema plugin to merge the column
# definitions in its parent class.
#
# class Model1 < Sequel::Model
#   plugin InheritableSchema
#
#   inheritable_schema do
#     String :col1
#   end
# end
#
# class Model2 < Model1
#   inheritable_schema do
#     String :col2
#   end
# end
#
# Model2.create_table!
# 
# Then the schema for Model2 becomes as follows:
#   primary_key :id, :type=>Integer, :unsigned=>true
#   String :col1
#   String :col2
module InheritableSchema
  def self.apply(model)
    model.plugin :schema
  end

  module ClassMethods
    def schema_builders
      @schema_builders ||= []
    end
  
    def inheritable_schema(&blk)
      if blk
        self.schema_builders << blk
      
        if @schema.nil?
          # set_dataset(:tablename) in set_schema() force to overwrite
          # dataset.row_proc to the standard one even if the
          # dataset.row_proc is set something another. This becomes problem when
          # another plugin needed to set its own row_proc.

          # This is workaround to prevent from above.
          row_proc = dataset.row_proc
          set_schema(implicit_table_name) do
            primary_key :id, :type=>Integer, :unsigned=>true
          end
          dataset.row_proc = row_proc if row_proc.is_a?(Proc)
        end

        builders = []
        c = self
        begin
          builders << c.schema_builders if c.respond_to?(:schema_builders)
        end while (c = c.superclass) < InheritableSchema

        builders = builders.reverse.flatten
        builders.delete(nil)
        builders.each { |blk|
          @schema.instance_eval(&blk)
        }
      end
    end
  end

end

class BaseNew < Sequel::Model

  def self.Proxy(klass)
    colnames = klass.schema.columns.map {|i| i[:name] }
    colnames.delete_if(klass.primary_key) if klass.restrict_primary_key?
    s = ::Struct.new(*colnames) do
      def to_hash
        n = {}
        self.each_pair { |k,v|
          n[k.to_sym]=v
        }
        n
      end
    end
    s
  end

  # Returns true if this Model has time stamps
  def with_timestamps?
    self.columns.include?(:created_at) && self.columns.include?(:updated_at)
  end

  # Callback when the initial data is setup to the database.
  def self.install_data
    install_data_hooks.each{|h| h.call }
  end

  # Add callbacks to setup the initial data. The hooks will be
  # called when Model1.install_data() is called.
  # 
  # class Model1 < Base
  #   install_data_hooks do
  #     Model1.create({:col1=>1, :col2=>2})
  #   end
  # end
  def self.install_data_hooks(&blk)
    @install_data_hooks ||= []
    if blk
      @install_data_hooks << blk
    end
    @install_data_hooks
  end


  private
  def self.inherited(klass)
    super

    klass.plugin InheritableSchema
    klass.class_eval {

      # Add timestamp columns and set callbacks using Timestamps
      # plugin.
      #
      # class Model1 < Base
      #   with_timestamps
      # end
      def self.with_timestamps
        self.schema_builders << proc {
          unless has_column?(:created_at)
            column(:created_at, Time, :null=>false)
          end
          unless has_column?(:updated_at)
            column(:updated_at, Time, :null=>false)
          end
        }
      
        self.plugin :timestamps, :update_on_create=>true
      end

      # Install Taggable module as Sequel plugin and set uuid_prefix.
      # 
      # class Model1 < Base
      #   taggable 'm'
      # end
      def self.taggable(uuid_prefix)
        return if self == BaseNew
        self.plugin Taggable
        self.uuid_prefix(uuid_prefix)
      end

    }
  
  end
end
