# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'billygen'

task :default => 'spec:run'

PROJ.name = 'billygen'
PROJ.authors = 'Joseph Pearson'
PROJ.email = 'joseph@inventivelabs.com.au'
PROJ.url = 'http://inventivelabs.com.au'
PROJ.version = Billygen::VERSION

PROJ.history_file = "HISTORY.md"
PROJ.readme_file = "README.md"
PROJ.ignore_file = '.gitignore'

# EOF
