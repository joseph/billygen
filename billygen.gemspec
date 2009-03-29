# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{billygen}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joseph Pearson"]
  s.date = %q{2009-03-10}
  s.description = %q{Billygen takes the data that RDoc collects and dumps it to a readable YAML transport format.}
  s.email = %q{joseph@inventivelabs.com.au}
  s.extra_rdoc_files = ["History.txt", "README.txt"]
  s.files = ["History.txt", "README.txt", "Rakefile", "billygen.gemspec", "lib/billygen.rb", "lib/billygen/code_objects.rb", "lib/billygen/generator.rb", "lib/billygen/manifest.rb", "test/test_billygen.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://inventivelabs.com.au}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{billygen}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Billygen takes the data that RDoc collects and dumps it to a readable YAML transport format}
  s.test_files = ["test/test_billygen.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bones>, [">= 2.4.2"])
    else
      s.add_dependency(%q<bones>, [">= 2.4.2"])
    end
  else
    s.add_dependency(%q<bones>, [">= 2.4.2"])
  end
end
