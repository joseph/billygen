# Class inheritance. RDoc (at least at 2.4.1) has a bug where if a superclass
# and subclass are defined in the same file, they're not associated, so 
# Billygen does it in post-processing.

# Namespacing this test data to keep things neat.
module Suite1

  # This is the superclass.
  class Superklass

    # The superclass has a method that doesn't quite do nothing.
    def noop
      puts "Superklass#noop called."
    end

  end


  # This is the subclass.
  class Subklass < Superklass

    # So does the subclass.
    def noop
      puts "Subklass#noop called."
      super
    end

  end

end
