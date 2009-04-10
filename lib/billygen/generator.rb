gem 'rdoc', '>= 2.4.0'
require 'rdoc/rdoc'
require 'yaml'


class RDoc::Generator::Billygen

  def self.for(options)
    new(options)
  end


  def initialize(options)
    @options = options
    @options.diagram = false
  end


  def generate(top_levels)
    reset
    top_levels.each { |tl| Billygen::CodeObjects::BFile.find_or_create(tl) }
    Billygen::RDocWorkarounds::postprocess
    @out = Billygen::Manifest.new(@options)

    File.open('rdocdump.yml', 'w') { |f| f << @out.to_yaml }
  end


  # Clear all saved global data.
  def reset
    Billygen::CodeObjects::BCodeObject.complete_store = {}
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
