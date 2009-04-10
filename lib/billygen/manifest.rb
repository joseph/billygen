class Billygen::Manifest

  attr_reader :rdoc_options, :data


  def initialize(options)
    @rdoc_options = {
      :title => options.title,
      :files => options.files,
      :line_numbers => options.include_line_numbers,
      :charset => options.charset,
      :tab_width => options.tab_width,
      :version => Billygen::VERSION
    }

    file = Billygen::CodeObjects::BFile.store.find {|fi|
      fi.full_name == options.main_page
    } || Billygen::CodeObjects::BFile.store.first
    @rdoc_options[:main_file_id] = file.id

    @data = Billygen::CodeObjects::BCodeObject.complete_store
  end


  def restore
    Billygen::CodeObjects::BCodeObject.complete_store = @data
  end


  def main_file
    data['files'][@rdoc_options[:main_file_id]]
  end


  def method_missing(mthd, *args)
    data[mthd.to_s] ? data[mthd.to_s] : super
  end

end
