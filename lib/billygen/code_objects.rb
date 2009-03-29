module Billygen::CodeObjects

  # CODE OBJECT
  class BCodeObject

    attr_accessor :bid
    attr_reader :comment, :description


    def self.complete_store
      @@complete_store ||= {}
    end


    # WARNING: this will invalidate any existing codeobjects
    def self.complete_store=(val)
      @@complete_store = val
    end


    def self.store
      complete_store[key] ||= []
    end


    def self.find_or_create(rdoc_code_object)
      result = nil
      if i = rdoc_code_object.bid
        result = self.store[i]
      else
        result = self.new
        self.store << result
        i = self.store.index(result)
        result.bid = i
        rdoc_code_object.bid = i
        rdoc_code_object.billy_object = result
        result.process(rdoc_code_object)
      end

      return result
    end


    def self.key
      'unknowns'
    end


    def process(src)
      @comment = src.comment
      @description = src.description if src.respond_to?(:description)
      if src.parent && src.parent.billy_object
        @parent_id = src.parent.bid
        @parent_collection = src.parent.billy_object.class.key
      end
    end


    def bids(klass, arr)
      arr.collect {|obj| klass.find_or_create(obj)}.collect {|obj| obj.bid}
    end


    def parent
      return nil unless @parent_id && @parent_collection
      return nil if @parent_id == bid
      return nil if @parent_collection == "files"
      self.class.complete_store[@parent_collection][@parent_id]
    end

  end


  # SECTION
  class BSection < BCodeObject

    def self.key
      'sections'
    end


    def process(src)
      super
    end

  end


  # CONTEXT
  class BContext < BCodeObject

    attr_reader :name


    def process(src)
      super
      @name = src.name
      @section_id = BSection.find_or_create(src.current_section).bid

      @file_ids = bids(BFile, src.in_files)
      @section_ids = bids(BSection, src.sections)
      @module_ids = bids(BModule, src.modules)
      @class_ids = bids(BClass, src.classes)
      @method_ids = bids(BMethod, src.method_list)
      @attribute_ids = bids(BAttribute, src.attributes)
      @alias_ids = bids(BAlias, src.aliases)
      @constant_ids = bids(BConstant, src.constants)
      @include_ids = bids(BInclude, src.includes)
      @require_ids = bids(BRequire, src.requires)
    end


    def section; BSection.store[@section_id]; end


    def files; @file_ids.collect { |idx| BFile.store[idx] }; end
    def sections; @section_ids.collect { |idx| BSection.store[idx] }; end
    def modules; @module_ids.collect { |idx| BModule.store[idx] }; end
    def classes; @class_ids.collect { |idx| BClass.store[idx] }; end
    def methods; @method_ids.collect { |idx| BMethod.store[idx] }; end
    def attributes; @attribute_ids.collect { |idx| BAttribute.store[idx] }; end
    def aliases; @alias_ids.collect { |idx| BAlias.store[idx] }; end
    def constants; @constant_ids.collect { |idx| BConstant.store[idx] }; end
    def includes; @include_ids.collect { |idx| BInclude.store[idx] }; end
    def requires; @require_ids.collect { |idx| BRequire.store[idx] }; end

    def long_name
      parent && !parent.is_a?(BFile) ? "#{parent.long_name}::#{name}" : name
    end

  end


  # FILE
  class BFile < BContext

    attr_reader :format, :last_modified, :absolute_name, :full_name


    def self.key
      'files'
    end


    def process(src)
      super
      @format = case src.parser.to_s
        when 'RDoc::Parser::PerlPOD'
          'perl'
        when 'RDoc::Parser::C'
          'c'
        when 'RDoc::Parser::Simple'
          'text'
        else
          'ruby'
      end

      @last_modified = src.last_modified
      @absolute_name = src.absolute_name
      @full_name = src.full_name
    end

  end


  # MODULE
  class BModule < BContext

    def self.key
      'modules'
    end

  end

  
  # CLASS
  class BClass < BContext

    def self.key
      'classes'
    end


    def process(src)
      super
      if src.superclass
        if src.superclass.is_a?(String)
          @superclass_id = src.superclass.to_s
        #if src.superclass.kind_of?(RDoc::CodeObject)
        else
          @superclass_id = BClass.find_or_create(src.superclass).bid
        end
      end
    end


    def superclass
      if @superclass_id == bid
        nil
      elsif @superclass_id.is_a?(String)
        @superclass_id
      else
        BClass.store[@superclass_id]
      end
    end

  end


  # Superclass of methods, aliases, constants, attributes, etc
  class BUnit < BCodeObject

    attr_reader :name

    def process(src)
      super
      @name = src.name
      @section_id = BSection.find_or_create(src.section).bid
      #@path = src.path
    end


    def section
      BSection.store[@section_id]
    end

  end


  # METHOD
  class BMethod < BUnit

    attr_reader :type, :params, :call_seq, :markup_code

    def self.key
      'methods'
    end


    def process(src)
      super
      @type = src.type # class or instance
      @params = src.params
      if src.call_seq
        @call_seq = src.call_seq.strip.gsub(/->/,'&rarr;').gsub(/^\w.*?\./m, '')
      end
      @markup_code = src.markup_code
      @alias_ids = bids(BMethod, src.aliases)
      # FIXME: block_params, is_alias_for, singleton
    end


    def aliases
      @alias_ids.collect {|idx| BMethod.store[idx]}
    end


    def signature
      (type == "class" ? "self." : "") + name + params
    end

  end

  
  # ALIAS
  class BAlias < BUnit

    attr_reader :aliased_name, :aliasee_name


    def self.key
      'aliases'
    end


    def process(src)
      super
      @aliased_name = src.new_name
      @aliasee_name = src.old_name
    end

  end


  # ATTRIBUTE
  class BAttribute < BUnit

    attr_reader :rw


    def self.key
      'attributes'
    end


    def process(src)
      super
      @rw = src.rw
    end

  end


  # CONSTANT
  class BConstant < BUnit

    attr_reader :value


    def self.key
      'constants'
    end


    def process(src)
      super
      @value = src.value
    end

  end


  # INCLUDE
  class BInclude < BUnit

    def self.key
      'includes'
    end


    def process(src)
      super
      if src.module
        if src.module.kind_of?(RDoc::CodeObject)
          @module_id = BModule.find_or_create(src.module).bid
        else
          @module_id = src.module.to_s
        end
      end
    end


    def module
      if @module_id.is_a?(String)
        @module_id
      else
        BModule.store[@module_id]
      end
    end

  end


  # REQUIRE
  class BRequire < BUnit

    def self.key
      'requires'
    end

  end

end
