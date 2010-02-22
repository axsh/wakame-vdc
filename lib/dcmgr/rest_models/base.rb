
module Dcmgr
  module RestModel
    module ClassMethods
      def get_actions
        @public_actions.each{|method, path, args, action|
          yield [method, path, route(self, method, action)]
        }
      end
      
      def public_action(method, name=nil, *args, &block)
        @public_actions ||= []
        @public_actions << [method, url_all(name), args, block]
      end
      
      def public_action_withid(method, name=nil, *args, &block)
        @public_actions ||= []
        @public_actions << [method, url_id(name), args, block]
      end
      
      def url_all(action_name=nil)
        if action_name
          "/#{public_name}/#{action_name}.json"
        else
          "/#{public_name}.json"
        end          
      end
      
      def url_id(action_name=nil)
        if action_name
          %r{/#{public_name}/(\w+-\w+)/#{action_name}.json}
        else
          %r{/#{public_name}/(\w+-\w+).json}
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
      
      def model(model_class=nil)
        return @model unless model_class
        @model = model_class
      end
      
      def public_name(name=nil)
        return (@public_name or @model.table_name.to_s) unless name
        @public_name = name
      end

      def json_request(request)
        ret = Hash.new
        
        request.GET.each{|k,v|
          ret[:"_get_#{k}"] = v
        }
        
        if request.content_length.to_i > 0
          body = request.body.read
          parsed = JSON.parse(body)
          Dcmgr.logger.debug("request: " + parsed.inspect)
        
          parsed.each{|k,v|
            ret[k.to_sym] = v
          }
        end
        Dcmgr.logger.debug("request: " + ret.inspect)
        ret        
      end

      def route(public_class, method, block)
        # Dcmgr::logger.debug "ROUTE: %s, %s, %s" % [self, public_class, block]
        proc do |*args|
          logger.debug "URL: #{method} #{request.url} #{args}"

          protected!
          
          begin
            parsed_request = public_class.json_request(request)

            # log
            Log.create(:user_id=>(if authorized_user then authorized_user.id else 0 end),
                       :account_id=>parsed_request[:account].to_i,
                       :target_uuid=>(if authorized_user.respond_to? :uuid then authorized_user.uuid else "" end),
                       :action=>'login')
            
            obj = public_class.new(authorized_user, parsed_request)
            obj.uuid = args[0] if args.length > 0
            
            ret = obj.instance_eval(&block)

            logger.debug "response(inspect): " + ret.inspect
            json_ret = obj.to_response(ret).to_json
            logger.debug "response(json): " + json_ret
            json_ret

          rescue StandardError => e
            logger.info "err! %s" % e.to_s
            logger.info "  " + e.backtrace.join("\n  ")
            throw :halt, [400, e.to_s]
          end
        end
      end
    end

    def self.included(mod)
      mod.extend ClassMethods
    end
    
    attr_accessor :uuid
    attr_accessor :user
    attr_accessor :request
    
    def model
      self.class.model
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
      keys = response_keys ? response_keys :
        object.keys.map{|key|
          if /^(.*)_id$/ =~ key.to_s then $1.to_sym else key end
        }

      ret = {}
      keys.each{|key|
        val = object.send(key)
        ret[key] = val
      }
      
      # strip id, change uuid to id
      id = ret.delete :id
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
        get_key = :"_get_#{key}"
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
        rescue Dcmgr::Model::InvalidUUIDError
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
      filter.limit(limit, offset)
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
          columns[key] = Account[val]
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

    def update
      obj = model[uuid]
      req_hash = request
      req_hash.delete :id
      allow_keys.each{|key|
        if key == :account # duplicate create
          obj.account = Account[req_hash[key]]
        elsif key == :user
            
        else req_hash.key?(key)
          obj.send('%s=' % key, req_hash[key])
        end
      }
      obj.save
    end
    
    def destroy
      obj = model[uuid]
      obj.destroy
    end

    def initialize(user, request)
      @user = user
      @request = request
    end
  end
end
