require 'rubygems'
require 'test/unit'
require 'fileutils'
class BillygenGeneratorTest < Test::Unit::TestCase

  def setup
    FileUtils.rm_rf 'test/tmp'
  end

  def test_run
    require 'lib/billygen.rb'
    files = ['test/data/suite1/README', 'test/data/suite1/lib/**/*.rb']
    Billygen.run('Billygen', 'test/tmp', files)
    assert File.exists?('test/tmp/rdocdump.yml')
  end

end
