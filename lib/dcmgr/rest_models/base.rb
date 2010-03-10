module Dcmgr
  module RestModels
    module ClassMethods
      def actions
        @actions.each{|method, path, args, action|
          yield [method, path, Dcmgr.route(self, method, action)]
        }
      end
      
      def public_action(method, name=nil, *args, &block)
        @actions ||= []
        @actions << [method, url_all(name), args, block]
      end
      
      def public_action_withid(method, name=nil, *args, &block)
        @actions ||= []
        @actions << [method, url_id(name), args, block]
      end
      
      def url_all(action_name=nil)
        if action_name
          "/#{get_public_name}/#{action_name}.json"
        else
          "/#{get_public_name}.json"
        end          
      end
      
      def url_id(action_name=nil)
        if action_name
          %r{/#{get_public_name}/(\w+-\w+)/#{action_name}.json}
        else
          %r{/#{get_public_name}/(\w+-\w+).json}
        end
      end
      
      def allow_keys(*keys)
        return @allow_keys if keys.empty?
        @allow_keys = keys
      end
      
      def response_keys(*keys)
        return @response_keys if keys.empty?
        @response_keys = keys
      end

      def get_model
        @model
      end
      
      def model(model_class)
        @model = model_class
      end
      
      attr_writer :model

      def get_public_name
        @public_name or
          (@model and @model.table_name.to_s) or
          self.to_s
      end
      
      def public_name(name)
        @public_name = name
      end
      
      def protect?
        @protect == nil || @protect
      end
      
      def set_protect(flg)
        @protect = flg
      end
    end
    
    module Base
      include Dcmgr::Helpers
      
      def self.included(mod)
        mod.extend ClassMethods
      end
      
      attr_accessor :uuid
      attr_accessor :user
      attr_accessor :request
      
      def model
        self.class.get_model
      end
      
      def allow_keys
        self.class.allow_keys
      end
      
      def response_keys
        self.class.response_keys
      end
      
      def to_response(object)
        case object
        when Array
          object.map{|o| format_object(o) }
        else
          format_object(object)
        end
      end
      
      def format_object(object)
        case object
        when Hash, TrueClass, FalseClass, NilClass
          return object
        end
        
        keys = response_keys ? response_keys :
          object.keys.map{|key|
          if /^(.*)_id$/ =~ key.to_s then $1.to_sym else key end
        }
        
        ret = {}
        keys.each{|key|
          case key # resopnse_key Array format is [:key, proc]
          when Array
            get_val = key[1]
            key = key[0]
            val = get_val.call(object)
          else
            val = object.send(key)
            if Array === val
              val = val.map{|v|
                if v.respond_to? :uuid then v.uuid else v end
              }
            else
              val = val.uuid if val.respond_to? :uuid
            end
          end
          ret[key] = val
        }
        
        # strip id, change uuid to id
        ret.delete :id
        uuid = ret.delete :uuid
        ret[:id] = uuid if uuid
        
        ret
      end
      
      def query_str_like(key, str)
        def escape(str); str.gsub(/_/, '\_').gsub(/%/, '\%'); end
        case str
        when /^\*(.*)\*$/
          key.like("%#{escape($1)}%")
        when /^\*(.*)$/
          key.like("%#{escape($1)}")
        when /^(.*)\*$/
          key.like("#{escape($1)}%")
        else
          {key=>str}
        end
      end
      
      def find
        find_params = []
        allow_keys.each{|key|
          get_key = "_get_#{key}".to_sym
          if request[get_key]
            if model.db_schema[key][:type] == :boolean
              find_params << {key => request[get_key] == 'true'}
            elsif model.db_schema[key][:type] == :datetime
              find_params << (key >= Time.parse(request[get_key][0]))
              find_params << (key <= Time.parse(request[get_key][1]))
            else
              find_params << query_str_like(key, request[get_key])
            end
          end
        }
        if request[:_get_id]
          begin
            find_params << {:uuid => Account.trim_uuid(request[:_get_id])}
          rescue Dcmgr::Models::InvalidUUIDError
            return []
          end
        end
        
        offset = if request.key? :_get_offset
                 then request[:_get_offset].to_i
                 else 0 end
        limit = if request.key? :_get_limit
                then request[:_get_limit].to_i
                else 100 end
        
        filter = if find_params.length > 0
                   model.filter(find_params)
                 else
                   model
                 end
        
        filter.limit(limit, offset).all
      end
      
      def get
        model[uuid]
      end
      
      def allowed_request_columns(request)
        columns = {}
        
        # set request user if allow keys
        if allow_keys.include? :user
          columns[:user] = user
        end
        
        allow_keys.each{|key|
          next unless request.key? key and not request[key].nil?
          val = request[key]
          case key
          when :account
            columns[key] = Models::Account[val]
          else
            columns[key] = val
          end
        }
        columns
      end
      
      def _create(req=request)
        obj = model.new
        columns = allowed_request_columns(req)
        Dcmgr.logger.debug("_create columns: " + columns.inspect)
        obj.set_all(columns)
        obj.save
      end
      
      def create
        _create
      end
      
      def update(req=request)
        obj = model[uuid]
        raise "unkown uuid: #{uuid}" unless obj
        columns = allowed_request_columns(req)
        Dcmgr.logger.debug("_update columns: " + columns.inspect)
        obj.set_all(columns)
        obj.save
      end
      
      def destroy
        obj = model[uuid]
        obj.destroy
      end
      
      def initialize(user, request)
        parsed_request = json_request(request)
        
        # log
        user_id = if user and user.is_a? Sequel::Model then user.id else 0 end
        user_uuid = if user.respond_to? :uuid
                    then user.uuid else "" end
        Models::Log.create(:user_id=>user_id,
                           :account_id=>parsed_request[:account].to_i,
                           :target_uuid=>user_uuid,
                           :action=>'login')
        
        @user = user
        @request = parsed_request
        @orig_request = request
      end
    end
  end
end
