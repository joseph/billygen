# If you subclass an external class (say, Object or String), a stub 
# 'BExternalClass' should be created.
module Suite1

  # This class subclasses an external class (one not defined in this test suite)
  class SubklassOfExternalKlass < String

    # This String subclass has a single additional method.
    def skoeknoop
      puts "SubklassOfExternalKlass#skoeknoop called."
    end

  end

end
