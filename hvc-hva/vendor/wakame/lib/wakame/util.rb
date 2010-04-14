

require 'digest/sha1'
require 'hmac-sha1'
require 'open4'

module Wakame
  module Util

    def ssh_known_hosts_hash(hostname, key=nil)
      # Generate 20bytes random value
      key = Array.new(20).collect{rand(0xFF).to_i}.pack('c*') if key.nil?
      
      "|1|#{[key].pack('m').chop}|#{[HMAC::SHA1.digest(key, hostname)].pack('m').chop}"
    end
    module_function :ssh_known_hosts_hash


    def gen_id(str=nil)
      Digest::SHA1.hexdigest( (str.nil? ? rand.to_s : str) )
    end
    module_function :gen_id


    def build_const(name)
      name.to_s.split(/::/).inject(Object) {|c,name| c.const_get(name) }
    end
    module_function :build_const

    
    def new_(class_or_str, *args)
      if class_or_str.is_a? Class
        class_or_str.new(*args)
      else
        c = build_const(class_or_str.to_s)
        c.new(*args)
      end
    end
    module_function :new_


    # Copied from http://github.com/ezmobius/nanite/
    ##
    # Convert to snake case.
    #
    #   "FooBar".snake_case           #=> "foo_bar"
    #   "HeadlineCNNNews".snake_case  #=> "headline_cnn_news"
    #   "CNN".snake_case              #=> "cnn"
    #
    # @return [String] Receiver converted to snake case.
    #
    # @api public
    def snake_case(const)
      const = const.to_s
      return const.downcase if const =~ /^[A-Z\d]+$/
      const.gsub(/\B([A-Z\d]+)|([A-Z]+)(?=[A-Z][a-z]?)/, '_\&') =~ /_*(.*)/
      return $+.downcase.gsub(/[_]+/, '_')
    end
    module_function :snake_case

    # Copied from http://github.com/ezmobius/nanite/
    ##
    # Convert a constant name to a path, assuming a conventional structure.
    #
    #   "FooBar::Baz".to_const_path # => "foo_bar/baz"
    #
    # @return [String] Path to the file containing the constant named by receiver
    #   (constantized string), assuming a conventional structure.
    #
    # @api public
    def to_const_path(const)
      snake_case(const).gsub(/::/, "/")
    end
    module_function :to_const_path


    def exec(command, &capture)
      outputs = []
      Wakame.log.debug("#{self}.exec(#{command})")
      cmdstat = ::Open4.popen4(command) { |pid, stdin, stdout, stderr|
        stdout.each { |l|
          capture.call(l, :stdout) if capture
          outputs << l
        }
        stderr.each { |l|
          capture.call(l, :stderr) if capture
          outputs << l
        }
      }
      Wakame.log.debug(outputs.join(''))
      raise "Command Failed (exit=#{cmdstat.exitstatus}): #{command}" unless cmdstat.exitstatus == 0
    end
    module_function :exec

    def spawn(command, &capture)
      outputs = []
      Wakame.log.debug("#{self}.spawn(#{command})")
      cmdstat = ::Open4.popen4(command) { |pid, stdin, stdout, stderr|
        stdout.each { |l|
          capture.call(l, :stdout) if capture
          outputs << l
        }
        stderr.each { |l|
          capture.call(l, :stderr) if capture
          outputs << l
        }
      }
      Wakame.log.debug(outputs.join(''))
      cmdstat
    end
    module_function :spawn

  end
end


module ThreadImmutable
  class IllegalCrossThreadMethodCall < StandardError; end


  module ClassMethods
    def thread_immutable_methods(*args)
      return if args.empty?
      
      args.each { |n|
        # Proc can not be passed a block due to 1.8's limitation. The following will work in 1.9.
        #um = instance_method(n) || next
        #define_method(n) { |*args, &blk|
        #  thread_check
        #  um.bind(self).call(*args, &blk)
        #}

        if method_defined?(n)
          alias_method "#{n}_no_thread_check", n.to_sym
          
          eval <<-__E__
          def #{n}(*args, &blk)
            thread_check
            #{n}_no_thread_check(*args, &blk)
          end
          __E__
        end
      }
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end

#   def self.included(klass)
#     klass.class_eval {
#       _um_constructor = self.instance_method(:initialize)
#       if _um_constructor
#         define_method(:initialize) { |*args|
#           bind_thread
#           _um_constructor.bind(self).call(*args)
#         }
#       end
#     }
#   end

  #      def self.method_added2(name)
  #        if name == :initialize
  #
  #          _um_constructor = instance_method(:initialize)
  #          define_method(:initialize) { |*args|
  #            bind_thread
  #            _um_constructor.bind(self).call(*args)
  #          }
  #        end
  #      end


  def bind_thread(thread=Thread.current)
    @target_thread = thread
    #puts "bound thread: #{@target_thread.inspect} to #{self.class} object"
  end

  def thread_check
    #puts "@target_thread == Thread.main : #{@target_thread == Thread.main}"
    raise "Thread is not bound." if @target_thread.nil?
    raise IllegalCrossThreadMethodCall unless target_thread?
  end

  def target_thread?(t=Thread.current)
    @target_thread == t
  end


  def target_thread
    @target_thread
  end

end



module AttributeHelper

  CLASS_TYPE_KEY=:class_type
  PRIMITIVE_CLASSES=[NilClass, TrueClass, FalseClass, Numeric, String, Symbol]
  CONVERT_CLASSES={Time => proc{|i| i.to_s } }

  module ClassMethods
    def attr_attributes
      @attr_attributes ||= {}
    end

    def merged_attr_attributes
      hash = {}

      deep_merge = proc {|key,v1,v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &deep_merge) : v2}

      self.ancestors.reverse.each { |klass|
        next unless klass.include?(AttributeHelper)
        hash.merge!(klass.attr_attributes, &deep_merge)
      }
      hash
    end

    def get_attr_attribute(attr_name)
      merged_attr_attributes[attr_name]
    end

    # Update attr_attributes[name][:default] value.
    # This works for existing name key.
    def update_attribute(name, v)
      attr_attr = get_attr_attribute(name.to_sym)
      raise "No such defined attribute: #{name}" if attr_attr.nil?
      attr_attributes[name.to_sym] ||= {}
      attr_attributes[name.to_sym].merge!({:default=>v})
      name
    end

    def def_attribute(name, *args)
      attr = begin 
               if args.size == 0
                 {:default=>nil}
               else
                 case args[0]
                 when Hash
                   args[0].dup
                 else
                   {:default=>args[0]}
                 end
               end
             end
      (attr_attributes[name.to_sym] ||= {}).merge!(attr)

      attr = self.merged_attr_attributes

      if attr[:read_only]
        if self.respond_to? "#{name}=".to_sym
          class_eval %Q{
            undef_method "#{name}=".to_sym
          }
        end
      else
        class_eval <<-__E__
        def #{name}=(v)
          @#{name}=v
        end

        public :#{name}=
        __E__
      end

      class_eval <<-__E__
      def #{name}
        if @#{name}.nil?
          a = self.class.get_attr_attribute(:#{name})
          if a
            defval = a[:default]
            @#{name} = case defval
                       when Proc
                         defval.call(self)
                       else
                         defval.dup rescue defval
                       end
          end
        end
        @#{name}
      end

      public :#{name}
      __E__
    end
    
  end

  private
  def self.included(klass)
    klass.extend ClassMethods
  end


  public
  def dump_attrs(root=nil, &blk)
    if root.nil? 
      root = self
    end

    return dump_internal(root, &blk)
  end
  #thread_immutable_method :dump_attrs if self.kind_of?(ThreadImmutable)
  #module_function :dump_attrs

  def retrieve_attr_attribute(&blk)
    self.class.ancestors.each { |klass|
      blk.call(klass.attr_attributes) if klass.include?(AttributeHelper)
    }
  end

  private
  def dump_internal(root, &blk)
    case root
    when AttributeHelper
      t={}
      t[CLASS_TYPE_KEY] = root.class.to_s

      default_dumper = lambda { |k|
        t[k] = dump_internal(root.__send__(k.to_sym), &blk)
      }

      self.class.merged_attr_attributes.each { |k,v|
        if blk
          blk.call(k,v, default_dumper)
        else
          default_dumper.call(k)
        end
      }
      t
    when Array
      root.collect { |a| dump_internal(a, &blk) }
    when Hash
      t={}
      root.each {|k,v| t[k] = dump_internal(v, &blk) }
      t
    else
      if CONVERT_CLASSES.any?{|t, p| root.kind_of?(t) }
        CONVERT_CLASSES[root.class].call(root)
      elsif PRIMITIVE_CLASSES.any?{|p| root.kind_of?(p) }
        root
      #elsif root.respond_to?(:dump_attrs)
        #dump_internal(root.dump_attrs)
      else
        raise TypeError, "#{root.class} does not support to dump attributes"
      end
    end
  end

end


class SortedHash < Hash
  def initialize
    @keyorder=[]
  end
  

  def store(key, value)
    raise TypeError, "#{key} is not Comparable" unless key.kind_of?(Comparable)
    if has_key?(key)
      ret = super(key, value)
    else
      ret = super(key, value)
      @keyorder << key
      @keyorder.sort!
      
    end
    ret
  end

  def []=(key, value)
    store(key, value)
  end

  def delete(key, &blk)
    if has_key?(key)
      @keyorder.delete(key)
      super(key, &blk)
    end
  end

  def keys
    @keyorder
  end

  def each(&blk)
    @keyorder.each { |k|
      blk.call(k, self[k])
    }
  end

  def first_key
    @keyorder.first
  end

  def first
    self[first_key]
  end

  def last_key
    @keyorder.last
  end

  def last
    self[last_key]
  end

  def clear
    super
    @keyorder.clear
  end

  def inspect
    str = "{"
    str << @keyorder.collect{|k| "#{k}=>#{self[k]}" }.join(', ')
    str << "}"
    str
  end

  def invert
    raise NotImplementedError
  end

end


module FilterChain
  def self.included(klass)
    klass.class_eval {
      def self.filter_chain
        @filter_chain ||= []
      end
      
      def self.append_filter(&blk)
        self.filter_chain << blk
      end
    }
  end

  def run_filter(pass_obj=nil)
    retrieve_filter_chain { |filter_chain|
      filter_chain.each { |filter_proc|
        begin
          ret = filter_proc.call(pass_obj)
        rescue => e
          ret = false
        end

        unless ret
          raise 
        end
      }
    }
  end

  private
  def retrieve_filter_chain(&blk)
    order = []
    self.class.ancestors.each { |klass|
      order << klass if klass.include?(FilterChain)
    }

    order.reverse.each { |klass|
      blk.call(klass.filter_chain) 
    }
  end
  
end


class ConditionalWait
  class TimeoutError < StandardError; end
  include ThreadImmutable

  def initialize(&blk)
    bind_thread
    @wait_queue = ::Queue.new
    @wait_tickets = []
    @poll_threads = []
    @event_tickets = []

    blk.call(self) if blk
  end
  
  def poll( period=5, max_retry=10, &blk)
    wticket = Wakame::Util.gen_id
    @poll_threads << Thread.new {
      retry_count = 0

      begin
        catch(:finish) {
          while retry_count < max_retry
            start_at = Time.now
            if blk.call == true
              throw :finish
            end
            Thread.pass
            if period > 0
              t = Time.now - start_at
              sleep (period - t) if period > t
            end
            retry_count += 1
          end
        }
        
        if retry_count >= max_retry
          Wakame.log.error('Over retry count')
          raise 'Over retry count'
        end

      rescue => e
        Wakame.log.error(e)
        @wait_queue << [false, wticket, e]
      else
        @wait_queue << [true, wticket]
      end
    }
    @poll_threads.last[:name]="#{self.class} poll"

    @wait_tickets << wticket
  end
  thread_immutable_methods :poll
  
  def wait_event(event_class, &blk)
    wticket = Wakame::Util.gen_id
    Wakame.log.debug("#{self.class} called wait_event(#{event_class}) on thread #{Thread.current} (target_thread=#{self.target_thread?}). has_blk=#{blk}")
    ticket = Wakame::EventDispatcher.subscribe(event_class) { |event|
      begin
        if blk.call(event) == true
          Wakame::EventDispatcher.unsubscribe(ticket)
          @wait_queue << [true, wticket]
        end
      rescue => e
        Wakame.log.error(e)
        Wakame::EventDispatcher.unsubscribe(ticket)
        @wait_queue << [false, wticket, e]
      end
    }
    @event_tickets << ticket

    @wait_tickets << wticket
  end
  thread_immutable_methods :wait_event

  def wait(tout=nil)

    unless @wait_tickets.empty?
      Wakame.log.debug("#{self.class} waits for #{@wait_tickets.size} num of event(s)/polling(s).")

      timeout(tout, TimeoutError) {
        while @wait_tickets.size > 0 && q = @wait_queue.shift
          @wait_tickets.delete(q[1])
          
          unless q[0]
            Wakame.log.debug("#{q[1]} failed with #{q[2]}")
            raise q[2]
          end
        end
      }
    end
    
  ensure
    # Cleanup generated threads/event tickets
    @poll_threads.each { |t|
      begin
        t.kill
      rescue => e
        Wakame.log.error(e)
      end
    }
    @event_tickets.each { |t| Wakame::EventDispatcher.unsubscribe(t) }
  end
  thread_immutable_methods :wait
  
  def self.wait(timeout=60*30, &blk)
    cond = ConditionalWait.new
    cond.bind_thread(Thread.current)
    
    #cond.instance_eval(&blk)
    blk.call(cond)
    
    cond.wait(timeout)
  end
  
end
