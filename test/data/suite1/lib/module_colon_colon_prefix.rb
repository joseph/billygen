# If we open a top-level module with the '::' prefix, it should be integrated
# into any other reference to that module without the '::' prefix.

module Suite1

  # This method is declared in the unprefixed module.
  def one
  end

end

module ::Suite1

  # This method is declared in the prefixed module.
  def two
  end

end


# Try it again with an external class/module.

class ::Array

  # This method is declared in the prefixed reopening of Array.
  def three
  end

end


# And again by referencing an external class as superclass

module Suite1

  class ABetterHash < ::Hash
  end

end
