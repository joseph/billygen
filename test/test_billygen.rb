require 'rubygems'
require 'test/unit'
require 'fileutils'
class BillygenGeneratorTest < Test::Unit::TestCase

  def setup
    FileUtils.rm_rf 'doc'
  end

  def test_run
    require 'lib/billygen.rb'
    files = ['README.md', 'HISTORY.md', 'lib/**/*.rb']
    Billygen.run('Billygen', 'doc', files)
    assert File.exists?('doc/rdocdump.yml')
  end

end
