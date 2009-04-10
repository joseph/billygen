# A file-level comment that should serve as it's description.


# A file-level method.
def main
  puts "Main called."
end

# A file-level require.
require 'a_class'
require 'a_module'

# A couple of constants
MAIN_CONSTANT_1 = "main_constant_1".freeze
MAIN_CONSTANT_2 = %w[main constant 1].collect { |str| str.freeze }

# A method that does a require when called.
def require_all_files
  require 'module_colon_colon_prefix'
  require 'external_object_reference'
  Dir.glob('*.rb').each { |lib_loc| require lib_loc }
end

# We're going to use this module as the namespace for most of the rest of
# the suite.
module Suite1
end
