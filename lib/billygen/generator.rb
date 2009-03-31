gem 'rdoc', '>= 2.0.0'
require 'rdoc/rdoc'
require 'yaml'


class RDoc::Generator::BillyGen

  def self.for(options)
    new(options)
  end


  def initialize(options)
    @options = options
    @options.diagram = false
  end


  def generate(top_levels)
    top_levels.each { |tl| Billygen::CodeObjects::BFile.find_or_create(tl) }
    tidy_parents
    @out = Billygen::Manifest.new(@options)

    File.open('rdocdump.yml', 'w') { |f| f << @out.to_yaml }
  end


  # This should be unnecessary. Sometimes a parent is not recognised during
  # processing. We can go through all such orphans and try to find their 
  # parents.
  def tidy_parents
    classes_and_modules = Billygen::CodeObjects::BClass.store + 
      Billygen::CodeObjects::BModule.store
    orphans = classes_and_modules.select {|klass| !klass.parent }

    orphans.each { |orphan|
      parent = classes_and_modules.detect { |obj| 
        obj.modules.include?(orphan) ||
        obj.classes.include?(orphan) 
      }
      if parent
        orphan.instance_variable_set(:@parent_id, parent.bid)
        orphan.instance_variable_set(:@parent_collection, parent.class.key)
        puts "Associated orphan #{orphan.long_name} with parent #{parent.long_name}"
      end
    }
  end

  
  # Meaningless required RDoc fluff.
  def file_dir # :nodoc:
    nil
  end


  # Meaningless required RDoc fluff.
  def class_dir # :nodoc:
    nil
  end

end



class RDoc::CodeObject

  attr_accessor :bid, :billy_object

end


class RDoc::Context::Section

  attr_accessor :bid, :billy_object

end
