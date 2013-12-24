
module Quickpress

  # Hash that holds global program's settings.
  #
  # There should be only one instalce of it.
  #
  class Options
    def initialize
      @values = {}
    end

    def [] label
      @values[label]
    end

    def []=(label, val)
      @values[label] = val
    end

    # To add settings saved on other hash.
    #
    # @note I don't use Hash#merge because Thor's
    #       argument list creates a Hash with darn
    #       Strings as keys.
    #       I want symbols, dammit!
    def merge! other_hash
      other_hash.each do |key, val|
        @values[key.to_sym] = val
      end
    end
  end

  $options = Options.new
end

