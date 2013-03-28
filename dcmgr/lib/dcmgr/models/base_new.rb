# -*- coding: utf-8 -*-

require 'sequel/model'


module Dcmgr::Models
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
      model.many_to_many :tags, :dataset=>lambda { Tag.join(TagMapping.table_name, :tag_id=>:id, :uuid=>self.canonical_uuid); }
    end

    module InstanceMethods
      # read-only instance method to retrieve @uuid_prefix class
      # variable.
      def uuid_prefix
        self.class.uuid_prefix
      end

      def before_validation
        # trim uuid prefix if it is in the self[:uuid]
        self[:uuid].sub!(/^#{self.class.uuid_prefix}-/, '')
        super
      end

      def before_create
        if !self.class.find(:uuid=>self[:uuid]).nil?
          raise "Duplicate UUID: #{self.canonical_uuid} already exists"
        end
        super
      end

      def after_initialize
        super
        # set random generated uuid value
        self[:uuid] ||= Array.new(8) do UUID_TABLE[rand(UUID_TABLE.size)]; end.join
      end

      # model hook
      def after_destroy
        super
        TagMapping.filter(:uuid=>self.canonical_uuid).delete
      end

      # Returns canonicalized uuid which has the form of
      # "{uuid_prefix}-{uuid}".
      def canonical_uuid
        "#{self.uuid_prefix}-#{self[:uuid]}"
      end
      alias_method :cuuid, :canonical_uuid

      # Put the tag on the object.
      #
      # @params [Models::Tag,String,Symbol] arg1
      # @params [String,NilClass] arg2
      # @params [String,NilClass] arg3
      #
      # @example
      # lable_tag('tag-xxxxx')
      # t = Tag['tag-xxxx']
      # label_tag(t)
      # label_tag(:NetworkGroup, 'newname1', 'account_id')
      def label_tag(arg1, arg2=nil, arg3=nil)
        tag = case arg1
              when String
                Tag[arg1]
              when Symbol
                acctid = arg3 || self.respond_to?(:account_id) ? self.account_id : raise("Unknown Account ID")
                Dcmgr::Tags.const_get(arg1, false).find_or_create(:account_id=>acctid, :name=>arg2)
              when Tag
                arg1
              else
                raise ArgumentError, "Invalid type: #{arg1.class}"
              end
        raise "Root Tag class can not be used" unless tag.class < Tag
        tag.label(self.canonical_uuid)
      end

      # Remove the labeled tag from the object
      #
      # @params [Models::Tag,String,Symbol] arg1
      # @params [String,NilClass] arg2
      # @params [String,NilClass] arg3
      #
      # @example
      # unlable_tag('tag-xxxxx')
      # t = Tag['tag-xxxx']
      # unlabel_tag(t)
      # unlabel_tag(:NetworkGroup, 'newname1', 'account_id')
      def unlabel_tag(arg1, arg2=nil, arg3=nil)
        tag = case arg1
              when String
                Tag[arg1]
              when Symbol
                acctid = arg3 || self.respond_to?(:account_id) ? self.account_id : raise("Unknown Account ID")
                Dcmgr::Tags.const_get(arg1, false).find(:account_id=>acctid, :name=>arg2)
              when Tag
                arg1
              else
                raise ArgumentError, "Invalid type: #{arg1.class}"
              end

        tag.unlabel(self.canonical_uuid)
      end

      def to_hash()
        r = self.values.dup.merge({:id=>self.id, :uuid=>canonical_uuid})
        serialize_columns = []
        require 'sequel/plugins/serialization'
        if self.class.plugins.member?(Sequel::Plugins::Serialization)
          self.class.deserialization_map.keys.each { |c|
            serialize_columns << c
            r[c] = self.__send__(c)
          }
        end
        # convert Sequel::SQL::Blob column.
        # TODO: look for alternative method to stop to retrieve
        #       db_schema hash.
        self.class.db_schema.each { |c, v|
          if v[:db_type] == 'text' && v[:type] == :string && !serialize_columns.member?(c)
            r[c] = self.__send__(c).to_s
          end
        }
        r
      end

      # generate API response document. similar to to_hash() but not
      # to expose integer primary key.
      def to_api_document
        self.values.dup.merge({:id=>self.canonical_uuid, :uuid=>canonical_uuid})
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

        @uuid_prefix || (superclass.uuid_prefix if superclass.respond_to?(:uuid_prefix)) || raise("uuid prefix is unset for:#{self}")
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
        raise InvalidUUIDError, "Invalid uuid or unsupported uuid: #{p_uuid} in #{self}"
      end

      # Checks the general uuid syntax
      def check_trimmed_uuid_format(uuid)
        uuid.match(/^[\w]+$/) && uuid.length <= 255
      end

      # Checks the uuid syntax if it is for the Taggable class.
      def check_uuid_format(uuid)
        uuid =~ /^#{self.uuid_prefix}-/
      end

      def valid_uuid_syntax?(uuid)
        uuid =~ /^#{self.uuid_prefix}-[\w]+/
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
      # Creates table, using the column information from set_schema.
      def create_table
        db.create_table(table_name, :generator=>schema)
        @db_schema = get_db_schema(true)
        columns
      end

      # Drops the table if it exists and then runs
      # create_table.  Should probably
      # not be used except in testing.
      def create_table!
        drop_table rescue nil
        create_table
      end

      # Creates the table unless the table already exists
      def create_table?
        create_table unless table_exists?
      end

      # Drops table.
      def drop_table
        db.drop_table(table_name)
      end

      # Returns true if table exists, false otherwise.
      def table_exists?
        db.table_exists?(table_name)
      end

      def schema
        builders = []
        c = self
        begin
          builders << c.schema_builders if c.respond_to?(:schema_builders)
        end while((c = c.superclass) && c != Sequel::Model)

        builders = builders.reverse.flatten
        builders.delete(nil)

        schema = Sequel::Schema::Generator.new(db) {
          primary_key :id, Integer, :null=>false, :unsigned=>true
        }
        builders.each { |blk|
          schema.instance_eval(&blk)
        }
        set_primary_key(schema.primary_key_name) if schema.primary_key_name

        schema
      end

      def schema_builders
        @schema_builders ||= []
      end

      def inheritable_schema(name=nil, &blk)
        set_dataset(db[name || implicit_table_name])
        self.schema_builders << blk
      end
    end

  end

  # This plugin is to archive the changes on each column of the model
  # to a history table.
  #
  # plugin ArchiveChangedColumn, :your_history_table
  #  or
  # plugin ArchiveChangedColumn
  # history_dataset = DB[:history_table]
  #
  # The history table should have the schema below:
  # schema do
  #   Fixnum :id, :null=>false, :primary_key=>true
  #   String :uuid, :size=>50, :null=>false
  #   String :attr, :null=>false
  #   String :vchar_value, :null=>true
  #   String :blob_value, :null=>true, :text=>true
  #   Time  :created_at, :null=>false
  #   index [:uuid, :created_at]
  #   index [:uuid, :attr]
  # end
  module ArchiveChangedColumn
    def self.configure(model, history_table=nil)
      model.history_dataset = case history_table
                              when NilClass
                                nil
                              when String,Symbol
                                model.db.from(history_table)
                              when Class
                                raise "Unknown type" unless history_table < Sequel::Model
                                history_table.dataset
                              when Sequel::Dataset
                                history_table
                              else
                                raise "Unknown type"
                              end
    end

    module ClassMethods
      def history_dataset=(ds)
        @history_ds = ds
      end

      def history_dataset
        @history_ds
      end
    end

    module InstanceMethods
      def history_snapshot(at)
        raise TypeError unless at.is_a?(Time)

        if self.created_at > at || (!self.terminated_at.nil? && self.terminated_at < at)
          raise "#{at} is not in the range of the object's life span."
        end

        ss = self.dup
        #  SELECT * FROM (SELECT * FROM `instance_histories` WHERE
        #  (`uuid` = 'i-ezsrs132') AND created_at <= '2010-11-30 23:08:05'
        #  ORDER BY created_at DESC) AS a GROUP BY a.attr;
        ds = self.class.history_dataset.filter('uuid=? AND created_at <= ?', self.canonical_uuid, at).order(:created_at.desc)
        ds = ds.from_self.group_by(:attr)
        ds.all.each { |h|
          if !h[:blob_value].nil?
            ss.send("#{h[:attr]}=", typecast_value(h[:attr], h[:blob_value]))
          else
            ss.send("#{h[:attr]}=", typecast_value(h[:attr], h[:vchar_value]))
          end
        }
        # take care for serialized columns by serialization plugin.
        ss.deserialized_values.clear if ss.respond_to?(:deserialized_values)

        ss
      end

      def before_create
        return false if super == false
        store_changes(self.columns)
        true
      end

      def before_update
        return false if super == false
        store_changes(self.changed_columns)
        true
      end

      private
      def store_changes(cols_stored)
        return if cols_stored.nil? || cols_stored.empty?
        common_rec = {
          :uuid=>self.canonical_uuid,
          :created_at => Time.now,
        }

        cols_stored.each { |c|
          hist_rec = common_rec.dup
          hist_rec[:attr] = c.to_s

          coldef = self.class.db_schema[c]
          case coldef[:type]
          when :text,:blob
            hist_rec[:blob_value]= (new? ? (self[c] || coldef[:default]) : self[c])
          else
            hist_rec[:vchar_value]=(new? ? (self[c] || coldef[:default]) : self[c])
          end
          self.class.history_dataset.insert(hist_rec)
        }
      end
    end
  end

  module ChangedColumnEvent
    # This plugin is to call any method when each columns of model was changed.
    #
    # Usage:
    #
    #   plugin ChangedColumnEvent, :function_name => [:track_columns]
    #
    #   * :function_name - specify name that called by :track_columns event. Please create a function that added with a on_changed_ prefix. ( eg: on_changed_accounting_log)
    #   * :track_columns - specify columns that can call :function_name when the table has been changed.

    def self.configure(model, track_columns)
      raise "Invalid type" if !track_columns.is_a?(Hash)
      track_columns.keys.each { |event_name|
        model.track_column_set(event_name, track_columns)
      }
    end

    module ClassMethods
      attr_accessor :track_columns
      def track_column_set(event_name, columns)
        @track_columns = {} if @track_columns.nil?
        @track_columns[event_name] = columns
      end
    end

    module InstanceMethods
      def before_create
        return false if super == false
        apply_changed_event(self.columns)
        true
      end

      def before_update
        return false if super == false
        apply_changed_event(self.changed_columns)
        true
      end

      private
      def apply_changed_event(changed_columns)
        model.track_columns.keys.each do |event_name|
          call_method = "on_changed_#{event_name.to_s}".to_sym
          raise "Undefined method #{call_method}" if !model.method_defined?(call_method)

          model.track_columns[event_name].values.find_all { |c|
            match_column = c - (c - changed_columns)
            self.__send__(call_method, match_column[0])  if !match_column.empty?
          }
        end
      end
    end
  end

  module Plugins
    M = Dcmgr::Models
    
    module ResourceLabel
      def self.apply(model)
        model.one_to_many :resource_labels, :class=>M::ResourceLabel, :key=>:resource_uuid, :primary_key=>:canonical_uuid, :extend=>M::ResourceLabel::LabelDatasetMethods

        # model.filter_label('key1', 'value1').first
        model.def_dataset_method(:filter_by_label) do |name, value=nil|
          pair_label_filter = {:name=>name}
          if value
            pair_label_filter.merge!(M::ResourceLabel.typecast_value_column(value))
          end
          m = self.instance_variable_get(:@model)
          lbds = M::ResourceLabel.dataset.filter(pair_label_filter).filter(Sequel.like(:resource_uuid, "#{m.uuid_prefix}-%"))
          self.filter(:uuid=>lbds.select(Sequel.function('SUBSTRING', :resource_uuid, m.uuid_prefix.size + 1)))
        end
      end

      module InstanceMethods
        def label(name)
          self.resource_labels_dataset.filter(:name=>name).first
        end
        
        def set_label(name, value)
          l = label(name)
          if l
            l.value = value
            l.save_changes
          else
            self.add_resource_label({:name=>name}.merge(M::ResourceLabel.typecast_value_column(value)))
          end
        end
        
        def unset_label(name)
          label(name).destroy
        end

        def to_hash(*args)
          super.to_hash.merge({:labels=>self.resource_labels_dataset.all.map{|l| l.to_hash }})
        end
      end
    end
  end

  class BaseNew < Sequel::Model

    plugin :validation_helpers

    def to_hash()
      self.values.dup
    end

    LOCK_TABLES_KEY='__locked_tables'

    def self.default_row_lock_mode=(mode)
      raise ArgumentError unless [nil, :share, :update].member?(mode)
      @default_row_lock_mode = mode
    end

    def self.lock!(mode=nil)
      raise ArgumentError unless [nil, :share, :update].member?(mode)
      mode ||= @default_row_lock_mode
      locktbls = Thread.current[LOCK_TABLES_KEY]
      if locktbls
        locktbls[self.db.uri.to_s + @dataset.first_source_alias.to_s]=mode
      end
    end

    def self.unlock!
      locktbls = Thread.current[LOCK_TABLES_KEY]
      if locktbls
        locktbls.delete(self.db.uri.to_s + @dataset.first_source_alias.to_s)
      end
    end

    def self.dataset
      locktbls = Thread.current[LOCK_TABLES_KEY]
      if locktbls && (mode = locktbls[self.db.uri.to_s + @dataset.first_source_alias.to_s])
        # lock mode: :share or :update
        @dataset.opts = @dataset.opts.merge({:lock=>mode})
      else
        @dataset.opts = @dataset.opts.merge({:lock=>nil})
      end
      @dataset
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
      klass.set_dataset(db[klass.implicit_table_name])

      klass.plugin InheritableSchema
      klass.plugin :timestamps, :update_on_create=>true
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
end
