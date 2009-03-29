require 'rubygems'
require 'test/unit'
require 'fileutils'
class BillygenGeneratorTest < Test::Unit::TestCase

  def setup
    FileUtils.rm_rf 'doc'
  end

  def test_run
    require 'pkg/billygen-1.0.0/lib/billygen.rb'
    files = ['README.md', 'HISTORY.md', 'lib/**/*.rb']
    Billygen.run('Billygen', 'doc', files)
    assert File.exists?('doc/rdocdump.yml')
  end

end
