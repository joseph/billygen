module Billygen::CodeObjects

  # This is the superclass of any given code artifact, from a file to a class
  # to a method to a 'require' statement & etc.
  class BCodeObject

    attr_accessor :id
    attr_reader :comment, :description


    def self.complete_store
      @@complete_store ||= {}
    end


    # WARNING: setting this will invalidate any existing codeobjects
    def self.complete_store=(val)
      @@complete_store = val
    end


    def self.store
      complete_store[key] ||= []
    end


    def self.find_or_create(rdoc_code_object)
      result = nil
      if i = rdoc_code_object.billy_id
        result = self.store[i]
      else
        result = self.new
        self.store << result
        i = self.store.index(result)
        result.id = i
        rdoc_code_object.billy_id = i
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
        @parent_id = src.parent.billy_id
        @parent_collection = src.parent.billy_object.class.key
      end
    end


    def ids(klass, arr)
      arr.collect { |obj| klass.find_or_create(obj) }.collect { |obj| obj.id }
    end


    def parent
      return nil unless @parent_id && @parent_collection
      return nil if @parent_id == id && @parent_collection == self.class.key
      return nil if @parent_collection == "files"
      self.class.complete_store[@parent_collection][@parent_id]
    end

  end


  # A section is a whole or part of a file that contains code and comments.
  # It's probably not as useful as it sounds.
  class BSection < BCodeObject

    def self.key
      'sections'
    end

  end


  # Entirely analogous to the RDoc concept of a 'context', BContext represents
  # a thing that can contain any kind of code. Files, classes and modules in
  # Ruby are all 'contexts'.
  class BContext < BCodeObject

    attr_reader :name


    def process(src)
      super
      @name = src.name
      @section_id = BSection.find_or_create(src.current_section).id

      @file_ids = ids(BFile, src.in_files)
      @section_ids = ids(BSection, src.sections)
      @module_ids = ids(BModule, src.modules)
      @class_ids = ids(BClass, src.classes)
      @method_ids = ids(BMethod, src.method_list)
      @attribute_ids = ids(BAttribute, src.attributes)
      @alias_ids = ids(BAlias, src.aliases)
      @constant_ids = ids(BConstant, src.constants)
      @include_ids = ids(BInclude, src.includes)
      @require_ids = ids(BRequire, src.requires)
    end


    # The section in which this context is found.
    def section
      BSection.store[@section_id]
    end


    # The files in which this context exists. Not always just one file?
    def files
      @file_ids.collect { |idx| BFile.store[idx] }
    end


    # The sections this context contains.
    def sections
      @section_ids.collect { |idx| BSection.store[idx] }
    end
    

    # All the modules defined or re-opened in this context.
    def modules
      @module_ids.collect { |idx| BModule.store[idx] }
    end


    # All the classes defined or re-opened in this context.
    def classes
      @class_ids.collect { |idx| BClass.store[idx] }
    end


    # The methods defined in this context.
    # FIXME: I don't think we should override this...
    def methods
      @method_ids.collect { |idx| BMethod.store[idx] }
    end


    # If this context is a class, the attributes of this class.
    # FIXME: or this...
    def attributes
      @attribute_ids.collect { |idx| BAttribute.store[idx] }
    end


    # Method aliases defined in this context.
    def aliases
      @alias_ids.collect { |idx| BAlias.store[idx] }
    end


    # Constants defined in this context.
    def constants
      @constant_ids.collect { |idx| BConstant.store[idx] }
    end


    # Modules included in this module or class.
    def includes
      @include_ids.collect { |idx| BInclude.store[idx] }
    end


    # Source files for which a 'require' statement is found in this context.
    def requires
      @require_ids.collect { |idx| BRequire.store[idx] }
    end


    def full_name
      @full_name ||= (parent ? "#{parent.full_name}::#{name}" : name)
    end

  end


  # Represents a source file, or a text file (such as a README) found by RDoc.
  class BFile < BContext

    attr_reader :format, :last_modified, :absolute_name, :full_name


    def self.key
      'files'
    end


    # In addition to standard BContext processing, this detects the file
    # format based on the parser class.
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


    # Returns a nested hash of arrays of files, in the form of a tree.
    # 
    # Files are stored under directory keys in the '.' key. For example,
    # this directory structure:
    #
    #     README.md
    #     lib/
    #       billygen.rb
    #       billygen/
    #         code_objects.rb
    #         generator.rb
    #         manifest.rb
    #
    # ... will generate this hash:
    #   
    #     {
    #       "." => ["README.md"],
    #       "lib" => {
    #         "." => ["billygen.rb"],
    #         "billygen" => {
    #           "." => ["code_objects.rb", "generator.rb", "manifest.rb"]
    #         }
    #       }
    #     }
    #
    # ... where the filenames in the hash above are actually BFile objects.
    #
    def self.tree
      t = {}
      store.each do |file|
        file_dirs = file.full_name.split(File::SEPARATOR)
        file_dirs.pop
        branch = t
        file_dirs.each { |dir| branch = (branch[dir] ||= {}) }
        branch['.'] ||= []
        branch['.'] << file
      end
      t
    end

  end


  # MODULE
  class BModule < BContext

    # Returns 'modules'.
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
        factory = src.superclass.is_a?(String) ? BExternalClass : BClass
        @superclass_id = factory.find_or_create(src.superclass).id
      end
    end


    def superclass
      return nil unless @superclass_id
      return nil if @superclass_id == id
      self.class.store[@superclass_id]
    end


    def subclasses
      BClass.store.select { |klass| klass.superclass == self }
    end


    def external?
      false
    end

  end

  # RDoc gives a string if a superclass object isn't found in the source.
  # This usually means the superclass is in an external library. For API 
  # neatness, we transform this string into a stub object that behaves like
  # a top-level class object.
  class BExternalClass < BClass
    
    def self.find_or_create(str)
      result = nil
      unless result = self.store.detect { |klass| klass.name == str }
        result = self.new
        self.store << result
        i = self.store.index(result)
        result.id = i
        result.process(str)
      end
      result
    end


    def process(str)
      @name = str

      @file_ids = []
      @section_ids = []
      @module_ids = []
      @class_ids = []
      @method_ids = []
      @attribute_ids = []
      @alias_ids = []
      @constant_ids = []
      @include_ids = []
      @require_ids = []
    end


    def superclass
      nil
    end


    def external?
      true
    end

  end



  # Superclass of methods, aliases, constants, attributes, etc
  class BUnit < BCodeObject

    attr_reader :name

    def process(src)
      super
      @name = src.name if src.respond_to?(:name)
      @section_id = BSection.find_or_create(src.section).id
      #@path = src.path
    end


    def section
      BSection.store[@section_id]
    end

  end


  # METHOD
  class BMethod < BUnit

    attr_reader :type, :params, :call_seq, :markup_code, :aref

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
      @alias_ids = ids(BMethod, src.aliases)
      @aref = src.aref
      # FIXME: block_params, is_alias_for, singleton
    end


    def aliases
      @alias_ids.collect {|idx| BMethod.store[idx]}
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
          @module_id = BModule.find_or_create(src.module).id
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
