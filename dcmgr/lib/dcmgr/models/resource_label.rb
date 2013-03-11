# -*- coding: utf-8 -*-

module Dcmgr::Models
  class ResourceLabel < BaseNew

    T_STRING=[1, :string_value, proc{|v| v.to_s }].freeze
    T_BLOB=[2, :blob_value, proc{|v| v.to_s }].freeze

    # dataset 
    module LabelDatasetMethods
      def label(name)
        self.find(:name=>name)
      end
      
      def set_label(name, value)
        l = self.find(:name=>name)
        if l
          l.value = value
          l.save_changes
          l
        else
          self.create(:name=>name, :value=>value)
        end
      end

      def unset_label(name)
        self.destroy(:name=>name)
      end

      def set_labels(tuples)
        tuples.each { |l|
          case l
          when Array
            set_label(l[0], l[1])
          when Hash
            set_label(l[:name], l[:value])
          end
        }
      end

      def unset_labels(*names)
        names.each { |n|
          unset_label(n)
        }
      end
    end
    
    def value()
      t = case self.value_type
          when T_STRING[0]
            T_STRING
          when T_BLOB[0]
            T_BLOB
          else
            T_STRING
          end

      self.__send__(t[1])
    end

    def value=(v)
      t = case v
          when String
            if v.bytesize <= 255
              T_STRING
            else
              T_BLOB
            end
          else
            T_STRING
          end

      self.value_type = t[0]
      self.__send__("#{t[1]}=", t[2].call(v))
      v
    end
  end
end
