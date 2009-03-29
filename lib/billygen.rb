module Billygen

  # :stopdoc:
  VERSION = '0.0.1'
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  # :startdoc:


  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end


  # Returns the library path for the module. If any arguments are given,
  # they will be joined to the end of the libray path using
  # <tt>File.join</tt>.
  #
  def self.libpath( *args )
    args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)

  end

  # Returns the lpath for the module. If any arguments are given,
  # they will be joined to the end of the path using
  # <tt>File.join</tt>.
  #
  def self.path( *args )
    args.empty? ? PATH : ::File.join(PATH, args.flatten)
  end


  # Utility method used to require all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= ::File.basename(fname, '.*')
    search_me = ::File.expand_path(
        ::File.join(::File.dirname(fname), dir, '**', '*.rb'))

    Dir.glob(search_me).sort.each {|rb| require rb}
  end



  # A simple runner that sets up defaults for rdoc generation with billygen.
  # The main file should be the first item in the files list.
  # Files can include glob patterns.
  def self.run(title, output_dir, files)
    files = files.collect {|glob| Dir.glob(glob)}.flatten
    args = [
      "--title=#{title}",
      "--main=#{files.first}",
      "--output=#{output_dir}",
      "--format=billygen",
      "--line-numbers"
    ]
    RDoc::RDoc.add_generator(RDoc::Generator::BillyGen)
    rdoc = RDoc::RDoc.new
    rdoc.document(args + files)
  end

end

Billygen.require_all_libs_relative_to(__FILE__)
