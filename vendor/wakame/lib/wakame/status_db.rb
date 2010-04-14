
require 'thread'
require 'timeout'

module Wakame
  module StatusDB

    def self.pass(&blk)
      if Thread.current == WorkerThread.worker_thread
        blk.call
      else
        WorkerThread.queue.enq(blk)
      end
    end
    
    def self.barrier(tout=60*2, &blk)
      abort "Cant use barrier() in side of the EventMachine thread." if Kernel.const_defined?(:EventMachine) && ::EventMachine.reactor_thread?

      if Thread.current == WorkerThread.worker_thread
        return blk.call
      end
      
      Wakame.log.debug("StatusDB.barrier: Called at #{caller(1)[0..1].inspect} on the thread #{Thread.current}.")

      q = ::Queue.new
      time_start = ::Time.now
      
      self.pass {
        begin
          res = blk.call
          q << [true, res]
        rescue => e
          q << [false, e]
        end
      }

      res = nil
      begin
        timeout(tout) do
          res = q.shift
        end
      rescue Timeout::Error => e
        Wakame.log.error("WorkerThread.queue.size=#{WorkerThread.queue.size}")
        Wakame.log.error(e)
        raise e
      end

      time_elapsed = ::Time.now - time_start
      Wakame.log.debug("#{self}.barrier: Elapsed time for #{blk}: #{time_elapsed} sec") if time_elapsed > 0.05

      if res[0] == false && res[1].is_a?(Exception)
        raise res[1]
      end
      res[1]
    end
    
    class WorkerThread

      def self.queue
        @queue ||= ::Queue.new
      end

      def self.worker_thread
        @thread 
      end

      def self.init
        @proceed_reqs = 0

        if @thread.nil?
          @thread = Thread.new {
            while blk = queue.deq
              Wakame.log.debug("#{self}: Queued Jobs: #{queue.size}") if queue.size > 0
              begin
                Wakame::Models::ObjectStore.db.transaction {
                  blk.call
                }
              rescue => e
                Wakame.log.error("#{self.class}: #{e}")
                Wakame.log.error(e)
              end
              @proceed_reqs += 1
            end
          }
        end
      end

      def self.terminate
        if self.queue.size > 0
          Wakame.log.warn("#{self.class}: #{self.class.queue.size} of queued reqs are going to be ignored to shutdown the worker thread.")
          self.queue.clear
        end
        self.worker_thread.kill if !self.worker_thread.nil? && self.worker_thread.alive?
      end
    end


    def self.adapter
      @adapter ||= SequelAdapter.new
    end

    class SequelAdapter

      def initialize
        @model_class = Wakame::Models::ObjectStore
      end

      def find(id)
        Wakame.log.debug("StatusDB.find(#{id}) called by #{Thread.current.to_s}")  unless Thread.current == WorkerThread.worker_thread 
        m = @model_class[id]
        if m
          hash = eval(m[:dump])
          hash[AttributeHelper::CLASS_TYPE_KEY]=m.class_type
          hash
        else
          nil
        end
      end

      # Find all rows belong to given klass name.
      # Returns id list which matches class_type == klass
      def find_all(klass)
        ds = @model_class.where(:class_type=>klass.to_s)
        ds.all.map {|r| r[:id] }
      end

      def exists?(id)
        !@model_class[id].nil?
      end

      def save(id, hash)
        Wakame.log.debug("StatusDB.save(#{id}) called by #{Thread.current.to_s}") unless Thread.current == WorkerThread.worker_thread 
        m = @model_class[id]
        if m.nil? 
          m = @model_class.new
          m.id = id
          m.class_type = hash[AttributeHelper::CLASS_TYPE_KEY]
        end 
        m.dump = hash.inspect
        m.save
      end

      def delete(id)
        Wakame.log.debug("StatusDB.delete(#{id}) called by #{Thread.current.to_s}") unless Thread.current == WorkerThread.worker_thread 
        @model_class[id].destroy
      end

      def clear_store
      end
      
    end


    class Model
     include ::AttributeHelper

      module ClassMethods
        def enable_cache
          unless @enable_cache
            @enable_cache = true
            @_instance_cache = {}
          end
        end

        def disable_cache
          if @enable_cache
            @enable_cache = false
            @_instance_cache = {}
          end
        end

        def _instance_cache
          return {} unless @enable_cache

          @_instance_cache ||= {}
        end

        def find(id)
          raise "Can not retrieve the data with nil." if id.nil?
          obj = _instance_cache[id]
          return obj unless obj.nil?

          hash = StatusDB.barrier {
            StatusDB.adapter.find(id)
          }
          return nil unless hash

          if hash[AttributeHelper::CLASS_TYPE_KEY]
            klass_const = Util.build_const(hash[AttributeHelper::CLASS_TYPE_KEY])
          else
            klass_const = self
          end
          
          # klass_const class is equal to self class or child of self class
          if klass_const <= self
            obj = klass_const.new
          else
            raise "Can not instanciate the object #{klass_const.to_s} from #{self}"
          end
          
          obj.on_before_load
          
          obj.instance_variable_set(:@id, id)
          obj.instance_variable_set(:@load_at, Time.now)
          
          hash.each { |k,v|
            obj.instance_variable_set("@#{k}", v)
          }
          
          obj.on_after_load

          _instance_cache[id] = obj
          obj
        end


        def find_all
          StatusDB.barrier {
            StatusDB.adapter.find_all(self.to_s).map { |id|
              find(id)
            }
          }
        end

        def exists?(id) 
          StatusDB.barrier {
            _instance_cache.has_key?(id) || StatusDB.adapter.exists?(id)
          }
        end

        # A helper method to define an accessor with persistent flag.
        def property(key, opts={})
          case opts 
          when Hash
            opts.merge!({:persistent=>true})
          else
            opts = {:persistent=>true}
          end
          def_attribute(key.to_sym, opts)
        end

        def delete(id)
          obj = find(id)
          if obj
            obj.on_before_delete
            StatusDB.barrier {
              StatusDB.adapter.delete(id)
            }
            _instance_cache.delete(id)

            obj.on_after_delete 
          end
        end

      end

      def self.inherited(klass)
        klass.extend(ClassMethods)
        klass.class_eval {
          #include(::AttributeHelper)
          #enable_cache

          # Manually set attr option to get :id appeared in dump_attrs.
          attr_attributes[:id]={:persistent=>false}
        }
      end

      def id
        @id ||= Wakame::Util.gen_id
      end

      def new_record?
        @load_at.nil?
      end

      def dirty?
        raise NotImplementedError
      end

      def save
        #return unless dirty?

        validate_on_save

        self.class.merged_attr_attributes.each { |k,v|
          next unless v[:persistent]
          if v[:call_after_changed]
            case v[:call_after_changed]
            when Symbol
              self.__send__(v[:call_after_changed].to_sym) # if self.respond_to?(v[:call_after_changed].to_sym)
            when Proc
              v[:call_after_changed].call(self)
            end
          end
        }

        hash_saved = self.dump_attrs { |k,v,dumper|
          if v[:persistent] == true
            dumper.call(k)
          end
        }
        StatusDB.barrier {
          StatusDB.adapter.save(self.id, hash_saved)
        }
      end

      def delete
        self.class.delete(self.id)
      end

      def reload
        self.class._instance_cache.delete(self.id)
        hash = StatusDB.barrier {
          StatusDB.adapter.find(self.id)
        }
        if hash[AttributeHelper::CLASS_TYPE_KEY]
          klass_const = Util.build_const(hash[AttributeHelper::CLASS_TYPE_KEY])
        else
          klass_const = self.class
        end
        
        # klass_const class is equal to self class or child of self class
        unless klass_const <= self.class
          raise "The class \"#{klass_const.to_s}\" has no relationship to #{self.class}"
        end
        
        on_before_load
        
        @load_at = Time.now
        
        hash.each { |k,v|
          instance_variable_set("@#{k}", v)
        }
            
        on_after_load
      end

      # Callback methods
      
      # Called prior to copying data from database in self.find().
      def on_before_load
      end
      # Called after copying data from database in self.find().
      def on_after_load
      end

      def on_before_delete
      end

      def on_after_delete
      end

      protected

      def validate_on_save
      end


    end
    
  end
  
end
