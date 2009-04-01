class Billygen::Manifest

  attr_reader :rdoc_options, :data


  def initialize(options)
    @rdoc_options = {
      :title => options.title,
      :main_page => options.main_page,
      :files => options.files,
      :line_numbers => options.include_line_numbers,
      :charset => options.charset,
      :tab_width => options.tab_width,
      :version => Billygen::VERSION
    }
    @data = Billygen::CodeObjects::BCodeObject.complete_store
  end


  def restore
    Billygen::CodeObjects::BCodeObject.complete_store = @data
  end


  def method_missing(mthd, *args)
    data[mthd.to_s] ? data[mthd.to_s] : super
  end

end
