module Billygen::CodeObjects

  # This is the superclass of any given code artifact, from a file to a class
  # to a method to a 'require' statement & etc.
  class BCodeObject

    attr_accessor :bid
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
      return nil if @parent_id == bid && @parent_collection == self.class.key
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


    # Outputter returns information on the renderer that should be used to 
    # transform the comment into HTML. If the result is +:rdoc+, then 
    # the file's +description+ should be used. Otherwise, operate directly
    # on the comment.
    #
    # If the file is a source file (ie, contains active code), this always 
    # returns +:rdoc+.
    #
    # The formats here should mirror Github's detection of README formats.
    # However, formats treated by Github as 'no formatting' are here considered
    # to be +:rdoc+.
    # See: http://github.com/guides/readme-formatting
    #
    # Currently, the possible outputter values are:
    # - +:rdoc+
    # - +:markdown+
    # - +:textile+
    # - +:png+
    # - +:restructured_text+
    #
    def outputter
      return @outputter ||= :rdoc unless format == 'text'

      @outputter ||= case File.extname(full_name)
        when '.textile'
          :textile
        when '.png'
          :png
        when '.rst'
          :restructured_text
        when *['.md', '.markdown', '.mdown', '.mkd', '.mkdn']
          :markdown
        else
          :rdoc
      end
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
        if src.superclass.is_a?(String)
          puts "String superclass for #{self.long_name}: #{src.superclass}"
          @superclass_id = src.superclass
        else
          @superclass_id = BClass.find_or_create(src.superclass).bid
        end
      end
    end


    def superclass
      if @superclass_id == bid
        # Not sure how you can be a subclass of yourself?
        nil
      elsif @superclass_id.is_a?(String)
        # Yeah this is a hack. It gets around an RDoc bug, where it fails to
        # provide a superclass object if it's in the same file as this class --
        # giving just a name instead.
        #
        # Of course this workaround is imperfect, because the RDoc superclass
        # name is not fully qualified. So if you have a class called
        # Billygen::Object for example, then all subclasses of Ruby's core 
        # Object class will be considered a subclass of that class instead. Ugh.
        BClass.store.find {|klass| klass.name == @superclass_id} ||
          @superclass_id
      else
        BClass.store[@superclass_id]
      end
    end


    def subclasses
      BClass.store.select {|klass| klass.superclass == self}
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
