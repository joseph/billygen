# Including modules.
module Suite1

  # This class includes an external module (one not defined in this test suite).
  class HasExternalInclude

    # The actual include.
    include Enumerable
    
  end

  # This module will be included in other classes in this test suite.
  module IncludeableModule

    def foo
      puts "IncludeableModule.foo called."
    end

  end

  # This class includes an internal module (one defined elsewhere in this suite)
  class HasInternalInclude

    # It looks like this module include will not resolve to an RDocCodeObject,
    # though it should.
    include IncludeableModule

    # I think this module include, functionally equivalent, will resolve 
    # correctly.
    include Suite1::IncludeableModule

  end
  
end
