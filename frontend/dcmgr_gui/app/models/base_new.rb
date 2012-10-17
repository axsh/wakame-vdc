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

    # Checks the uuid syntax if it is for the Taggable class.
    def check_uuid_format(uuid)
      uuid =~ /^#{self.uuid_prefix}-/
    end

    def valid_uuid_syntax?(uuid)
      uuid =~ /^#{self.uuid_prefix}-[\w]+/
    end
  end

  def self.apply(model)
    model.def_dataset_method(:by_uuid) do |uuid|
      if model.check_uuid_format(uuid)
        uuid = model.trim_uuid(uuid)
      end
      self.where(:uuid=>uuid)
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
    require 'sequel/plugins/schema'
    model.plugin Sequel::Plugins::Schema
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

  module LogicalDelete
    class FilterClause < Sequel::ASTTransformer
      include Sequel::SQL
      
      private
      def v2(o)
        if o.is_a?(ComplexExpression) && check_target_ast(o)
          1
        else
          super
        end
      end
      
      def v(o)
        if o.is_a?(ComplexExpression)
          if check_target_ast(o)
            return ComplexExpression.new(:NOOP, 1)
          else
            is_rejected = o.args.reject! { |o2|
              check_target_ast(o2)
            }
            return super(o) if is_rejected.nil?
          end
          
          return case o.op
                 when *ComplexExpression::N_ARITY_OPERATORS
                   if o.args.empty?
                     ComplexExpression.new(:NOOP, 1)
                   else
                     super(o) #ComplexExpression.new(o.op, *v(o.args))
                   end
                 when *ComplexExpression::TWO_ARITY_OPERATORS
                   super(o.args.first)
                 when *ComplexExpression::ONE_ARITY_OPERATORS
                   ComplexExpression.new(:NOOP, 1)
                 end
        else
          super
        end
      end
      
      # find "deleted_at IS NULL" SQL clause.
      def check_target_ast(o)
        o.is_a?(Sequel::SQL::ComplexExpression) && o.op == :IS && o.args.first == :deleted_at && o.args.last == nil
      end
    end

    def self.apply(model)
      model.subset(:alives, {:deleted_at=>nil})
      model.set_dataset(model.dataset.where(:deleted_at=>nil))

      model.def_dataset_method(:with_deleted) do
        self.opts[:where] = FilterClause.new.transform(self.opts[:where] || self.opts[:having])
        self
      end
      
      model.class_eval {
        # override Sequel::Model#_delete not to delete rows but to set
        # delete flags.
        def _destroy_delete
          self.deleted_at ||= Time.now
          self.save_changes
        end
      }
    end
  end
  
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

  # Create a UUID from IDset separated by pattern(default commas).
  def self.split_uuid(params, pattern = ',')
    arr = params.split(pattern)
    uuids = arr.collect {|u| u.split('-')[1] }
    uuids.delete(nil)
    uuids.delete("")
    uuids
  end

  private
  def self.inherited(klass)
    super
    klass.set_dataset(db[klass.implicit_table_name])

    klass.class_eval {

      # Add timestamp columns and set callbacks using Timestamps
      # plugin.
      #
      # class Model1 < Base
      #   with_timestamps
      # end
      def self.with_timestamps
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
