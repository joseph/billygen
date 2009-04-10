# A module.
module ASuite1Module

  # A module method
  def module_mthd
    puts "ASuite1Module::module_method called."
  end

  # A class within a module.
  class ModuleKlass

    # An attribute accessor
    attr_accessor :foo
    attr_reader :bar

    # Instance method within a module class
    def inst_mthd
      puts "ASuite1Module::ModuleKlass called."
    end

  end

end


# Reopening this module with a different comment (RDoc should append to first).
module ASuite1Module
end
