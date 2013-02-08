module Sirportly
  class DataObject
    
    class << self
      attr_accessor :collection_path
      attr_accessor :member
      attr_accessor :maps
      
      def all(client, options = {})
        raise Sirportly::Error, "This object does not support a full list" if collection_path.nil?
        result = client.request(collection_path, options)
        DataSet.new(client, result, self)
      end
      
      def find(client, query)
        raise Sirportly::Error, "This object does not support finding objects" unless member.is_a?(Hash)
        result = client.request(member[:path], {member[:param] => query})
        self.new(client, result)
      end
      
    end
    
    attr_reader :attributes
    attr_reader :client
    
    def initialize(client, attributes = {})
      @client = client
      set_attributes(attributes)
    end
    
    def inspect
      "#<#{self.class.to_s} #{attributes.inspect}>"
    end
    
    def method_missing(name)
      if attributes.keys.include?(name.to_s)
        attributes[name.to_s]
      else
        super
      end
    end
    
    private
    
    def set_attributes(attributes)
      @attributes = attributes.inject({}) do |hash, (k,v)|
        case k
        when /\_(at|on)\Z/
          hash[k] = v ? Time.parse(v) : nil
        when /minutes\_since/
          hash[k] = v.to_f
        else
          hash[k] = v          
          if self.class.maps.is_a?(Hash) && klass_name = self.class.maps[k]
            if v.is_a?(Array)
              hash[k] = v.map { |p| Sirportly.const_get(klass_name).new(@client, p) }
            elsif v.is_a?(Hash)
              hash[k] = Sirportly.const_get(klass_name).new(@client, v)
            end
          end
        end
        hash
      end
    end
        
  end
end
