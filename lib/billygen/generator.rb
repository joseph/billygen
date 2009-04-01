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
    Billygen::RDocWorkarounds::postprocess
    @out = Billygen::Manifest.new(@options)

    File.open('rdocdump.yml', 'w') { |f| f << @out.to_yaml }
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
