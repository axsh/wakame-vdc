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

      def allow_keys(keys=nil)
        return @allow_keys unless keys
        @allow_keys = keys
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
          rescue StandardError => e
            logger.info "err! %s" % e.to_s
            logger.info "  " + e.backtrace.join("\n  ")
            throw :halt, [400, e.to_s]
          end
          
          logger.debug "response(inspect): " + ret.inspect
          json_ret = public_class.json_render(ret)
          logger.debug "response(json): " + json_ret
          json_ret
        end
      end
      
      def json_render(obj)
        def model2hash i
          h = Hash.new
          i.keys.each{ |key|
            h[key] = i.send(key)
          }

          # strip id, change uuid to id
          id = h.delete :id
          uuid = h.delete :uuid
          h[:id] = uuid if uuid
          h
        end
        
        if obj.is_a? Array
          ret = obj.collect{|i| model2hash(i)}
        elsif obj == nil
          ret = nil
        else
          ret = model2hash(obj)
        end
        ret.to_json
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

    def format_object(object)
      if object
        def object.keys
          keys = super
          # change from xxx_id to xxx
          keys.map! {|k|
            if /^(.*)_id$/ =~ k.to_s
              $1.to_sym
            else
              k
            end
          }
          keys.push :tags if self.respond_to? :tags
          keys  
        end
        def object.tags
          super.map{|t| t.uuid} # format only tags uuid
        end
        def object.account
          return nil unless super
          super.uuid
        end
        def object.hv_agent
          return nil unless super
          super.uuid
        end
        def object.user
          return nil unless super
          super.uuid
        end
        def object.relate_user
          return nil unless super
          super.uuid
        end
        def object.physical_host
          return nil unless super
          super.uuid
        end
        def object.image_storage
          return nil unless super
          super.uuid
        end
      end
      object
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
      filter.limit(limit, offset).map{|o| format_object(o)}
    end
    
    def get
      format_object(model[uuid])
    end

    def _create(req_hash=nil)
      req_hash = request unless req_hash
      obj = model.new

      if allow_keys
        allow_keys.each{|k|
          if k == :user
            obj.user = user
          elsif not req_hash[k].nil? # through false
            if k == :account
              obj.account = Account[req_hash[k]]
            else
              Dcmgr.logger.debug("set: #{k} = #{req_hash[k]}")
              obj.send('%s=' % k, req_hash[k])
            end
          end
        }
      else
        obj.set_all(req_hash)
      end

      obj.save
    end
    
    def create
      format_object(_create())
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
      format_object(obj.save)
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
