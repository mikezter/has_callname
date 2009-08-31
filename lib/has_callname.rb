module HasCallname
  def self.included(base)  
    base.send :extend, InclusionMethods

  end  

  module InclusionMethods

    # set database callname column
    # set column from which to create the callname
    # gsubs define which letters or words should be gsubbed 
    # filters define which letters or words should be deleted
    def has_callname(*args)
      options = args.extract_options!
      
      if args[0].is_a?(Symbol) or args[0].is_a?(String)
        options[:name] ||= args[0].to_s
        options[:callname] ||= args[0].to_s
      end
      
      cattr_accessor :build_callname_from
      cattr_accessor :callname_attribute
      cattr_accessor :additional_filters
      cattr_accessor :additional_gsubs
      cattr_accessor :prefix
      cattr_accessor :suffix
      
      self.build_callname_from = (options[:name] || :name)
      self.callname_attribute = (options[:callname] || :callname)
      self.additional_gsubs = (options[:gsubs] || {})
      self.suffix = (options[:suffix] || '')
      self.prefix = (options[:prefix] || '')
      
      
      if options[:filters].is_a? String
        self.additional_filters = [options[:filters]]
      elsif options[:filters].is_a? Array
        self.additional_filters = options[:filters]
      else
        self.additional_filters = []
      end
      
      send :include, InstanceMethods
      send :extend, ClassMethods
      send :before_create, :generate_callname

      alias_method_chain :method_missing, :callname
      

      
      
      unless options[:unique] == false
        alias_method_chain :create_callname, :add_counter
        send :validates_uniqueness_of, self.callname_attribute, :case_sensitive => false
      end

    end
  end
  
  module ClassMethods
    # finds the first record with matching callname
    # should never be more than one with a given callname though
    
    def method_missing(m, *args)
      if m.to_s == "find_by_#{self.callname_attribute}"
        cn = args[0]
        c = self.find(:first, :conditions => {self.callname_attribute => cn})
        raise ActiveRecord::RecordNotFound, "Couldn't find #{self.class.name} with #{self.callname_attribute} #{cn}" unless c.is_a? self
        return c
      else
        super
      end
    end
  end
  
  
  module InstanceMethods
    
    def method_missing_with_callname(m, *args)
      if m.to_s == self.callname_attribute.to_s
        cn = self.read_attribute(self.callname_attribute)
        cn = self.update_callname if cn.blank?
        return cn  
      else
        return method_missing_without_callname(m, *args)
      end
    end
    
    protected
    
    def generate_callname
      cn = self.create_callname self.send(self.build_callname_from)
      self.send "#{self.callname_attribute}=", cn
      return cn
    end
    
    def update_callname
      cn = self.generate_callname
      self.save unless self.new_record?
      return cn
    end

    def create_callname cn
      cn = cn.dup
      cn.downcase!
      self.additional_gsubs.each  {|k, v| cn.gsub!(k, v)}
      self.additional_filters.each {|w| cn.gsub!(w, '')}
      cn.gsub!(/\303\244/, 'ae') 
      cn.gsub!(/\303\204/, 'ae') 
      cn.gsub!(/\303\226/, 'oe') 
      cn.gsub!(/\303\266/, 'oe') 
      cn.gsub!(/\303\234/, 'ue') 
      cn.gsub!(/\303\274/, 'ue') 
      cn.gsub!(/\303\237/, 'ss')
      cn.gsub!(/[^a-z0-9]+/i, '-')
      cn.gsub!(/(^[-]+|[-]+$)/, '')
      return "#{self.prefix}#{cn}#{self.suffix}"
    end
    
    def create_callname_with_add_counter cn
      cn = self.create_callname_without_add_counter cn
      objects = self.class.find(:all, :conditions => "#{self.callname_attribute} LIKE '#{cn}%'")
      objects.delete_if { |object| not object.send("#{self.callname_attribute}").match(/\A#{cn}-?\d*\Z/i) }
      count = objects.size
      return count > 0 ? "#{cn}-#{count + 1}" : cn
    end
  end
  
end
  

